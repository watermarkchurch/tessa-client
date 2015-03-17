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

end
