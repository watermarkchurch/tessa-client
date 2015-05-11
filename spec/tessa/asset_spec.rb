require 'spec_helper'

RSpec.describe Tessa::Asset do
  subject(:asset) { described_class.new(args) }
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

  describe "#complete!" do
    subject(:call) { asset.complete!(call_args) }

    include_examples "remote call macro", :patch, "/assets/123/completed", Tessa::Asset
  end

  describe "#cancel!" do
    subject(:call) { asset.cancel!(call_args) }

    include_examples "remote call macro", :patch, "/assets/123/cancelled", Tessa::Asset
  end

  describe "#delete!" do
    subject(:call) { asset.delete!(call_args) }

    include_examples "remote call macro", :delete, "/assets/123", Tessa::Asset
  end

  describe "#failure?" do
    it "returns false" do
      expect(asset.failure?).to be(false)
    end
  end

  describe ".find" do
    let(:faraday_stubs) {
      Faraday::Adapter::Test::Stubs.new do |stub|
        stub.get("/assets/#{id_query}") { |env| [200, {}, remote_response.to_json] }
      end
    }
    let(:connection) { Faraday.new { |f| f.adapter :test, faraday_stubs } }

    context "with a single id" do
      let(:id_query) { "ID" }
      let(:remote_response) { {} }

      it "calls get('/assets/ID') on connection" do
        expect(connection).to receive(:get).with("/assets/ID").and_call_original
        described_class.find("ID", connection: connection)
      end

      it "returns an instance of Asset" do
        response = described_class.find("ID", connection: connection)
        expect(response).to be_a(described_class)
      end

      it "defaults connection to Tessa.config.connection" do
        expect(Tessa.config).to receive(:connection).and_return(connection)
        expect(connection).to receive(:get).and_call_original
        described_class.find("ID")
      end

      context "with attributes in response" do
        subject(:response) { described_class.find("ID", connection: connection) }
        let(:remote_response) { args }

        it "sets attributes on models" do
          expect(response.id).to eq(args[:id])
          expect(response.status).to eq(args[:status])
          expect(response.meta).to eq(args[:meta])
        end
      end
    end

    context "with multiple ids" do
      subject(:response) {
        described_class.find("ID1", "ID2", connection: connection)
      }
      let(:remote_response) { [{}] }
      let(:id_query) { "ID1,ID2" }

      it "calls get('/assets/ID1,ID2') on connection" do
        expect(connection).to receive(:get).with("/assets/ID1,ID2").and_call_original
        response
      end

      it "returns instances of Asset" do
        expect(response).to all(be_a(described_class))
      end

      context "with attributes in response" do
        let(:remote_response) { [args, args] }

        it "sets attributes on models" do
          expect(response[0].id).to eq(args[:id])
          expect(response[1].id).to eq(args[:id])
        end
      end
    end
  end

end
