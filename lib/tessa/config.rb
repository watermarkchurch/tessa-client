module Tessa
  class Config
    include Virtus.model

    DEFAULT_STRATEGY = "default"

    attribute :username, String, default: -> (*_) { ENV['TESSA_USERNAME'] }
    attribute :password, String, default: -> (*_) { ENV['TESSA_PASSWORD'] }
    attribute :url, String, default: -> (*_) { ENV['TESSA_URL'] }
    attribute :strategy, String, default: -> (*_) { ENV['TESSA_STRATEGY'] || DEFAULT_STRATEGY }

    def connection
      @connection ||= Faraday.new(url: url) do |conn|
        conn.request :digest, username, password
        conn.request :url_encoded
        conn.adapter Faraday.default_adapter
      end
    end
  end
end
