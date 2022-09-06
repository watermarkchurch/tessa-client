module Tessa
  class Config
    include Virtus.model

    DEFAULT_STRATEGY = "default"

    attribute :username, String, default: -> (*_) { ENV['TESSA_USERNAME'] }
    attribute :password, String, default: -> (*_) { ENV['TESSA_PASSWORD'] }
    attribute :url, String, default: -> (*_) { ENV['TESSA_URL'] }
    attribute :strategy, String, default: -> (*_) { ENV['TESSA_STRATEGY'] || DEFAULT_STRATEGY }

    def connection
      @connection ||= Tessa::FakeConnection.new
    end
  end
end
