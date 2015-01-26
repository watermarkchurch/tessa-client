require "tessa/version"

require "tessa/config"

module Tessa
  def self.config
    @config ||= Config.new
  end

  def self.setup
    yield config
  end
end
