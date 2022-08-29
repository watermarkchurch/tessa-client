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

      it "No longer calls Tessa::Asset#find" do
        instance.another_place = [1, 2, 3]
        expect(Tessa::Asset).to_not receive(:find)
        expect(getter).to eq([])
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

      it "No longer calls Tessa::Asset#find" do
        instance.avatar_id = 1
        expect(Tessa::Asset).to_not receive(:find)
        expect(getter).to eq(nil)
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
    end
  end
end
