require "tessa/version"

require "faraday"
require "faraday/digestauth"
require "virtus"
require "json"

require "tessa/config"
require "tessa/response_factory"
require "tessa/asset"
require "tessa/upload"

module Tessa
  def self.config
    @config ||= Config.new
  end

  def self.setup
    yield config
  end
end
