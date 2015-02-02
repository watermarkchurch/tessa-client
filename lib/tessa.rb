require "tessa/version"

require "tessa/config"
require "tessa/asset"

require "tessa/dragonfly"

module Tessa
  def self.config
    @config ||= Config.new
  end

  def self.setup
    yield config
  end
end
