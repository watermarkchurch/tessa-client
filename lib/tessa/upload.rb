module Tessa
  class Upload
    include Virtus.model
    extend ResponseFactory

    attribute :asset_id, Integer
    attribute :upload_url, String
    attribute :upload_method, String

    def upload_file(file)
      if UploadsFile.new(upload: self).(file)
        asset.complete!
      else
        asset.cancel!
        false
      end
    end

    def self.create(connection: Tessa.config.connection,
                    strategy: Tessa.config.strategy,
                    **options)
      new_from_response connection.post('/uploads', options.merge(strategy: strategy))
    end

    private def asset
      Asset.new(id: asset_id)
    end
  end
end

require 'tessa/upload/uploads_file'
