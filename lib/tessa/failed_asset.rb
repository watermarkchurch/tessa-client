module Tessa
  class FailedAsset
    include Virtus.model

    attribute :id, Integer
    attribute :error, StandardError
  end
end
