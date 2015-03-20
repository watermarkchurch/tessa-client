require 'spec_helper'

RSpec.describe Tessa::ControllerHelpers do
  let(:controller) {
    Class.new do
      attr_writer :session

      def session
        @session ||= {}
      end

    end.tap { |c| c.send :include, described_class }
  }
  subject(:instance) { controller.new }

  describe "#tessa_upload_asset_ids" do
    it "returns the value of session[:tessa_upload_asset_ids]" do
      instance.session = { tessa_upload_asset_ids: :value }
      expect(instance.tessa_upload_asset_ids).to eq(:value)
    end

    it "sets and returns session[:tessa_upload_asset_ids] to an empty array if nil" do
      array = instance.tessa_upload_asset_ids
      expect(array).to eq([])
      array << 123
      expect(instance.tessa_upload_asset_ids).to eq(array)
    end
  end

  describe "#params_for_asset" do
    it "returns a Tessa::AssetChangeSet" do
      expect(instance.params_for_asset({})).to be_a(Tessa::AssetChangeSet)
    end

    it "sets the value of changes to the argument passed" do
      changes = [Tessa::AssetChange.new(id: 1)]
      expect(instance.params_for_asset(changes).changes).to eq(changes)
    end

    it "sets the scoped_ids to the value of tessa_upload_asset_ids" do
      scoped_ids = [1, 2, 3]
      instance.session[:tessa_upload_asset_ids] = scoped_ids
      expect(instance.params_for_asset([]).scoped_ids).to eq(scoped_ids)
    end

    it "ensures a unique array" do
      scoped_ids = [1]
      instance.session[:tessa_upload_asset_ids] = scoped_ids
      set = instance.params_for_asset([])
      set.scoped_ids << 2
      expect(scoped_ids).to eq([1])
    end
  end

end
