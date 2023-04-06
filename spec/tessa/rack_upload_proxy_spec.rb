require 'rails_helper'

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

  let(:blob) { ActiveStorage::Blob.last }

  before do
    allow(ActiveStorage.verifier).to receive(:generate)
      .and_return('some-consistent-token')
  end

  shared_examples_for "proper json return" do
    it "returns asset_id" do
      expect(result.json['asset_id']).to eq(blob.signed_id)
    end

    it "returns upload_url" do
      expect(result.json['upload_url']).to eq('https://www.example.com/rails/active_storage/disk/some-consistent-token')
    end

    it "returns upload_method" do
      expect(result.json['upload_method']).to eq('PUT')
    end

    it "returns upload_method" do
      expect(result.json['upload_headers']).to eq(blob.service_headers_for_direct_upload)
    end

    it "returns a 200 response" do
      expect(result.status).to eq(200)
    end

    it "sets the mime type to application/json" do
      expect(result.headers).to include("Content-Type" => "application/json")
    end
  end

  context "with no params and no session" do
    it "raises a bad request error" do
      expect(result.status).to eq(400)
    end
  end

  context "with params" do
    let(:params) {
      {
        "name" => "my-name",
        "size" => 456,
        "mime_type" => "plain/text",
        "checksum" => '1234'
      }
    }

    it "creates the ActiveStorage blob" do
      expect {
        described_class.call(env)
      }.to change { ActiveStorage::Blob.count }.by(1)

      expect(blob.filename).to eq('my-name')
      expect(blob.byte_size).to eq(456)
      expect(blob.content_type).to eq('plain/text')
      expect(blob.checksum).to eq('1234')
    end

    it_behaves_like "proper json return"
  end

end
