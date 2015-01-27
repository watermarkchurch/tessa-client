require 'spec_helper'

RSpec.describe Tessa::Asset do
  let(:uuid) { "abc" }
  let(:metadata) { { size: 1234 } }
  let(:uri) { "file:///tmp/file" }
  let(:file) { :temp_file }

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

    it "assigns :uri to attribute" do
      obj = subject.new(uuid: uuid, uri: uri)
      expect(obj.uri).to eq(uri)
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

    it ""
  end

  describe "#upload" do
    subject(:asset) { described_class.new(uuid: uuid) }

    it "uses default backend"

    let(:backend) { double(:backend) }

    it "calls upload on backend and sets uri to response" do
      expect(backend).to receive(:upload).with(file).and_return(uri)
      asset.upload(file, backend: backend)
      expect(asset.uri).to eq(uri)
    end
  end
end
