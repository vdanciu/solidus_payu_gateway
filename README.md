SolidusPayuGateway
==================

**NOT DONE YET. DO NOT TRY TO USE!**

Installation
------------

Add solidus_payu_gateway to your Gemfile:

```ruby
gem 'solidus_payu_gateway'
```

Bundle your dependencies and run the installation generator:

```shell
bundle
bundle exec rails g solidus_payu_gateway:install
```

Testing
-------

First bundle your dependencies, then run `rake`. `rake` will default to building the dummy app if it does not exist, then it will run specs, and [Rubocop](https://github.com/bbatsov/rubocop) static code analysis. The dummy app can be regenerated by using `rake test_app`.

```shell
bundle
bundle exec rake
```

When testing your applications integration with this extension you may use it's factories.
Simply add this require statement to your spec_helper:

```ruby
require 'solidus_payu_gateway/factories'
```

