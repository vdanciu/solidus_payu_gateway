# encoding: UTF-8

$:.push File.expand_path('lib', __dir__)
require 'solidus_payu_gateway/version'

Gem::Specification.new do |s|
  s.name        = 'solidus_payu_gateway'
  s.version     = SolidusPayuGateway::VERSION
  s.summary     = 'PayU Solidus Gateway'
  s.description = 'PayU Solidus Gateway'
  s.license     = 'BSD-3-Clause'

  s.author    = 'Vlad Danciu'
  s.email     = 'vdanciu@yahoo.com'
  # s.homepage  = 'http://www.example.com'

  s.files = Dir["{app,config,db,lib}/**/*", 'LICENSE', 'Rakefile', 'README.md']
  s.test_files = Dir['test/**/*']

  s.add_dependency 'solidus_core'

  s.add_development_dependency 'capybara'
  s.add_development_dependency 'poltergeist'
  s.add_development_dependency 'coffee-rails'
  s.add_development_dependency 'sass-rails'
  s.add_development_dependency 'database_cleaner'
  s.add_development_dependency 'factory_girl'
  s.add_development_dependency 'rspec-rails'
  s.add_development_dependency 'rubocop', '~> 0.49.0'
  s.add_development_dependency 'rubocop-rspec', '1.4.0'
  s.add_development_dependency 'simplecov'
  s.add_development_dependency 'sqlite3'
end
