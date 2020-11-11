require 'rubygems'
require 'active_record'
require 'active_record/fixtures'
require 'active_support'
require 'active_support/test_case'
require 'active_support/core_ext/string'

require 'sql_crypt/version.rb'
require 'sql_crypt/exceptions.rb'
require 'sql_crypt/adapters/mysql.rb'

module SQLCrypt

  def self.included(base)
    base.extend ClassMethods
  end

  module ClassMethods
    def initialize_sql_crypt
      already_done = (!self.encrypted_fields.empty? rescue false)
      return if already_done
      include InstanceMethods
      include InstanceMethods::SQLCryptMethods
      begin
        include "SQLCrypt::Adapters::#{self.connection.adapter_name}".constantize
      rescue
        raise NoAdapterFound.new(self.connection.adapter_name)
      end

      after_find :find_encrypted
      after_save :save_encrypted

      cattr_accessor(:encrypted_fields)
      cattr_accessor(:converters)

      self.encrypted_fields = []
      self.converters = {}

      @@sql_crypt_initialized = true
    end

    def sql_encrypted(*args)
      raise NoEncryptionKey unless args.last[:key]
      self.initialize_sql_crypt

      secret_key = args.last[:key]
      decrypted_converter = args.last[:converter]
      args.delete args.last

      args.each do |name|
        attr_protected(name)
        self.encrypted_fields << { :name => name, :key => secret_key}
        self.converters[name] = decrypted_converter
        module_eval <<-"ATTRIBUTE_ACCESSORS", __FILE__, __LINE__
          def #{name}
            value = self.read_encrypted_value("#{name}_decrypted")
            if value.respond_to?(:force_encoding)
              value.force_encoding("UTF-8")
            else
              value
            end
          end

          def #{name}=(value)
            self.write_encrypted_value("#{name}_decrypted", value)
          end
        ATTRIBUTE_ACCESSORS
      end
    end
  end # ClassMethods

  module InstanceMethods
    def find_encrypted
      encrypted_find = self.class.encrypted_fields.collect do |y|
        encryption_find(y[:name], y[:key])
      end.join(',')

      # TODO: move to the adapter
      encrypted_fields = self.class.connection.select_one <<-"SQL"
      select #{encrypted_find}
        from #{self.class.table_name}
        where #{self.class.primary_key} = #{self.id}
      SQL
      encrypted_fields.each do |k, v|
        write_encrypted_value("#{k}_decrypted", convert(k, v), false)
      end
    end

    def save_encrypted
      encrypted_save = self.class.encrypted_fields.collect do |y|
        if encrypted_changed?(y[:name])
          encryption_set(y[:name], y[:key])
        end
      end.delete_if { |c|c.blank? }.join(',')

      return if encrypted_save.blank? # no changes to save
      # TODO: move to the adapter
      self.class.connection.execute <<-"SQL"
      update #{self.class.table_name}
        set #{encrypted_save}
        where #{self.class.primary_key} = #{self.id}
      SQL
    end

    def convert(name, value)
      converter = self.class.converters[name.to_sym]
      converter ? value.send(converter) : value
    end

    module SQLCryptMethods
      def read_encrypted_value(name)
        @sql_crypt_data &&
          @sql_crypt_data[name]
      end

      def write_encrypted_value(name, value, check_changed = true)
        @sql_crypt_data ||= {}
        @sql_crypt_changed ||= {}

        if check_changed
          old_value = encrypted_orig_value(name)
          if value != old_value
            @sql_crypt_changed[name] ||= {}
            @sql_crypt_changed[name][:old] = old_value
            @sql_crypt_changed[name][:new] = value
          else
            @sql_crypt_changed[name] = nil
          end
        end
        @sql_crypt_data[name] = value
      end

      def encrypted_orig_value(name)
        @sql_crypt_changed[name][:old]
      rescue
        read_encrypted_value(name)
      end

      def encrypted_changed?(name)
        @sql_crypt_changed && @sql_crypt_changed["#{name}_decrypted"]
      end
    end # SQLCryptMethods
  end # InstanceMethods
end # SQLCrypt

# include in AR
ActiveSupport.on_load(:active_record) do
  ActiveRecord::Base.send(:include, SQLCrypt)
end
