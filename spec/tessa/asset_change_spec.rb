require 'spec_helper'

RSpec.describe Tessa::AssetChange do
  subject(:change) { described_class.new(args) }
  let(:args) {
    {
      id: 123,
      action: "add",
    }
  }

  describe "#initialize" do
    context "with hash args" do
      it "sets id" do
        expect(subject.id).to eq(123)
      end

      it "sets action" do
        expect(subject.action).to eq("add")
      end
    end

    context "with array arg" do
      let(:args) { [123, { "action" => "add" }] }

      it "sets id" do
        expect(subject.id).to eq(123)
      end

      it "sets action" do
        expect(subject.action).to eq("add")
      end
    end
  end

  describe "#apply" do
    let(:asset) { instance_spy(Tessa::Asset) }
    before do
      expect(Tessa::Asset).to receive(:new).with(id: 123).and_return(asset)
    end

    context "with action 'add'" do
      before { args[:action] = "add" }
      it "calls complete! on asset with :id" do
        change.apply
        expect(asset).to have_received(:complete!)
      end
    end

    context "with action 'remove'" do
      before { args[:action] = "remove" }
      it "calls delete! on asset with :id" do
        change.apply
        expect(asset).to have_received(:delete!)
      end
    end
  end
end
