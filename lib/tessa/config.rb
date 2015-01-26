module Tessa
  class Config
    attr_accessor :backends, :default_backend

    def initialize(options = {})
      @backends = {}
    end

    def default_backend
      @backends[@default_backend]
    end
  end
end
