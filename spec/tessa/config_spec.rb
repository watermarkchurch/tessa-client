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

  describe "#url" do
    it_behaves_like "defaults to environment variable" do
      let(:variable_name) { 'TESSA_URL' }
      subject(:url) { config.url }
    end

    it "behaves like a normal accessor" do
      config.url = "my-new-value"
      expect(config.url).to eq("my-new-value")
    end
  end

  describe "#strategy" do
    it_behaves_like "defaults to environment variable" do
      let(:variable_name) { 'TESSA_STRATEGY' }
      subject(:strategy) { config.strategy }
    end

    it "uses the string 'default' when no envvar passed" do
      expect(config.strategy).to eq("default")
    end

    it "behaves like a normal accessor" do
      config.strategy = "my-new-value"
      expect(config.strategy).to eq("my-new-value")
    end
  end

  describe "#connection" do
    it "is a Faraday::Connection" do
      expect(config.connection).to be_a(Faraday::Connection)
    end

    context "with values configured" do
      subject(:connection) { config.connection }
      before { args.each { |k, v| config.send("#{k}=", v) } }
      let(:args) {
        {
          url: "http://tessa.test",
          username: "username",
          password: "password",
        }
      }

      it "sets faraday's url prefix to our url" do
        expect(connection.url_prefix.to_s).to match(config.url)
      end

      context "with faraday spy" do
        let(:spy) { instance_spy(Faraday::Connection) }
        before do
          expect(Faraday).to receive(:new).and_yield(spy)
          connection
        end

        it "sets up url_encoded request handler" do
          expect(spy).to have_received(:request).with(:url_encoded)
        end

        it "configures the default adapter" do
          expect(spy).to have_received(:adapter).with(:net_http)
        end
      end
    end

    it "caches the result" do
      expect(config.connection.object_id).to eq(config.connection.object_id)
    end
  end
end
