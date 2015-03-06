require "tessa/version"

require "faraday"
require "faraday/digestauth"

require "tessa/config"
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
