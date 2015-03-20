require 'spec_helper'

RSpec.describe Tessa::RackUploadProxy do
  Result = Struct.new(:status, :headers, :body) do
    def json
      JSON.parse body.first
    end
  end

  subject(:result) { Result.new *described_class.call(env) }
  let(:env) {
    {
      "rack.request.form_hash" => params,
      "rack.session" => session,
    }
  }
  let(:params) { {} }
  let(:session) { {} }
  let(:upload) {
    Tessa::Upload.new(
      asset_id: 123,
      upload_url: "a-url",
      upload_method: "a-method",
    )
  }
  before do
    allow(Tessa::Upload).to receive(:create).and_return(upload)
  end

  shared_examples_for "proper json return" do
    it "returns asset_id" do
      expect(result.json['asset_id']).to eq(123)
    end

    it "returns upload_url" do
      expect(result.json['upload_url']).to eq("a-url")
    end

    it "returns upload_method" do
      expect(result.json['upload_method']).to eq("a-method")
    end

    it "returns a 200 response" do
      expect(result.status).to eq(200)
    end

    it "sets the mime type to application/json" do
      expect(result.headers).to include("Content-Type" => "application/json")
    end

    context "when Tessa::Upload.create raises RequestFailed" do
      before do
        allow(Tessa::Upload).to receive(:create).and_raise(Tessa::RequestFailed)
      end

      it "returns a proper 500" do
        expect(result.status).to eq(500)
      end

      it "sets the mime type to application/json" do
        expect(result.headers).to include("Content-Type" => "application/json")
      end

      it "includes an error message in JSON response" do
        expect(result.json['error']).to be_truthy
      end
    end
  end

  context "with no params and no session" do
    it "calls Tessa::Upload.create" do
      expect(Tessa::Upload).to receive(:create).and_return(upload)
      result
    end

    it "pushes the asset_id onto session" do
      result
      expect(session[:tessa_upload_asset_ids]).to eq([123])
    end

    it_behaves_like "proper json return"
  end

  context "with params" do
    let(:params) {
      {
        "name" => "my-name",
        "size" => 456,
        "mime_type" => "plain/text",
      }
    }

    it "calls Tessa::Upload.create with 'name'" do
      expect(Tessa::Upload).to receive(:create).with(hash_including(name: "my-name"))
      result
    end

    it "calls Tessa::Upload.create with 'size'" do
      expect(Tessa::Upload).to receive(:create).with(hash_including(size: 456))
      result
    end

    it "calls Tessa::Upload.create with 'mime_type'" do
      expect(Tessa::Upload).to receive(:create).with(hash_including(mime_type: "plain/text"))
      result
    end

    it_behaves_like "proper json return"
  end

  context "with existing session" do
    let(:session) {
      {
        tessa_upload_asset_ids: [:existing_id],
      }
    }

    it "does not remove existing ids" do
      result
      expect(session[:tessa_upload_asset_ids]).to eq([:existing_id, 123])
    end

    it_behaves_like "proper json return"
  end

end
