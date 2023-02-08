require "tessa/version"

require "virtus"
require "json"

require "tessa/fake_connection"
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

if defined?(ActiveJob)
  require "tessa/jobs/migrate_assets_job"
end

if defined?(SimpleForm)
  require "tessa/simple_form"
end

module Tessa
  class << self
    def config
      @config ||= Config.new
    end

    def setup
      yield config
    end

    def find_assets(ids)
      return find_all_assets(ids) if ids.is_a?(Array)

      return find_asset(ids)
    end

    def model_registry
      @model_registry ||= []
    end

    private

    def find_asset(id)
      return nil unless id

      if blob = ::ActiveStorage::Blob.find_by(key: id)
        return Tessa::ActiveStorage::AssetWrapper.new(blob)
      end

      Tessa::Asset.find(id)
    rescue Tessa::RequestFailed => err
      Tessa::Asset::Failure.factory(id: id, response: err.response)
    end

    def find_all_assets(ids)
      return [] if ids.empty?

      blobs = ::ActiveStorage::Blob.where(key: ids).to_a
        .map { |a| Tessa::ActiveStorage::AssetWrapper.new(a) }
      ids = ids - blobs.map(&:key)
      assets = 
        begin
          Tessa::Asset.find(ids) if ids.any?
        rescue Tessa::RequestFailed => err
          ids.map do |id|
            Tessa::Asset::Failure.factory(id: id, response: err.response)
          end
        end

      [*blobs, *assets]
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
