module Tessa
  class Asset
    attr_reader :uuid, :metadata, :location_url

    def initialize(uuid:, metadata: nil, location_url: nil)
      @uuid = uuid
      @metadata = metadata
      @location_url = location_url
    end

    def write(file, backend: Tessa.default_backend)
      @location_url = backend.write(file)
    end
  end
end
