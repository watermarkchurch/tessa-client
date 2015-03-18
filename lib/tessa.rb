require "tessa/version"

require "faraday"
require "faraday/digestauth"
require "virtus"
require "json"

require "tessa/config"
require "tessa/response_factory"
require "tessa/asset"
require "tessa/asset_change"
require "tessa/asset_change_set"
require "tessa/model_field"
require "tessa/model"
require "tessa/upload"


module Tessa
  def self.config
    @config ||= Config.new
  end

  def self.setup
    yield config
  end

  class RequestFailed < StandardError
    attr_reader :response

    def initialize(message=nil, response=nil)
      super(message)
      @response = response
    end
  end

end
