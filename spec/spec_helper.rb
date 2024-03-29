require 'webmock/rspec'
require 'tessa'
require 'tempfile'

Dir[File.expand_path("../support/*.rb", __FILE__)].each do |file|
  require file
end

if ENV['SIMPLE_COV'] || ENV['CC_TEST_REPORTER_ID']
  require 'simplecov'
  SimpleCov.start
end

RSpec.configure do |config|
  WebMock.disable_net_connect!

  config.expect_with :rspec do |expectations|
    expectations.include_chain_clauses_in_custom_matcher_descriptions = true
  end

  config.mock_with :rspec do |mocks|
    mocks.verify_partial_doubles = true
  end

  if config.files_to_run.one?
    config.default_formatter = 'doc'
  end

  config.filter_run :focus
  config.run_all_when_everything_filtered = true
  config.disable_monkey_patching!
  config.warnings = true
  config.order = :random

  Kernel.srand config.seed
end
