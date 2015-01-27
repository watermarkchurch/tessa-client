require 'uri'
require 'securerandom'

module Tessa
  class Asset
    attr_reader :uuid, :metadata, :uri

    def initialize(uuid:, metadata: nil, uri: nil)
      @uuid = uuid
      @metadata = metadata
      @uri = URI(uri || "")
    end

    def download(backend_db: Backend.db)
      raise if uri.scheme.nil?
      backend = backend_db.fetch(uri.scheme)
      backend.download(uri)
    end

    def upload(file, backend: Tessa.config.default_backend)
      @uri = backend.upload(file)
    end

    def self.create
      new(uuid: SecureRandom.uuid)
    end
  end
end
