require 'spec_helper'

RSpec.describe Tessa::Asset do
  let(:uuid) { "abc" }
  let(:metadata) { { size: 1234 } }
  let(:location_url) { "file:///tmp/file" }
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

    it "assigns :location_url to attribute" do
      obj = subject.new(uuid: uuid, location_url: location_url)
      expect(obj.location_url).to eq(location_url)
    end
  end

  describe "metadata" do
    it "is a hash"
  end

  describe "location_url" do
    it "is a string"
  end

  describe "uuid" do
    it "is a string"
  end

  describe "file" do
  end

  describe "#write" do
    subject(:asset) { described_class.new(uuid: uuid) }

    it "uses default backend"

    let(:backend) { double(:backend) }

    it "calls write on backend and sets location_url to response" do
      expect(backend).to receive(:write).with(file).and_return(location_url)
      asset.write(file, backend: backend)
      expect(asset.location_url).to eq(location_url)
    end
  end
end
