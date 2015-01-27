require 'spec_helper'

RSpec.describe Tessa::Asset do
  let(:uuid) { "abc" }
  let(:metadata) { { size: 1234 } }
  let(:uri) { "file:///tmp/file" }
  let(:file) { :temp_file }
  let(:backend) { double(:backend) }

  describe "#initialize" do
    subject(:klass) { described_class }

    it "requires :uuid" do
      expect { subject.new }.to raise_error(ArgumentError)
    end

    it "assigns :uuid to attribute" do
      obj = subject.new(uuid: uuid)
      expect(obj.uuid).to eq(uuid)
    end

    it "assigns :metadata to attribute" do
      obj = subject.new(uuid: uuid, metadata: metadata)
      expect(obj.metadata).to eq(metadata)
    end

    context "a valid URI string for :uri" do
      it "creates a URI object" do
        obj = subject.new(uuid: uuid, uri: uri)
        expect(obj.uri).to be_a(URI::Generic)
      end
    end

    context "an invalid URI string for :uri" do
      let(:uri) { "::::" }

      it "raises an error" do
        expect { subject.new(uuid: uuid, uri: uri) }.to raise_error(URI::InvalidURIError)
      end
    end

    context "no URI passed" do
      it "initializes an empty URI" do
        obj = subject.new(uuid: uuid)
        expect(obj.uri).to respond_to(:scheme)
      end
    end
  end

  describe "metadata" do
    it "is a hash"
  end

  describe "uri" do
    it "is a string"
  end

  describe "uuid" do
    it "is a string"
  end

  describe "file" do
  end

  describe "#download" do
    subject(:asset) { described_class.new(uuid: uuid, uri: uri) }
    let(:db) { double(:db, fetch: backend) }

    context "uri is blank" do
      let(:uri) { '' }

      it "raises an error" do
        expect { asset.download(backend_db: db) }.to raise_error
      end
    end

    it "calls download on backend" do
      data = 'test data'
      expect(backend).to receive(:download).with(asset.uri).and_return(data)
      expect(asset.download(backend_db: db)).to eq(data)
    end
  end

  describe "#upload" do
    subject(:asset) { described_class.new(uuid: uuid) }

    it "uses default backend"

    it "calls upload on backend and sets uri to response" do
      expect(backend).to receive(:upload).with(file).and_return(uri)
      asset.upload(file, backend: backend)
      expect(asset.uri).to eq(uri)
    end
  end

  describe "::create" do
    it "initializes a new Asset" do
      expect(described_class.create).to be_a(described_class)
    end

    it "sets uuid to a new uuid" do
      obj = described_class.create
      expect(obj.uuid).to match(/^\w{8}-\w{4}-\w{4}-\w{4}-\w{12}$/)
    end
  end
end
