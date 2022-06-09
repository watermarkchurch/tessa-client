require 'tessa/model/field'
require 'tessa/model/dynamic_extensions'
require 'tessa/active_storage/asset_wrapper'

module Tessa
  module Model

    def self.included(base)
      base.send :include, InstanceMethods
      base.extend ClassMethods
      base.after_commit :apply_tessa_change_sets if base.respond_to?(:after_commit)
      base.before_destroy :remove_all_tessa_assets if base.respond_to?(:before_destroy)
    end

    module InstanceMethods

      def pending_tessa_change_sets
        @pending_tessa_change_sets ||= Hash.new { AssetChangeSet.new }
      end

      def apply_tessa_change_sets
        pending_tessa_change_sets.delete_if do |_, change_set|
          change_set.apply
        end
      end

      def remove_all_tessa_assets
        self.class.tessa_fields.each do |name, field|
          change_set = pending_tessa_change_sets[name]
          field.ids(on: self).each do |asset_id|
            change_set.remove(asset_id)
          end
          pending_tessa_change_sets[name] = change_set
        end
      end

      def fetch_tessa_remote_assets(ids)
        if [*ids].empty?
          if ids.is_a?(Array)
            []
          else
            nil
          end
        elsif (blobs = ::ActiveStorage::Blob.where(key: ids).to_a).present?
          if ids.is_a?(Array)
            blobs.map { |a| Tessa::ActiveStorage::AssetWrapper.new(a) }
          else
            Tessa::ActiveStorage::AssetWrapper.new(blobs.first)
          end
        else
          Tessa::Asset.find(ids)
        end
      rescue Tessa::RequestFailed => err
        if ids.is_a?(Array)
          ids.map do |id|
            Tessa::Asset::Failure.factory(id: id, response: err.response)
          end
        else
          Tessa::Asset::Failure.factory(id: ids, response: err.response)
        end
      end

      private def reapplying_asset?(field, change_set)
        additions = change_set.changes.select(&:add?)

        return false if additions.none?
        return false if change_set.changes.size > additions.size

        additions.all? { |a| field.ids(on: self).include?(a.id) }
      end
    end

    module ClassMethods
      def asset(name, args={})
        field = tessa_fields[name] = Field.new(args.merge(name: name))
        
        multiple = args[:multiple]


        if respond_to?(:has_one_attached)
          if multiple
            has_many_attached(name)
          else
            has_one_attached(name)
          end
        end

        dynamic_extensions =
          if respond_to?(:has_one_attached)
            if multiple
              ::Tessa::DynamicExtensions::MultipleRecord.new(field)
            else
              ::Tessa::DynamicExtensions::SingleRecord.new(field)
            end
          else
            if multiple
              ::Tessa::DynamicExtensions::MultipleFormObject.new(field)
            else
              ::Tessa::DynamicExtensions::SingleFormObject.new(field)
            end
          end
        include dynamic_extensions.build(Module.new)

        # Undefine the activestorage default attribute method so it falls back
        # to our dynamic module
        remove_method "#{name}" rescue nil
        remove_method "#{name}=" rescue nil
      end

      def tessa_fields
        @tessa_fields ||= {}
      end

      def inherited(subclass)
        subclass.instance_variable_set(:@tessa_fields, @tessa_fields.dup)
      end
    end
  end
end
