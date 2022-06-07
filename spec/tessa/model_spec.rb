require 'rails_helper'

RSpec.describe Tessa::Model do
  subject(:described_module) { described_class }
  let(:model) {
    SingleAssetModel
  }

  it { is_expected.to be_a(Module) }

  describe "::asset" do
    it "creates ModelField and sets it by name to @tessa_fields" do
      expect(model.tessa_fields[:avatar]).to be_a(Tessa::Model::Field)
    end

    context "with a field named :avatar" do
      subject(:instance) { model.new }

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
      let(:model) {
        MultipleAssetModel
      }

      it "sets all attributes on ModelField properly" do
        field = model.tessa_fields[:multiple_field]
        expect(field.name).to eq("multiple_field")
        expect(field.multiple).to eq(true)
        expect(field.id_field).to eq("another_place")
      end
    end

    context "with inheritance hierarchy" do
      let(:submodel) {
        Class.new(model) do
          asset :field2
        end
      }

      it "submodel has its own list of fields" do
        expect(submodel.tessa_fields.keys).to eq([:avatar, :field2])
      end

      it "does not alter parent class fields" do
        expect(model.tessa_fields.keys).to eq([:avatar])
      end
    end
  end

  describe "#asset_getter" do
    let(:instance) { model.new }

    context "with a multiple typed field" do
      let(:model) {
        MultipleAssetModel
      }
      subject(:getter) { instance.multiple_field }

      it "calls find for each of the file_ids and returns result" do
        instance.another_place = [1, 2, 3]
        expect(Tessa::Asset).to receive(:find).with([1, 2, 3]).and_return([:a1, :a2, :a3])
        expect(getter).to eq([:a1, :a2, :a3])
      end

      it "caches the result" do
        instance.another_place = [1]
        expect(Tessa::Asset).to receive(:find).and_return(:val).once
        instance.multiple_field
        instance.multiple_field
      end

      context "with no values" do
        it "does not call find" do
          instance.another_place = []
          expect(Tessa::Asset).not_to receive(:find)
          expect(instance.multiple_field).to eq([])
        end
      end
    end

    context "with a singular typed field" do
      let(:model) {
        SingleAssetModel
      }
      subject(:getter) { instance.avatar }

      it "calls find for file_id and returns result" do
        instance.avatar_id = 1
        expect(Tessa::Asset).to receive(:find).with(1).and_return(:a1)
        expect(getter).to eq(:a1)
      end

      it "caches the result" do
        instance.avatar_id = 1
        expect(Tessa::Asset).to receive(:find).and_return(:val).once
        instance.avatar
        instance.avatar
      end

      context "with nil value" do
        it "does not call find" do
          instance.avatar_id = nil
          expect(Tessa::Asset).not_to receive(:find)
          expect(instance.avatar).to be_nil
        end
      end
    end
  end

  describe "#apply_tessa_change_sets" do
    let(:instance) { model.new }
    let(:sets) { [ instance_spy(Tessa::AssetChangeSet) ] }

    before do
      instance.instance_variable_set(
        :@pending_tessa_change_sets,
        {
          avatar: sets[0],
        }
      )
    end

    it "iterates over all pending changesets calling apply" do
      instance.apply_tessa_change_sets
      expect(sets[0]).to have_received(:apply)
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

    context "with a single typed field" do
      let(:model) {
        SingleAssetModel
      }

      before do
        instance.avatar_id = 1
      end

      it "adds pending change sets for each field removing all current assets" do
        instance.remove_all_tessa_assets
        changes = instance.pending_tessa_change_sets.values
          .reduce(Tessa::AssetChangeSet.new, :+)
          .changes
          .map { |change| [change.id, change.action.to_sym] }
          expect(changes).to eq([
            [1, :remove]
          ])
      end
    end


    context "with a multiple typed field" do
      let(:model) {
        MultipleAssetModel
      }
      
      before do
        instance.another_place = [2, 3]
      end

      it "adds pending change sets for each field removing all current assets" do
        instance.remove_all_tessa_assets
        changes = instance.pending_tessa_change_sets.values
          .reduce(Tessa::AssetChangeSet.new, :+)
          .changes
          .map { |change| [change.id, change.action.to_sym] }
          expect(changes).to eq([
            [2, :remove],
            [3, :remove],
          ])
      end
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
