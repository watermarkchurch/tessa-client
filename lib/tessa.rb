require "tessa/version"

require "faraday"
require "virtus"
require "json"

require "tessa/config"
require "tessa/response_factory"
require "tessa/asset"
require "tessa/asset_change"
require "tessa/asset_change_set"
require "tessa/controller_helpers"
require "tessa/model"
require "tessa/rack_upload_proxy"
require "tessa/upload"
require "tessa/view_helpers"

module Tessa
  def self.config
    @config ||= Config.new
  end

  def self.setup
    yield config
  end

  def self.find_assets(ids)
    if [*ids].empty?
      if ids.is_a?(Array)
        []
      else
        nil
      end
    elsif (blobs = ::ActiveStorage::Blob.where(key: ids).to_a).present?
      if ids.is_a?(Array)
        blobs.map { |a| Tessa::ActiveStorage::AssetWrapper.new(a) }
      else
        Tessa::ActiveStorage::AssetWrapper.new(blobs.first)
      end
    else
      Tessa::Asset.find(ids)
    end
  rescue Tessa::RequestFailed => err
    if ids.is_a?(Array)
      ids.map do |id|
        Tessa::Asset::Failure.factory(id: id, response: err.response)
      end
    else
      Tessa::Asset::Failure.factory(id: ids, response: err.response)
    end
  end

  class RequestFailed < StandardError
    attr_reader :response

    def initialize(message=nil, response=nil)
      super(message)
      @response = response
    end
  end

end

if defined?(Rails::Railtie)
  require "tessa/engine"
end
