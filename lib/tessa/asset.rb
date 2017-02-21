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
    attribute :private_download_url, String
    attribute :delete_url, String

    def complete!(connection: Tessa.config.connection)
      Asset.new_from_response connection.patch("/assets/#{id}/completed")
    end

    def cancel!(connection: Tessa.config.connection)
      Asset.new_from_response connection.patch("/assets/#{id}/cancelled")
    end

    def delete!(connection: Tessa.config.connection)
      Asset.new_from_response connection.delete("/assets/#{id}")
    end

    def self.find(*ids,
                  connection: Tessa.config.connection)
      new_from_response connection.get("/assets/#{ids.join(",")}")
    end

    def failure?
      false
    end
  end
end

require 'tessa/asset/failure'
