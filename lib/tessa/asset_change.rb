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
      if add?
        asset.complete!
      elsif remove?
        asset.delete!
      end
    end

    def add?
      action == 'add'
    end

    def remove?
      action == 'remove'
    end

    private

    def asset
      Tessa::Asset.new(id: id)
    end
  end
end
