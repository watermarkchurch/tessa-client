module Tessa
  class AssetChangeSet
    include Virtus.model

    attribute :changes, Array[AssetChange]
    attribute :scoped_ids, Array[Integer]

    def scoped_ids=(new_ids)
      super new_ids.compact
    end
  end
end
