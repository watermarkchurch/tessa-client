require 'open-uri'

class Tessa::MigrateAssetsJob < ActiveJob::Base

  def perform(*args)
    options = args&.extract_options!
    options = {
      batch_size: 10,
      interval: 10.minutes
    }.merge!(options&.symbolize_keys || {})
    processing_state = args.first ||
      load_models_from_registry

    if processing_state.fully_processed?
      Rails.logger.info("Nothing to do - all models have transitioned to ActiveStorage")
      return
    end

    processing_state.batch_count = 0
    while processing_state.batch_count < options[:batch_size]
      model_state = processing_state.next_model

      process(processing_state, model_state, options)

      break if processing_state.fully_processed?
    end

    unless processing_state.fully_processed?
      self.class.perform_later(processing_state, options)
    end
  end

  private

  def process(processing_state, model_state, options)
    while processing_state.batch_count < options[:batch_size]
      field_state = model_state.next_field

      process_field(processing_state, field_state, options)

      return if model_state.fully_processed?
    end
  end

  def process_field(processing_state, field_state, options)
    while processing_state.batch_count < options[:batch_size]
      remaining = options[:batch_size] - processing_state.batch_count

      next_batch = field_state.query
        .offset(field_state.offset)
        .limit(remaining)

      next_batch.each do |record|
        begin
          reupload(record, field_state)

        rescue StandardError => ex
          Rails.logger.error("Error reuploading #{record.id}##{field_state.field_name}\n#{ex}")
          field_state.failed_ids << record.id
        ensure
          field_state.offset += 1
          processing_state.batch_count += 1
        end
      end

      return if field_state.fully_processed?
    end
  end

  def reupload(record, field_state)
    if field_state.tessa_field.multiple?
      reupload_multiple(record, field_state)
    else
      reupload_single(record, field_state)
    end    
  end

  def reupload_single(record, field_state)
    # models with ActiveStorage uploads have nil in the column, but if you call
    # the method it hits the dynamic extensions and gives you the blob key
    database_id = record.attributes["_tessa_#{field_state.tessa_field.id_field}"]
    return unless database_id

    asset = Tessa::Asset.find(database_id)

    attachable = {
      io: URI.open(asset.private_download_url),
      filename: asset.meta[:name]
    }

    record.public_send("#{field_state.tessa_field.name}=", attachable)
    record.save!
  end

  def reupload_multiple(record, field_state)
    database_ids = record.attributes["_tessa_#{field_state.tessa_field.id_field}"]
    return unless database_ids
    
    assets = Tessa::Asset.find(database_ids)

    attachables = assets.map do |asset|
      {
        io: URI.open(asset.private_download_url),
        filename: asset.meta[:name]
      }
    end

    record.public_send("#{field_state.tessa_field.name}=", attachables)
    record.save!
  end

  def load_models_from_registry
    Rails.application.eager_load!

    # Load all Tessa models that can have attachments (not form objects)
    models = Tessa.model_registry
      .select { |m| m.respond_to?(:has_one_attached) }

    # Initialize our Record Keeping object
    ProcessingState.initialize_from_models(models)
  end

  ProcessingState = Struct.new(:model_queue, :batch_count) do
    def self.initialize_from_models(models)
      new(
        models.map do |model|
          ModelProcessingState.initialize_from_model(model)
        end,
        0
      )
    end

    def next_model
      model_queue.detect { |i| !i.fully_processed? }
    end

    def fully_processed?
      model_queue.all?(&:fully_processed?)
    end
  end

  ModelProcessingState = Struct.new(:class_name, :field_queue) do
    def self.initialize_from_model(model)
      new(
        model.name,
        model.tessa_fields.map do |name, _|
          FieldProcessingState.initialize_from_model(model, name)
        end
      )
    end

    def next_field
      field_queue.detect { |i| !i.fully_processed? }
    end

    def model
      @model ||= class_name.constantize
    end

    def fully_processed?
      field_queue.all?(&:fully_processed?)
    end
  end

  FieldProcessingState = Struct.new(:class_name, :field_name, :offset, :success_count, :failed_ids) do
    def self.initialize_from_model(model, field_name)
      new(
        model.name,
        field_name,
        0,
        0,
        []
      )
    end

    def model
      @model ||= class_name.constantize
    end

    def tessa_field
      model.tessa_fields[field_name]
    end

    def query
      model.where.not(Hash[tessa_field.id_field, nil])
    end

    def count
      query.count
    end

    def fully_processed?
      offset >= count
    end
  end
end