module Tessa
  class AssetChange
    include Virtus.model

    attribute :id, Integer
    attribute :action, String
  end
end
