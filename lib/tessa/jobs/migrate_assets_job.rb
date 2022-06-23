class Tessa::MigrateAssetsJob < ActiveJob::Base

  def perform(*args)
    options = args&.extract_options!
    options = {
      batch_size: 10,
      interval: 10.minutes
    }.merge!(options&.symbolize_keys || {})
    klasses = args.presence ||
      load_models_from_registry

    count = 0
    while klasses.any?
      count += process(klasses.first, batch_size: options[:batch_size] - count)
      if count >= options[:batch_size]
        klasses.shift
        self.class.perform_later(*klasses, **options)
      end
    end
  end

  private

  def process(klass, batch_size:)
    count = 0
    klass.tessa_fields.each do |name, field|
      # Find all records where id field is not nil, limit by batch size
      records = klass
        .where.not(Hash[field.id_field, nil])
        .limit(batch_size)
        .to_a

      records.each { |r| reupload(r, field) }
      count += records.length
      break if count >= batch_size
    end

    count
  end

  def reupload(record, field)
    # TODO
  end

  def load_models_from_registry
    Rails.application.eager_load!
    Tessa.model_registry
  end
end