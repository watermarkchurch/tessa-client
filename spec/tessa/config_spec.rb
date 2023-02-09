require 'spec_helper'

RSpec.describe Tessa::Config do
  let(:cfg) { Tessa::Config.new }

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
      subject { cfg.username }
    end

    it "behaves like a normal accessor" do
      cfg.username = "my-new-value"
      expect(cfg.username).to eq("my-new-value")
    end
  end

  describe "#password" do
    it_behaves_like "defaults to environment variable" do
      let(:variable_name) { 'TESSA_PASSWORD' }
      subject { cfg.password }
    end

    it "behaves like a normal accessor" do
      cfg.password = "my-new-value"
      expect(cfg.password).to eq("my-new-value")
    end
  end

  describe "#url" do
    it_behaves_like "defaults to environment variable" do
      let(:variable_name) { 'TESSA_URL' }
      subject { cfg.url }
    end

    it "behaves like a normal accessor" do
      cfg.url = "my-new-value"
      expect(cfg.url).to eq("my-new-value")
    end
  end

  describe "#strategy" do
    it_behaves_like "defaults to environment variable" do
      let(:variable_name) { 'TESSA_STRATEGY' }
      subject { cfg.strategy }
    end

    it "uses the string 'default' when no envvar passed" do
      expect(cfg.strategy).to eq("default")
    end

    it "behaves like a normal accessor" do
      cfg.strategy = "my-new-value"
      expect(cfg.strategy).to eq("my-new-value")
    end
  end
end
