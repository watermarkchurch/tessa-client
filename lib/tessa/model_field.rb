module Tessa
  class ModelField
    include Virtus.model

    attribute :model
    attribute :name, String
    attribute :multiple, Boolean, default: false
    attribute :id_field, String

    def id_field
      super || "#{name}#{default_id_field_suffix}"
    end

    def set(value, on:)
      previous_ids = [*on.public_send(id_field)]
      ids = previous_ids.dup

      value = [*value] if value.is_a?(Asset)

      case value
      when Array
        ids = value.collect(&:id)
      when AssetChangeSet
        add_ids = value.scoped_changes.select(&:add?).collect(&:id)
        remove_ids = value.scoped_changes.select(&:remove?).collect(&:id)
        ids = previous_ids + add_ids - remove_ids
      end

      if multiple?
        on.public_send(id_field_writer, ids)
      else
        on.public_send(id_field_writer, ids.first)
      end
    end

    def change_set_for(value)
      case value
      when AssetChangeSet
        value
      when Array
        value.map { |item| change_set_for(item) }.reduce(:+)
      when Asset
        AssetChangeSet.new.tap { |set| set.add(value) }
      else
        AssetChangeSet.new
      end
    end

    private

    def id_field_writer
      "#{id_field}="
    end

    def default_id_field_suffix
      if multiple
        "_ids"
      else
        "_id"
      end
    end
  end
end
