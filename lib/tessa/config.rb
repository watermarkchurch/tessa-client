module Tessa
  class Config
    include Virtus.model

    attribute :username, String, default: -> (*_) { ENV['TESSA_USERNAME'] }
    attribute :password, String, default: -> (*_) { ENV['TESSA_PASSWORD'] }
    attribute :url, String, default: -> (*_) { ENV['TESSA_URL'] }
    attribute :default_strategy, String, default: -> (*_) { ENV['TESSA_DEFAULT_STRATEGY'] }

    def connection
      @connection ||= Faraday.new(url: url) do |conn|
        conn.request :digest, username, password
        conn.adapter Faraday.default_adapter
      end
    end
  end
end
