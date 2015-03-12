require 'spec_helper'

RSpec.describe Tessa::Upload do
  subject(:upload) { described_class.new(args) }
  let(:args) {
    {
      upload_url: "/upload",
      upload_method: "put",
      asset_id: 123,
    }
  }

  describe "#initialize" do
    context "with all arguments" do
      it "sets upload_url to attribute" do
        expect(upload.upload_url).to eq(args[:upload_url])
      end

      it "sets upload_method to attribute" do
        expect(upload.upload_method).to eq(args[:upload_method])
      end

      it "sets asset_id to attribute" do
        expect(upload.asset_id).to eq(args[:asset_id])
      end
    end
  end

  describe "::create" do
    subject(:call) { described_class.create(call_args) }

    include_examples "remote call macro", :post, "/uploads", Tessa::Upload

    context "with a full response" do
      let(:remote_response) { args }

      it "returns a new object initialized with the response" do
        upload = described_class.create(connection: connection)
        expect(upload.asset_id).to eq(args[:asset_id])
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
