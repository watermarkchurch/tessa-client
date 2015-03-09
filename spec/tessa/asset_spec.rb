require 'spec_helper'

RSpec.describe Tessa::Asset do
  let(:args) {
    {
      id: 123,
      status: 'completed',
      strategy: 'default',
      meta: { name: "foo" },
      public_url: "http://example.com/public",
      private_url: "http://example.com/private",
      delete_url: "http://example.com/delete",
    }
  }

  describe "#initialize" do
    context "with all arguments" do
      subject(:asset) { described_class.new(args) }

      it "sets id to attribute" do
        expect(asset.id).to eq(args[:id])
      end

      it "sets status to attribute" do
        expect(asset.status).to eq(args[:status])
      end

      it "sets strategy to attribute" do
        expect(asset.strategy).to eq(args[:strategy])
      end

      it "sets meta to attribute" do
        expect(asset.meta).to eq(args[:meta])
      end

      it "sets public_url to attribute" do
        expect(asset.public_url).to eq(args[:public_url])
      end

      it "sets private_url to attribute" do
        expect(asset.private_url).to eq(args[:private_url])
      end

      it "sets delete_url to attribute" do
        expect(asset.delete_url).to eq(args[:delete_url])
      end

    end
  end

end
