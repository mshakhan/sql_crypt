# -*- encoding: utf-8 -*-
$:.push File.expand_path("../lib", __FILE__)
require "sql_crypt/version"

Gem::Specification.new do |s|
  s.name        = "sql_crypt"
  s.version     = SQLCrypt::VERSION
  s.summary     = "Simple encoding support for models."
  s.description = "Provides field encoding  support for ActiveRecord models."

  s.required_ruby_version = ">= 2.7.2"
  s.required_rubygems_version = ">= 3.1.4"

  s.authors = ["Monica McArthur", "Mikhail Shakhanov"]
  s.email = ["mechaferret@gmail.com", "mshakhan@gmail.com"]
  s.homepage = "https://github.com/mshakhan/sql_crypt"

  s.files = `git ls-files`.split("\n")
  s.test_files = `git ls-files -- {test,spec,features}/*`.split("\n")
  s.require_path = 'lib'

  s.license = 'MIT'

  s.add_dependency "rails", "~> 6.0.3"
  s.add_dependency 'activerecord', '~> 6.0.3'
  s.add_dependency "mysql2"
  s.add_dependency 'protected_attributes_continued'


  s.add_development_dependency 'rake', '>= 13.0.1'
end
