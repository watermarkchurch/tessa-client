module Tessa
  class Config
    attr_accessor :username, :password
    attr_accessor :default_strategy

    def initialize
      @username ||= ENV['TESSA_USERNAME']
      @password ||= ENV['TESSA_PASSWORD']
      @default_strategy ||= ENV['TESSA_DEFAULT_STRATEGY']
    end
  end
end
