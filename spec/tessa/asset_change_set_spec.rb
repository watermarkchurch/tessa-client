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

  describe "#scoped_changes" do
    context "with changes not contained in scoped ids" do
      let(:args) {
        {
          changes: [
            Tessa::AssetChange.new(id: 1),
            Tessa::AssetChange.new(id: 2),
            Tessa::AssetChange.new(id: 3),
            Tessa::AssetChange.new(id: 4)],
          scoped_ids: [1, 2],
        }
      }

      it "only returns the scoped changes" do
        expect(set.scoped_changes.size).to eq(2)
        expect(set.scoped_changes.map(&:id)).to eq([1, 2])
      end

      it "will return scoped plus additional ids passed in :additional_scoped_ids" do
        scoped_changes = set.scoped_changes(additional_scoped_ids: [3])
        expect(scoped_changes.size).to eq(3)
        expect(scoped_changes.map(&:id)).to eq([1, 2, 3])
      end
    end
  end

  describe "#apply" do
    let(:args) {
      {
        changes: [
          Tessa::AssetChange.new(id: 1),
          Tessa::AssetChange.new(id: 2)],
        scoped_ids: [1],
      }
    }

    it "calls apply on each scoped change" do
      expect(set.changes[0]).to receive(:apply)
      expect(set.changes[1]).not_to receive(:apply)
      set.apply
    end

    it "calls apply on scoped plus additional ids from :additional_scoped_ids" do
      expect(set.changes[0]).to receive(:apply)
      expect(set.changes[1]).to receive(:apply)
      set.apply(additional_scoped_ids: [2])
    end
  end

  describe "#+" do
    let(:a) {
      described_class.new(
        changes: [Tessa::AssetChange.new(id: 1, action: 'add')],
        scoped_ids: [1],
      )
    }
    let(:b) {
      described_class.new(
        changes: [Tessa::AssetChange.new(id: 2, action: 'add')],
        scoped_ids: [2],
      )
    }
    subject(:sum) { a + b }

    it "concatenates the values of changes" do
      expect(sum.changes.collect(&:id)).to eq([1, 2])
    end

    it "concatenates the values of scoped_ids" do
      expect(sum.scoped_ids).to eq([1, 2])
    end

    context "with duplicate entries" do
      subject(:sum) { a + b + b }

      it "only includes unique values" do
        expect(sum.changes.collect(&:id)).to eq([1, 2])
        expect(sum.scoped_ids).to eq([1, 2])
      end
    end
  end

end
