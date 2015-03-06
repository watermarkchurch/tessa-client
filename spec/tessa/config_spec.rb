require 'spec_helper'

RSpec.describe Tessa::Config do
  subject(:config) { Tessa::Config.new }

  shared_examples_for "defaults to environment variable" do
    around { |ex| swap_environment_var(variable_name, 'from-env') { ex.run } }

    it { is_expected.to eq("from-env") }

    def swap_environment_var(var, new_val)
      old_val = ENV[var]
      ENV[var] = new_val
      yield
      ENV[var] = old_val
    end
  end

  describe "#username" do
    it_behaves_like "defaults to environment variable" do
      let(:variable_name) { 'TESSA_USERNAME' }
      subject(:username) { config.username }
    end

    it "behaves like a normal accessor" do
      config.username = "my-new-value"
      expect(config.username).to eq("my-new-value")
    end
  end

  describe "#password" do
    it_behaves_like "defaults to environment variable" do
      let(:variable_name) { 'TESSA_PASSWORD' }
      subject(:password) { config.password }
    end

    it "behaves like a normal accessor" do
      config.password = "my-new-value"
      expect(config.password).to eq("my-new-value")
    end
  end

  describe "#default_strategy" do
    it_behaves_like "defaults to environment variable" do
      let(:variable_name) { 'TESSA_DEFAULT_STRATEGY' }
      subject(:default_strategy) { config.default_strategy }
    end

    it "behaves like a normal accessor" do
      config.default_strategy = "my-new-value"
      expect(config.default_strategy).to eq("my-new-value")
    end
  end
end
