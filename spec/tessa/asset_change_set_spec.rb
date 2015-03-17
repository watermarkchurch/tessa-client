require 'spec_helper'

RSpec.describe Tessa::AssetChangeSet do
  subject(:set) { described_class.new(args) }
  let(:args) {
    {
      changes: Array.new(2) { Tessa::AssetChange.new },
      scoped_ids: [1, 2],
    }
  }

  describe "#initialize" do
    it "sets :changes to attribute" do
      expect(set.changes).to eq(args[:changes])
    end

    it "sets :scoped_ids to attribute" do
      expect(set.scoped_ids).to eq([1, 2])
    end

    context "with various scoped_id input types" do
      before { args[:scoped_ids] = ["1", 2, nil] }

      it "ensures all values are integers and ignores nils" do
        expect(set.scoped_ids).to eq([1, 2])
      end
    end

    context "with hash format for changes" do
      before do
        args[:changes] = { "123" => { "action" => "add" }, "456" => { "action" => "remove" } }
      end

      it "initializes AssetChange objects for each hash" do
        expect(set.changes[0].id).to eq(123)
        expect(set.changes[0].action).to eq("add")
        expect(set.changes[1].id).to eq(456)
        expect(set.changes[1].action).to eq("remove")
      end
    end
  end

end
