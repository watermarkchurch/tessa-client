module Tessa
  class AssetChange
    include Virtus.model

    attribute :id, Integer
    attribute :action, String

    def initialize(args={})
      case args
      when Array
        id, attributes = args
        super attributes.merge(id: id)
      else
        super
      end
    end
  end
end
