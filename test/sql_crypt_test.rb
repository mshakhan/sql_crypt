require File.dirname(__FILE__) + '/test_helper'
include SQLCrypt
require 'fixtures/account.rb'

class SqlCryptTest < ActiveSupport::TestCase
  test_order = :sorted

  test "01 no key raises exception" do
    assert_raise(NoEncryptionKey) {
      Account.sql_encrypted(:balance, {})
    }
  end

  test "02 each encrypted attribute is added when added in sequence" do
    # :balance is encrypted in model class definition
    assert Account.encrypted_fields.size == 2
    assert Account.encrypted_fields.first[:name] == :balance
    assert Account.encrypted_fields.first[:key] == 'test1'
    Account.sql_encrypted(:name, :key => 'test2')
    assert Account.encrypted_fields.size==3
    assert Account.encrypted_fields.first[:name] == :balance
    assert Account.encrypted_fields.first[:key] == 'test1'
    assert Account.encrypted_fields.last[:name] == :name
    assert Account.encrypted_fields.last[:key] == 'test2'
  end

  test "03 multiple encrypted attributes can be added" do
    Account.sql_encrypted(:acct_number, :password, :key => 'test4')
    assert Account.encrypted_fields.size==5
    assert Account.encrypted_fields[3][:name] == :acct_number
    assert Account.encrypted_fields[3][:key] == 'test4'
    assert Account.encrypted_fields.last[:name] == :password
    assert Account.encrypted_fields.last[:key] == 'test4'
  end

  test "04 encrypted attribute is stored locally" do
    acc = Account.new
    acc.balance = '100'
    assert acc.read_encrypted_value("balance_decrypted")=='100'
  end

  test "05 encrypted attribute is retrieved from the right place" do
    acc = Account.new
    acc.balance = '100'
    assert acc.balance=='100'
    assert acc.balance==acc.read_encrypted_value("balance_decrypted")
  end

  test "06 encrypted attribute is persisted to database" do
    acc = Account.new
    acc.balance = '100'
    acc.save
    fetched_from_db = acc.class.connection.select_value("select balance from accounts where id=#{acc.id}")
    expected = acc.class.connection.select_value("select hex(aes_encrypt('100','test1_#{acc.id}'))")
    assert fetched_from_db==expected
  end

  test "07 encrypted attribute is retrieved from database" do
    acc = Account.new
    acc.balance = '100'
    acc.save
    acc2 = Account.find(acc.id)
    assert acc2.balance == '100'
    # Do an update too
    acc.balance = '220'
    acc.save
    acc3 = Account.find(acc.id)
    assert acc3.balance == '220'
  end

  test "08 encrypted attribute uses specified type" do
    acc = Account.new
    acc.balance_as_float = 150
    acc.save
    acc2 = Account.find(acc.id)
    assert acc2.balance_as_float == 150
  end

  test "09 encryption changes are true when attribute is changed" do
    acc = Account.new
    acc.balance_as_float = 150
    acc.save
    acc2 = Account.find(acc.id)
    acc2.balance_as_float = 180
    assert acc2.encrypted_changed?(:balance_as_float)
  end

  test "10 encryption changes are false when attribute is not changed" do
    acc = Account.new
    acc.balance_as_float = 150
    acc.save
    acc2 = Account.find(acc.id)
    acc2.balance_as_float = 150
    assert !acc2.encrypted_changed?(:balance_as_float)
  end

  test "11 encryption changes are false when attribute is changed and then changed back" do
    acc = Account.new
    acc.balance_as_float = 150
    acc.save
    acc2 = Account.find(acc.id)
    acc2.balance_as_float = 180
    assert acc2.encrypted_changed?(:balance_as_float)
    acc2.balance_as_float = 150
    assert !acc2.encrypted_changed?(:balance_as_float)
  end

  test "12 nonchanged attributes are not persisted (and therefore don't overwrite changed ones)" do
    acc = Account.new
    acc.balance_as_float = 150
    acc.save
    acc2 = Account.find(acc.id)
    acc2.balance_as_float = 180
    acc3 = Account.find(acc.id)
    acc2.save
    acc3.save
    acc4 = Account.find(acc.id)
    assert acc4.balance_as_float == 180
  end

  test "13 nonencrypted attribute is still persisted to and retrieved from database even if no encryption happens" do
    acc = Account.new
    acc.normal_attribute = 'hello'
    acc.save
    acc2 = Account.find(acc.id)
    assert acc2.normal_attribute == 'hello'
  end

  test "14 encrypted attribute cannot be mass-assigned" do
    acc = Account.new({:normal_attribute=>'what', :balance=>'10'})
    assert acc.normal_attribute == 'what'
    assert acc.balance.nil?
    # Now assign it normally
    acc.balance = '10'
    assert acc.balance == '10'
  end

end
