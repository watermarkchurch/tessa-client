module Tessa
  class Upload
    include Virtus.model
    extend ResponseFactory

    attribute :success_url, String
    attribute :cancel_url, String
    attribute :upload_url, String
    attribute :upload_method, String

    def complete!(connection: Tessa.config.connection)
      Asset.new_from_response connection.patch(success_url)
    end

    def cancel!(connection: Tessa.config.connection)
      Asset.new_from_response connection.patch(cancel_url)
    end

    def self.create(connection: Tessa.config.connection,
                    strategy: Tessa.config.default_strategy,
                    **options)
      new_from_response connection.post('/uploads', options.merge(strategy: strategy))
    end
  end
end
