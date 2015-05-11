require 'spec_helper'

RSpec.describe Tessa::Failure do
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

  it "responds like a blank asset" do
    asset = Tessa::Asset.new
    expect(failure.status).to eq(asset.status)
    expect(failure.strategy).to eq(asset.strategy)
    expect(failure.meta).to eq(asset.meta)
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
