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
        if conn.respond_to?(:basic_auth)
          conn.basic_auth username, password
        else # Faraday >= 1.0
          conn.request :authorization, :basic, username, password
        end
        conn.request :url_encoded
        conn.adapter Faraday.default_adapter
      end
    end
  end
end
