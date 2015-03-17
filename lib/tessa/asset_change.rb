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

    def apply
      case action
      when "add"
        asset.complete!
      when "remove"
        asset.delete!
      end
    end

    private

    def asset
      Tessa::Asset.new(id: id)
    end
  end
end
