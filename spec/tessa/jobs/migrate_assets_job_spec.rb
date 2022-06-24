require 'rails_helper'

require 'tessa/jobs/migrate_assets_job'

RSpec.describe Tessa::MigrateAssetsJob do
  it 'does nothing if no db rows' do
    
    expect {
      subject.perform
    }.to_not change { ActiveStorage::Attachment.count }
  end

  it 'creates attachments for old tessa assets' do
    allow(Tessa::Asset).to receive(:find)
      .with(1)
      .and_return(
        Tessa::Asset.new(id: 1,
          meta: { name: 'README.md' },
          private_download_url: 'https://test.com/README.md')
      )
    
    allow(Tessa::Asset).to receive(:find)
      .with(2)
      .and_return(
        Tessa::Asset.new(id: 2,
          meta: { name: 'LICENSE.txt' },
          private_download_url: 'https://test.com/LICENSE.txt'),
      )

    stub_request(:get, 'https://test.com/README.md')
      .to_return(body: File.new('README.md'))
    stub_request(:get, 'https://test.com/LICENSE.txt')
      .to_return(body: File.new('LICENSE.txt'))

      # DB models with those
    models = [
      SingleAssetModel.create!(avatar_id: 1),
      SingleAssetModel.create!(avatar_id: 2)
    ]

    expect {
      subject.perform
    }.to change { ActiveStorage::Attachment.count }.by(2)

    models.each do |m|
      expect(m.reload.avatar_id).to eq(m.avatar.key)
      # Now it's in activestorage
      expect(m.avatar.public_url).to start_with(
        'https://www.example.com/rails/active_storage/blobs/')
    end

    expect(SingleAssetModel.where.not('avatar_id' => nil).count)
      .to eq(0)
  end

  it 'preserves ActiveStorage blobs' do
    allow(Tessa::Asset).to receive(:find)
      .with([1, 2])
      .and_return([
        Tessa::Asset.new(id: 1,
          meta: { name: 'README.md' },
          private_download_url: 'https://test.com/README.md'),
        Tessa::Asset.new(id: 2,
          meta: { name: 'LICENSE.txt' },
          private_download_url: 'https://test.com/LICENSE.txt'),
      ])
    stub_request(:get, 'https://test.com/README.md')
      .to_return(body: File.new('README.md'))
    stub_request(:get, 'https://test.com/LICENSE.txt')
      .to_return(body: File.new('LICENSE.txt'))

    file2 = Rack::Test::UploadedFile.new("LICENSE.txt")

    model = MultipleAssetModel.create!(
      # The Tessa DB column has the one asset
      another_place: [1, 2]
    )
    # But has already attached a second ActiveStorage blob
    ::ActiveStorage::Attached::Many.new("multiple_field", model, dependent: :purge_later)
      .attach(file2)
    model.save!
    attachment = model.multiple_field_attachments.first

    expect {
      subject.perform
    }.to change { ActiveStorage::Attachment.count }.by(2)

    model = model.reload
    # The IDs are now the keys of ActiveStorage objects
    expect(model.another_place).to eq(
      model.multiple_field.map(&:key))
    # preserves the existing attachment
    expect(model.multiple_field_attachments).to include(attachment)
    expect(model.another_place).to include(attachment.key)

    # all assets are in activestorage
    model.multiple_field.each do |blob|
      expect(blob.public_url).to start_with(
        'https://www.example.com/rails/active_storage/blobs/')
    end

    # DB column is reset to nil
    expect(MultipleAssetModel.where.not('another_place' => nil).count)
      .to eq(0)
  end
end