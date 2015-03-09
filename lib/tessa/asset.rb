module Tessa
  class Asset
    include Virtus.model

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

    def self.new_from_response(response)
      case json = JSON.parse(response.body)
      when Array
        json.map { |record| new record }
      when Hash
        new json
      end
    end
  end
end
