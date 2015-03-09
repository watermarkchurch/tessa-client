require 'spec_helper'

RSpec.describe Tessa::Upload do
  let(:args) {
    {
      success_url: "http://example.com/success",
      cancel_url: "http://example.com/cancel",
      upload_url: "http://example.com/upload",
      upload_method: "put",
    }
  }

  describe "#initialize" do
    context "with all arguments" do
      subject(:upload) { described_class.new(args) }
      it "sets success_url to attribute" do
        expect(upload.success_url).to eq(args[:success_url])
      end

      it "sets cancel_url to attribute" do
        expect(upload.cancel_url).to eq(args[:cancel_url])
      end

      it "sets upload_url to attribute" do
        expect(upload.upload_url).to eq(args[:upload_url])
      end

      it "sets upload_method to attribute" do
        expect(upload.upload_method).to eq(args[:upload_method])
      end
    end
  end

  describe "::create" do
    let(:remote_response) { {} }
    let(:faraday_stubs) {
      Faraday::Adapter::Test::Stubs.new do |stub|
        stub.post("/uploads") { |env| [200, {}, remote_response.to_json] }
      end
    }
    let(:connection) { Faraday.new { |f| f.adapter :test, faraday_stubs } }

    it "calls post('/uploads') on connection" do
      expect(connection).to receive(:post).with("/uploads", any_args).and_call_original
      described_class.create(connection: connection)
    end

    it "uses Tessa.config.connection when no connection passed" do
      expect(Tessa.config).to receive(:connection).and_return(connection)
      expect(connection).to receive(:post).and_call_original
      described_class.create
    end

    context "with a full response" do
      let(:remote_response) { args }

      it "returns a new object initialized with the response" do
        upload = described_class.create(connection: connection)
        expect(upload.success_url).to eq(args[:success_url])
        expect(upload.cancel_url).to eq(args[:cancel_url])
        expect(upload.upload_url).to eq(args[:upload_url])
        expect(upload.upload_method).to eq(args[:upload_method])
      end
    end

    describe ":strategy param" do
      it "defaults to config.default_strategy" do
        expect(Tessa.config).to receive(:default_strategy).and_return(:my_default)
        expect_post_with_hash_including(strategy: :my_default)
        described_class.create(connection: connection)
      end

      it "overrides with :strategy argument" do
        expect_post_with_hash_including(strategy: :my_default)
        described_class.create(connection: connection, strategy: :my_default)
      end
    end

    it "sets :name param from argument" do
      expect_post_with_hash_including(name: "my-file.txt")
      described_class.create(connection: connection, name: "my-file.txt")
    end

    it "sets :size param from argument" do
      expect_post_with_hash_including(size: 12345)
      described_class.create(connection: connection, size: 12345)
    end

    it "sets :mime_type param from argument" do
      expect_post_with_hash_including(mime_type: "text/plain")
      described_class.create(connection: connection, mime_type: "text/plain")
    end

    def expect_post_with_hash_including(expected)
      expect(connection).to receive(:post)
        .with("/uploads", hash_including(expected))
        .and_call_original
    end
  end

end
