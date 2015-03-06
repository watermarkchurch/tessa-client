module Tessa
  class Config
    attr_accessor :username, :password
    attr_accessor :url, :default_strategy

    def initialize
      @username ||= ENV['TESSA_USERNAME']
      @password ||= ENV['TESSA_PASSWORD']
      @url ||= ENV['TESSA_URL']
      @default_strategy ||= ENV['TESSA_DEFAULT_STRATEGY']
    end

    def connection
      @connection ||= Faraday.new(url: url) do |conn|
        conn.request :digest, username, password
        conn.adapter Faraday.default_adapter
      end
    end
  end
end
