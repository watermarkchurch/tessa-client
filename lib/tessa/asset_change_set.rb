module Tessa
  class AssetChangeSet
    include Virtus.model

    attribute :changes, Array[AssetChange]
    attribute :scoped_ids, Array[Integer]

    def scoped_ids=(new_ids)
      super new_ids.compact
    end

    def scoped_changes
      changes.select { |change| scoped_ids.include?(change.id) }
    end

    def apply
      scoped_changes.each(&:apply)
    end

    def +(b)
      self.changes = (self.changes + b.changes).uniq
      self.scoped_ids = (self.scoped_ids + b.scoped_ids).uniq
      self
    end

    def add(value)
      id = id_from_asset(value)
      changes << AssetChange.new(id: id, action: "add")
      scoped_ids << id
    end

    def remove(value)
      id = id_from_asset(value)
      changes << AssetChange.new(id: id, action: "remove")
      scoped_ids << id
    end

    private

    def id_from_asset(value)
      case value
      when Asset
        value.id
      when Fixnum
        value
      end
    end
  end
end
