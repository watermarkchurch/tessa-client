require 'spec_helper'

RSpec.describe Tessa::Model do
  subject(:described_module) { described_class }
  let(:model) { Class.new.tap { |c| c.send(:include, described_module) } }

  it { is_expected.to be_a(Module) }

  describe "::asset" do
    it "creates ModelField and sets it by name to @tessa_fields" do
      model.asset :new_field
      expect(model.tessa_fields[:new_field]).to be_a(Tessa::Model::Field)
    end

    context "with a field named :avatar" do
      subject(:instance) { model.new }
      before do
        model.send :attr_accessor, :avatar_id
        model.asset :avatar
      end

      it "creates an #avatar method" do
        expect(instance).to respond_to(:avatar)
      end

      it "creates an #avatar= method" do
        expect(instance).to respond_to(:avatar=)
      end

      it "allows overriding and calling super" do
        model.class_eval do
          def avatar
            @override_test = true
            super
          end
        end

        instance.avatar
        expect(instance.instance_variable_get(:@override_test)).to eq(true)
      end
    end

    context "with customized field" do
      before do
        model.asset :custom_field, multiple: true, id_field: "another_place"
      end

      it "sets all attributes on ModelField properly" do
        field = model.tessa_fields[:custom_field]
        expect(field.name).to eq("custom_field")
        expect(field.multiple).to eq(true)
        expect(field.id_field).to eq("another_place")
      end
    end

    context "with inheritance hierarchy" do
      let(:submodel) { Class.new(model) }
      before do
        model.asset :field1
        submodel.asset :field2
        model.asset :field3
      end

      it "submodel has its own list of fields" do
        expect(submodel.tessa_fields.keys).to eq([:field1, :field2])
      end

      it "does not alter parent class fields" do
        expect(model.tessa_fields.keys).to eq([:field1, :field3])
      end
    end
  end

  describe "#asset_setter" do
    let(:instance) { model.new }

    context "with change set present for a field" do
      let(:a) { Tessa::Asset.new(id: 1) }
      let(:b) { Tessa::Asset.new(id: 2) }
      let(:set) { instance.pending_tessa_change_sets[:field] }
      before do
        model.send :attr_accessor, :field_id
        model.asset :field
        instance.field = a
      end

      it "combines the changes with the new set" do
        instance.field = b
        instance.field = nil
        changes = set.changes.map { |change| [change.id, change.action.to_sym] }
        expect(changes).to eq([
          [1, :add],
          [2, :add],
          [1, :remove],
          [2, :remove],
        ])
      end
    end

    context "with a multiple typed field" do
      before do
        model.send(:attr_accessor, :file_ids)
        model.asset :file, multiple: true
      end

      context "when set with array of assets" do
        let(:assets) {
          [
            Tessa::Asset.new(id: 1),
            Tessa::Asset.new(id: 2),
          ]
        }

        it "sets field to list of ids from assets" do
          instance.file = assets
          expect(instance.file_ids).to eq([1, 2])
        end

        it "removes any ids that aren't in list" do
          instance.file_ids = [3]
          instance.file = assets
          expect(instance.file_ids).to eq([1, 2])
        end

        it "adds an AssetChangeSet to pending queue for this field" do
          instance.file = assets
          expect(instance.pending_tessa_change_sets).to be_a(Hash)
          expect(instance.pending_tessa_change_sets[:file]).to be_a(Tessa::AssetChangeSet)
        end

        describe "the added change set" do
          subject(:set) { instance.pending_tessa_change_sets[:file] }

          it "has an 'add' action for each new asset" do
            instance.file = assets
            ids = set.changes.select { |c| c.action == 'add' }.collect(&:id)
            expect(ids).to eq([1, 2])
          end

          it "has a 'remove' action for each missing asset" do
            instance.file_ids = [3]
            instance.file = assets
            ids = set.changes.select { |c| c.action == 'remove' }.collect(&:id)
            expect(ids).to eq([3])
          end

          it "adds each of the ids to the scoped_ids list" do
            instance.file_ids = [3]
            instance.file = assets
            expect(set.scoped_ids).to eq([1, 2, 3])
          end
        end
      end

      context "when set with an AssetChangeSet" do
        let(:set) { Tessa::AssetChangeSet.new }
        before do
          set.add(1)
          set.add(2)
          set.changes << Tessa::AssetChange.new(id: 0, action: "add")
        end

        it "sets field to list of ids from scoped_changes" do
          instance.file = set
          expect(instance.file_ids).to eq([1, 2])
        end

        it "leaves any ids that are not touched by the set" do
          instance.file_ids = [3]
          instance.file = set
          expect(instance.file_ids).to include(1, 2, 3)
        end

        it "removes any ids from field that are scoped as removals" do
          instance.file_ids = [3]
          set.remove(3)
          instance.file = set
          expect(instance.file_ids).to eq([1, 2])
        end

        it "adds the AssetChangeSet to pending queue for this field" do
          instance.file = set
          new_set = instance.pending_tessa_change_sets[:file]
          expect(new_set.changes).to eq(set.changes)
          expect(new_set.scoped_ids).to eq(set.scoped_ids)
        end
      end
    end

    context "with a singular typed field" do
      before do
        model.send(:attr_accessor, :file_id)
        model.asset :file
      end

      context "when set with an Asset" do
        let(:asset) { Tessa::Asset.new(id: 1) }

        it "sets field to id from asset" do
          instance.file = asset
          expect(instance.file_id).to eq(1)
        end

        it "adds an AssetChangeSet to pending queue for this field" do
          instance.file = asset
          expect(instance.pending_tessa_change_sets[:file]).to be_a(Tessa::AssetChangeSet)
        end

        describe "the added change set" do
          let(:set) { instance.pending_tessa_change_sets[:file] }

          it "has an 'add' action for the new asset" do
            instance.file = asset
            expect(set.changes.select(&:add?).first.id).to eq(1)
          end

          it "has a 'remove' action for the previous asset" do
            instance.file_id = 2
            instance.file = asset
            expect(set.changes.select(&:remove?).first.id).to eq(2)
          end
        end
      end

      context "when set with an AssetChangeSet" do
        let(:set) { Tessa::AssetChangeSet.new }
        before do
          set.changes << Tessa::AssetChange.new(id: 0, action: "add")
          set.add(1)
        end

        it "sets field to asset id of first 'add' action in scoped_changes" do
          instance.file = set
          expect(instance.file_id).to eq(1)
        end

        it "adds the AssetChangeSet to pending queue for this field" do
          instance.file = set
          new_set = instance.pending_tessa_change_sets[:file]
          expect(new_set.changes).to eq(set.changes)
          expect(new_set.scoped_ids).to eq(set.scoped_ids)
        end

        it 'keeps asset when set to existing value' do
          change_set = Tessa::AssetChangeSet.new(
            changes: { '999' => { 'action' => 'add' } },
            scoped_ids: [999]
          )
          instance.file = change_set
          expect(instance.file_id).to eq(999)

          change_set.scoped_ids = [4, 5, 6]
          instance.file = change_set
          removals = change_set.changes.select(&:remove?).map(&:id)
          expect(removals).to_not include(999)
          expect(instance.file_id).to eq(999)

          instance.file = change_set
          expect(instance.file_id).to eq(999)
        end

        context "with no remove in change set" do
          it "ensures there is a 'remove' action for previous value" do
            instance.file_id = 2
            instance.file = set
            expect(set.scoped_changes.select(&:remove?).map(&:id)).to eq([2])
          end
        end
      end
    end
  end

  describe "#asset_getter" do
    let(:instance) { model.new }
    subject(:getter) { instance.file }

    context "with a multiple typed field" do
      before do
        model.send(:attr_accessor, :file_ids)
        model.asset :file, multiple: true
      end

      it "calls find for each of the file_ids and returns result" do
        instance.file_ids = [1, 2, 3]
        expect(Tessa::Asset).to receive(:find).with([1, 2, 3]).and_return([:a1, :a2, :a3])
        expect(getter).to eq([:a1, :a2, :a3])
      end

      it "caches the result" do
        instance.file_ids = [1]
        expect(Tessa::Asset).to receive(:find).and_return(:val).once
        instance.file
        instance.file
      end

      context "with no values" do
        it "does not call find" do
          instance.file_ids = []
          expect(Tessa::Asset).not_to receive(:find)
          expect(instance.file).to eq([])
        end
      end
    end

    context "with a singular typed field" do
      before do
        model.send(:attr_accessor, :file_id)
        model.asset :file
      end

      it "calls find for file_id and returns result" do
        instance.file_id = 1
        expect(Tessa::Asset).to receive(:find).with(1).and_return(:a1)
        expect(getter).to eq(:a1)
      end

      it "caches the result" do
        instance.file_id = 1
        expect(Tessa::Asset).to receive(:find).and_return(:val).once
        instance.file
        instance.file
      end

      context "with nil value" do
        it "does not call find" do
          instance.file_id = nil
          expect(Tessa::Asset).not_to receive(:find)
          expect(instance.file).to be_nil
        end
      end
    end
  end

  describe "#apply_tessa_change_sets" do
    let(:instance) { model.new }
    let(:sets) { Array.new(2) { instance_spy(Tessa::AssetChangeSet) } }

    before do
      model.asset :field1
      model.asset :field2
      instance.instance_variable_set(
        :@pending_tessa_change_sets,
        {
          field1: sets[0],
          field2: sets[1],
        }
      )
    end

    it "iterates over all pending changesets calling apply" do
      instance.apply_tessa_change_sets
      expect(sets[0]).to have_received(:apply)
      expect(sets[1]).to have_received(:apply)
    end

    it "removes all changesets from list" do
      instance.apply_tessa_change_sets
      expect(instance.pending_tessa_change_sets).to be_empty
    end

    context "no @pending_tessa_change_sets ivar" do
      before do
        instance.instance_variable_set(
          :@pending_tessa_change_sets,
          nil
        )
      end

      it "doesn't raise error" do
        expect { instance.apply_tessa_change_sets }.to_not raise_error
      end
    end
  end

  describe "#fetch_tessa_remote_assets" do
    subject(:result) { model.new.fetch_tessa_remote_assets(arg) }

    before do
      model.asset :avatar
    end

    context "argument is `nil`" do
      let(:arg) { nil }

      it "returns nil" do
        expect(result).to be_nil
      end
    end

    context "argument is `[]`" do
      let(:arg) { [] }

      it "returns []" do
        expect(result).to be_a(Array)
        expect(result).to be_empty
      end
    end

    context "when argument is not blank" do
      let(:id) { rand(100) }
      let(:arg) { id }

      it "calls Tessa::Asset.find with arguments" do
        expect(Tessa::Asset).to receive(:find).with(arg)
        result
      end

      context "when Tessa::Asset.find raises RequestFailed exception" do
        let(:error) {
          Tessa::RequestFailed.new("test exception", double(status: '500'))
        }

        before do
          allow(Tessa::Asset).to receive(:find).and_raise(error)
        end

        context "argument is single id" do
          let(:arg) { id }

          it "returns Failure" do
            expect(result).to be_a(Tessa::Asset::Failure)
          end

          it "returns asset with proper data" do
            expect(result.id).to eq(arg)
          end
        end

        context "argument is array" do
          let(:arg) { [ id, id * 2 ] }

          it "returns array" do
            expect(result).to be_a(Array)
          end

          it "returns instances of Failure" do
            expect(result).to all( be_a(Tessa::Asset::Failure) )
          end

          it "returns array with an asset for each id passed" do
            arg.zip(result) do |a, r|
              expect(r.id).to eq(a)
            end
          end
        end
      end
    end
  end

  describe "#remove_all_tessa_assets" do
    let(:instance) { model.new }
    before do
      model.send :attr_accessor, :field1_id, :field2_ids
      model.asset :field1
      model.asset :field2, multiple: true
      instance.field1_id = 1
      instance.field2_ids = [2, 3]
    end

    it "adds pending change sets for each field removing all current assets" do
      instance.remove_all_tessa_assets
      changes = instance.pending_tessa_change_sets.values
        .reduce(Tessa::AssetChangeSet.new, :+)
        .changes
        .map { |change| [change.id, change.action.to_sym] }
        expect(changes).to eq([
          [1, :remove],
          [2, :remove],
          [3, :remove],
        ])
    end
  end

  describe "adds callbacks" do
    context "model responds to after_commit" do
      let(:model) {
        Class.new do
          def self.after_commit(arg=nil)
            @after_commit ||= arg
          end
        end.tap { |c| c.send(:include, described_module) }
      }

      it "calls it with :apply_tessa_change_sets" do
        expect(model.after_commit).to eq(:apply_tessa_change_sets)
      end
    end

    context "model responds to before_destroy" do
      let(:model) {
        Class.new do
          def self.before_destroy(arg=nil)
            @before_destroy ||= arg
          end
        end.tap { |c| c.send(:include, described_module) }
      }

      it "calls it with :remove_all_tessa_assets" do
        expect(model.before_destroy).to eq(:remove_all_tessa_assets)
      end
    end
  end

end
