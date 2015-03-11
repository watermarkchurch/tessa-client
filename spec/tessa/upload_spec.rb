require 'spec_helper'

RSpec.describe Tessa::Upload do
  subject(:upload) { described_class.new(args) }
  let(:args) {
    {
      success_url: "/success",
      cancel_url: "/cancel",
      upload_url: "/upload",
      upload_method: "put",
    }
  }

  describe "#initialize" do
    context "with all arguments" do
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

  shared_examples_for "remote call macro" do |method, path, return_type|
    let(:remote_response) { {} }
    let(:faraday_stubs) {
      Faraday::Adapter::Test::Stubs.new do |stub|
        stub.send(method, path) { |env| [200, {}, remote_response.to_json] }
      end
    }
    let(:connection) { Faraday.new { |f| f.adapter :test, faraday_stubs } }
    let(:call_args) { { connection: connection } }

    it "calls #{method} method with #{path}" do
      expect(connection).to receive(method).with(path, any_args).and_call_original
      call
    end

    context "with no connection passed" do
      let(:call_args) { {} }

      it "defaults connection to Tessa.config.connection" do
        expect(Tessa.config).to receive(:connection).and_return(connection)
        expect(connection).to receive(method).and_call_original
        call
      end
    end

    context "when response is not successful" do
      let(:faraday_stubs) {
        Faraday::Adapter::Test::Stubs.new do |stub|
          stub.send(method, path) { |env| [422, {}, { "error" => "error" }.to_json] }
        end
      }

      it "raises Tessa::RequestFailed" do
        expect{ call }.to raise_error(Tessa::RequestFailed)
      end
    end

    it "returns an instance of #{return_type}" do
      expect(call).to be_a(return_type)
    end
  end

  describe "#complete!" do
    subject(:call) { upload.complete!(call_args) }

    include_examples "remote call macro", :patch, "/success", Tessa::Asset
  end

  describe "#cancel!" do
    subject(:call) { upload.cancel!(call_args) }

    include_examples "remote call macro", :patch, "/cancel", Tessa::Asset
  end

  describe "::create" do
    subject(:call) { described_class.create(call_args) }

    include_examples "remote call macro", :post, "/uploads", Tessa::Upload

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
      it "defaults to config.strategy" do
        expect(Tessa.config).to receive(:strategy).and_return(:my_default)
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
