require 'tessa/model/field'

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
        @pending_tessa_change_sets.delete_if do |_, change_set|
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
          [] if ids.is_a?(Array)
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

    end

    module ClassMethods

      def asset(name, args={})
        field = tessa_fields[name] = Field.new(args.merge(name: name))

        dynamic_extensions = Module.new

        dynamic_extensions.send(:define_method, name) do
          if instance_variable_defined?(ivar = "@#{name}")
            instance_variable_get(ivar)
          else
            instance_variable_set(
              ivar,
              fetch_tessa_remote_assets(field.id(on: self))
            )
          end
        end

        dynamic_extensions.send(:define_method, "#{name}=") do |value|
          change_set = field.change_set_for(value)

          if !(field.multiple? && value.is_a?(AssetChangeSet))
            new_ids = change_set.scoped_changes.select(&:add?).map(&:id)
            change_set += field.difference_change_set(new_ids, on: self)
          end

          pending_tessa_change_sets[name] += change_set

          field.apply(change_set, on: self)
        end

        include dynamic_extensions
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
