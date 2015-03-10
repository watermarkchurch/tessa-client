module Tessa
  class Asset
    include Virtus.model
    extend ResponseFactory

    attribute :id, Integer
    attribute :status, String
    attribute :strategy, String
    attribute :meta, Hash[Symbol => String]
    attribute :public_url, String
    attribute :private_url, String
    attribute :delete_url, String

    def self.find(*ids,
                  connection: Tessa.config.connection)
      new_from_response connection.get("/assets/#{ids.join(",")}")
    end
  end
end
