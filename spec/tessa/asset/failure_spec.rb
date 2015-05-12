require 'spec_helper'

RSpec.describe Tessa::Asset::Failure do
  subject(:failure) { described_class.new(args) }
  let(:id) { rand(100) }
  let(:args) {
    { id: id, message: "Test" }
  }

  describe "#initialize" do
    it "sets id to attribute" do
      expect(failure.id).to eq(args[:id])
    end

    it "sets message to attribute" do
      expect(failure.message).to eq(args[:message])
    end
  end

  describe ".factory" do
    let(:message) { 'test message' }
    let(:response) { double(status: 500) }
    subject(:failure) { described_class.factory(id: id, response: response) }


    it "returns instance of Failure" do
      expect(described_class).to receive(:message_from_status)
        .with(response.status).and_return(message)
      expect(failure.id).to eq(id)
      expect(failure.message).to eq(message)
    end
  end

  it "responds like a blank asset" do
    asset = Tessa::Asset.new
    expect(failure.status).to eq(asset.status)
    expect(failure.strategy).to eq(asset.strategy)
    expect(failure.public_url).to eq(asset.public_url)
    expect(failure.private_url).to eq(asset.private_url)
    expect(failure.delete_url).to eq(asset.delete_url)
  end

  describe "#failure?" do
    it "returns true" do
      expect(failure).to be_failure
    end
  end
end
