module Tessa
  class Upload
    include Virtus.model
    extend ResponseFactory

    attribute :asset_id, Integer
    attribute :upload_url, String
    attribute :upload_method, String

    def self.create(connection: Tessa.config.connection,
                    strategy: Tessa.config.strategy,
                    **options)
      new_from_response connection.post('/uploads', options.merge(strategy: strategy))
    end
  end
end
