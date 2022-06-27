
ENV['RAILS_ENV'] ||= 'test'

require 'spec_helper'

require File.expand_path('dummy/config/environment.rb', __dir__)

require 'rspec/rails'

RSpec.configure do |config|
  ActiveStorage::Current.host = 'https://www.example.com'
  Rails.application.routes.default_url_options = {
    protocol: 'https',
    host: "www.example.com"
  }

  config.use_transactional_fixtures = true
end