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

  it 'Stops after hitting the batch size' do
    1.upto(11).each do |i|
      asset = Tessa::Asset.new(id: i,
        meta: { name: 'README.md' },
        private_download_url: 'https://test.com/README.md')
      allow(Tessa::Asset).to receive(:find)
        .with(i)
        .and_return(asset)
      allow(Tessa::Asset).to receive(:find)
        .with([i])
        .and_return([asset])
    end
    stub_request(:get, 'https://test.com/README.md')
      .to_return(body: File.new('README.md'))

    # Mix of the two models...
    models =
      1.upto(11).map do |i|
        if i % 2 == 0
          MultipleAssetModel.create!(another_place: [i])
        else
          SingleAssetModel.create!(avatar_id: i)
        end
      end

    final_state = nil
    final_options = nil
    dbl = double('set')
    expect(dbl).to receive(:perform_later) do |state, options|
      final_state = Marshal.load(state)
      final_options = options
    end
    expect(Tessa::MigrateAssetsJob).to receive(:set)
      .with(wait: 10.minutes)
      .and_return(dbl) 
    
    expect {
      subject.perform
    }.to change { ActiveStorage::Attachment.count }.by(10)

    expect(final_state.fully_processed?).to be false
    expect(final_options).to eq({
      batch_size: 10,
      interval: 10.minutes.to_i
    })
    # One of the two models was fully processed
    expect(final_state.model_queue.count(&:fully_processed?))
      .to eq(1)
  end

  it 'Skips over Tessa errors' do
    1.upto(11).each do |i|
      if i % 2 == 0
        allow(Tessa::Asset).to receive(:find)
          .with(i)
          .and_raise(Tessa::RequestFailed)
        next
      end

      allow(Tessa::Asset).to receive(:find)
        .with(i)
        .and_return(
          Tessa::Asset.new(id: i,
            meta: { name: 'README.md' },
            private_download_url: 'https://test.com/README.md')
        )
    end
    stub_request(:get, 'https://test.com/README.md')
      .to_return(body: File.new('README.md'))

    # Mix of the two models...
    models =
      1.upto(11).map do |i|
        SingleAssetModel.create!(avatar_id: i)
      end

    final_state = nil
    final_options = nil
    dbl = double('set')
    expect(dbl).to receive(:perform_later) do |state, options|
      final_state = Marshal.load(state)
      final_options = options
    end
    expect(Tessa::MigrateAssetsJob).to receive(:set)
      .with(wait: 10.minutes)
      .and_return(dbl) 
    
    expect {
      subject.perform
    }.to change { ActiveStorage::Attachment.count }.by(5)

    expect(final_state.fully_processed?).to be false
    field_state = final_state.next_model.next_field
    expect(field_state.offset).to eq(5)
    expect(field_state.failed_ids).to eq(
      [2, 4, 6, 8, 10]
    )
  end

  it 'Resumes from marshalled state' do

    file = Rack::Test::UploadedFile.new('README.md')

    state = Tessa::MigrateAssetsJob::ProcessingState.initialize_from_models(
      [SingleAssetModel])
    field_state = state.model_queue
      .detect { |m| m.class_name == 'SingleAssetModel' }
      .field_queue
      .detect { |m| m.field_name == :avatar }
    
    1.upto(10).each do |i|
      if i % 2 == 0
        # This one failed
        SingleAssetModel.create!(avatar_id: i).tap do |r|
          field_state.failed_ids << r.id
          field_state.offset += 1
        end
      else
        # This one succeeded and is in ActiveStorage
        SingleAssetModel.create!(avatar: file).tap do |r|
          field_state.success_count += 1
        end
      end
    end
    
    # This one still needs to transition
    model = SingleAssetModel.create!(avatar_id: 11)

    asset = Tessa::Asset.new(id: 11,
      meta: { name: 'README.md' },
      private_download_url: 'https://test.com/README.md')
    allow(Tessa::Asset).to receive(:find)
      .with(11)
      .and_return(asset)
    stub_request(:get, 'https://test.com/README.md')
      .to_return(body: File.new('README.md'))

    # Doesn't reenqueue since we finished processing
    expect(Tessa::MigrateAssetsJob).to_not receive(:set)

    expect {
      subject.perform(Marshal.dump(state), { batch_size: 2, interval: 3 })
    }.to change { ActiveStorage::Attachment.count }.by(1)
  end
end