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
      let(:instance) { model.new(another_place: []) }

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

    context "on a form object" do
      let(:model) {
        SingleAssetModelForm
      }
      subject(:instance) { model.new }

      it "creates an #avatar method" do
        expect(instance).to respond_to(:avatar)
      end

      it "creates an #avatar= method" do
        expect(instance).to respond_to(:avatar=)
      end
    end
  end

  describe "#asset_getter" do
    let(:instance) { model.new }

    context "with a multiple typed field" do
      let(:model) {
        MultipleAssetModel
      }
      let(:instance) { model.new(another_place: []) }
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

      it "wraps ActiveStorage uploads with AssetWrapper" do
        file = Rack::Test::UploadedFile.new("README.md")
        instance.avatar = file
        
        asset = instance.avatar
        expect(asset).to be_a(Tessa::ActiveStorage::AssetWrapper)
        # This goes to the blobs URL, which then redirects to the backend service URL
        expect(asset.public_url).to start_with('https://www.example.com/rails/active_storage/blobs/')
        # This is a direct download to the service URL (in test mode that is "disk")
        expect(asset.private_url).to start_with('https://www.example.com/rails/active_storage/disk/')
        expect(asset.private_download_url).to start_with('https://www.example.com/rails/active_storage/disk/')
        expect(asset.private_download_url).to include('&disposition=attachment')
      end

      context "with nil value" do
        it "does not call find" do
          instance.avatar_id = nil
          expect(Tessa::Asset).not_to receive(:find)
          expect(instance.avatar).to be_nil
        end
      end
    end

    context "on a form object" do
      let(:model) {
        SingleAssetModelForm
      }
      subject(:getter) { instance.avatar }
      
      it 'returns nil when empty' do
        expect(getter).to be_nil
      end

      it 'returns assigned upload object' do
        file = Rack::Test::UploadedFile.new("README.md")
        instance.avatar = file
        expect(getter).to eq(file)
      end
    end
  end

  describe "#asset_setter" do
    let(:instance) { model.new }

    context "with a singular typed field" do
      let(:model) {
        SingleAssetModel
      }
      subject(:getter) { instance.avatar }
      let(:file) {
        Rack::Test::UploadedFile.new("README.md")
      }

      it 'attaches uploaded file' do
        instance.avatar = file

        expect(getter.name).to eq('avatar')
        expect(getter.filename).to eq('README.md')
        expect(getter.content_type).to eq('text/plain')
        expect(getter.service_url)
          .to start_with('https://www.example.com/rails/active_storage/disk/')
      end

      it 'sets the ID to be the ActiveStorage key' do
        instance.avatar = file

        expect(instance.avatar_id).to eq(instance.avatar_attachment.key)
      end

      it 'sets the ID in the attributes' do
        instance.avatar = file
        
        expect(instance.attributes['avatar_id']).to eq(instance.avatar_attachment.key)
      end

      it 'attaches signed ID from Tessa::AssetChangeSet' do
        blob = ::ActiveStorage::Blob.create_before_direct_upload!({
          filename: 'README.md',
          byte_size: file.size,
          content_type: file.content_type,
          checksum: '1234'
        })

        changeset = Tessa::AssetChangeSet.new(
          changes: [{ 'id' => blob.signed_id, 'action' => 'add' }]
        )
        instance.avatar = changeset

        expect(instance.avatar_id).to eq(instance.avatar_attachment.key)
      end

      it 'does nothing when "add"ing an existing blob' do
        # Before this HTTP POST, we've previously uploaded this file
        instance.avatar = file

        # In this HTTP POST, we re-upload the 'add' action with the same ID
        changeset = Tessa::AssetChangeSet.new(
          changes: [{ 'id' => instance.avatar_attachment.key, 'action' => 'add' }]
        )

        # We expect that we're not going to detatch the existing attachment
        expect(instance.avatar_attachment).to_not receive(:destroy)

        # act
        instance.avatar = changeset

        expect(instance.avatar_id).to eq(instance.avatar_attachment.key)
      end
    end

    context "with a multiple typed field" do
      let(:model) {
        MultipleAssetModel
      }
      let(:instance) { model.new(another_place: []) }
      let(:file) {
        Rack::Test::UploadedFile.new("README.md")
      }
      let(:file2) {
        Rack::Test::UploadedFile.new("LICENSE.txt")
      }

      it 'attaches uploaded files' do
        instance.multiple_field = [file, file2]

        expect(instance.multiple_field[0].name).to eq('multiple_field')
        expect(instance.multiple_field[0].filename).to eq('README.md')
        expect(instance.multiple_field[0].content_type).to eq('text/plain')
        expect(instance.multiple_field[0].service_url)
          .to start_with('https://www.example.com/rails/active_storage/disk/')
        expect(instance.multiple_field[1].name).to eq('multiple_field')
        expect(instance.multiple_field[1].filename).to eq('LICENSE.txt')
        expect(instance.multiple_field[1].content_type).to eq('text/plain')
        expect(instance.multiple_field[1].service_url)
          .to start_with('https://www.example.com/rails/active_storage/disk/')
      end

      it 'sets the ID to be the ActiveStorage key' do
        instance.multiple_field = [file, file2]

        expect(instance.another_place).to eq(instance.multiple_field_attachments.map(&:key))
      end

      it 'sets the ID in the attributes' do
        instance.multiple_field = [file, file2]
        
        expect(instance.attributes['another_place']).to eq(instance.multiple_field_attachments.map(&:key))
      end

      it 'attaches signed ID from Tessa::AssetChangeSet' do
        blob = ::ActiveStorage::Blob.create_before_direct_upload!({
          filename: 'README.md',
          byte_size: file.size,
          content_type: file.content_type,
          checksum: '1234'
        })
        blob2 = ::ActiveStorage::Blob.create_before_direct_upload!({
          filename: "LICENSE.txt",
          byte_size: file2.size,
          content_type: file2.content_type,
          checksum: '5678'
        })

        changeset = Tessa::AssetChangeSet.new(
          changes: [
            { 'id' => blob.signed_id, 'action' => 'add' },
            { 'id' => blob2.signed_id, 'action' => 'add' },
          ]
        )
        instance.multiple_field = changeset

        expect(instance.another_place).to eq([
          blob.key,
          blob2.key
        ])
      end

      it 'does nothing when "add"ing an existing blob' do
        # Before this HTTP POST, we've previously uploaded these files
        instance.multiple_field = [file, file2]
        keys = instance.multiple_field_attachments.map(&:key)

        # In this HTTP POST, we re-upload the 'add' action with the same ID
        changeset = Tessa::AssetChangeSet.new(
          changes: [
            { 'id' => keys[0], 'action' => 'add' },
            { 'id' => keys[1], 'action' => 'add' },
          ]
        )

        # We expect that we're not going to detatch the existing attachment
        instance.multiple_field_attachments.each do |a|
          expect(a).to_not receive(:destroy)
        end

        # act
        instance.multiple_field = changeset

        expect(instance.another_place).to eq(keys)
      end

      it 'replaces Tessa assets with ActiveStorage assets' do
        # Before deploying this code, we previously had DB records with Tessa IDs
        instance.update!(another_place: [1, 2, 3])

        # In this HTTP POST, we removed one of the tessa assets and uploaded a
        # new ActiveStorage asset
        blob = ::ActiveStorage::Blob.create_before_direct_upload!({
          filename: 'README.md',
          byte_size: file.size,
          content_type: file.content_type,
          checksum: '1234'
        })
        changeset = Tessa::AssetChangeSet.new(
          changes: [
            { 'id' => 1, 'action' => 'add' },
            { 'id' => 2, 'action' => 'remove' },
            { 'id' => 3, 'action' => 'add' },
            { 'id' => blob.signed_id, 'action' => 'add' },
          ]
        )

        # We'll download these assets when we access #multiple_field
        allow(Tessa.config.connection).to receive(:get)
          .with("/assets/1,3")
          .and_return(double("response",
            success?: true,
            body: [
              { 'id' => 1, 'public_url' => 'test1' },
              { 'id' => 2, 'public_url' => 'test2' }
            ].to_json))

        blob.upload(file)

        # act
        instance.multiple_field = changeset

        expect(instance.another_place).to eq([
          blob.key, 1, 3
        ])

        assets = instance.multiple_field
        expect(assets[0].key).to eq(blob.key)
        expect(assets[0].service_url)
          .to start_with('https://www.example.com/rails/active_storage/disk/')

        expect(assets[1].id).to eq(1)
        expect(assets[1].public_url).to eq('test1')
        expect(assets[2].id).to eq(2)
        expect(assets[2].public_url).to eq('test2')
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
      let(:instance) { model.new(another_place: []) }
      
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
