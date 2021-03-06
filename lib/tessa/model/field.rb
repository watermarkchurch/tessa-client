module Tessa
  module Model
    class Field
      include Virtus.model

      attribute :model
      attribute :name, String
      attribute :multiple, Boolean, default: false
      attribute :id_field, String

      def id_field
        super || "#{name}#{default_id_field_suffix}"
      end

      def ids(on:)
        [*id(on: on)]
      end

      def id(on:)
        on.public_send(id_field)
      end

      def apply(set, on:)
        ids = ids(on: on)

        set.scoped_changes.each do |change|
          if change.add?
            ids << change.id
          elsif change.remove?
            ids.delete change.id
          end
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

      def difference_change_set(subtrahend_ids, on:)
        AssetChangeSet.new.tap do |change_set|
          (ids(on: on) - subtrahend_ids).each do |id|
            change_set.remove(id)
          end
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
end
