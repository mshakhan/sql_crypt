module SQLCrypt
   module Adapters
      module MySQL
         def encryption_find(name, key, options={})
            "aes_decrypt(unhex(#{name}), '#{key}_#{self.id}') as #{name}"
         end

         def encryption_set(name, key, options={})
            "#{name}=hex(aes_encrypt('#{self.read_encrypted_value("#{name}_decrypted")}', '#{key}_#{self.id}'))"
         end
      end
      Mysql2 = MySQL
   end #Adapters
end #SqlCrypt

