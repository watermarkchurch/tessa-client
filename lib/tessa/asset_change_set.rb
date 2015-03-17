module Tessa
  class AssetChangeSet
    include Virtus.model

    attribute :changes, Array[AssetChange]
    attribute :scoped_ids, Array[Integer]

    def scoped_ids=(new_ids)
      super new_ids.compact
    end

    def scoped_changes(additional_scoped_ids: [])
      changes.select { |change|
        (scoped_ids + additional_scoped_ids).include?(change.id) }
    end

    def apply(**options)
      scoped_changes(**options).each(&:apply)
    end
  end
end
