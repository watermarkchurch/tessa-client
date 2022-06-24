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
end