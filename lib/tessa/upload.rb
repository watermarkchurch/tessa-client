module Tessa
  class Upload
    include Virtus.model

    attribute :success_url, String
    attribute :cancel_url, String
    attribute :upload_url, String
    attribute :upload_method, String

    def self.create(connection: Tessa.config.connection,
                    strategy: Tessa.config.default_strategy,
                    **options)
      new_from_response connection.post('/uploads', options.merge(strategy: strategy))
    end

    def self.new_from_response(response)
      new JSON.parse(response.body)
    end
  end
end
