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
    it "sets id" do
      expect(subject.id).to eq(123)
    end

    it "sets action" do
      expect(subject.action).to eq("add")
    end
  end

end
