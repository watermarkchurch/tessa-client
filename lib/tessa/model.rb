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

      private def reapplying_asset?(field, change_set)
        additions = change_set.changes.select(&:add?)

        return false if additions.none?
        return false if change_set.changes.size > additions.size

        additions.all? { |a| field.ids(on: self).include?(a.id) }
      end
    end

    module ClassMethods
      def asset(name, args={})
        # new ActiveStorage wrapper
        multiple = args[:multiple]
        if multiple
          has_many_attached(name)
        else
          has_one_attached(name)
        end

        # old Tessa fallback
        field = tessa_fields[name] = Field.new(args.merge(name: name))
        dynamic_extensions = Module.new

        # field getter - first checks attachment
        dynamic_extensions.send(:define_method, name) do
          if attachment = super.attached?
            if multiple
              return attachment.map { |a| Tessa::ActiveStorage::AssetWrapper.new(a) }
            else
              return Tessa::ActiveStorage::AssetWrapper.new(attachment)
            end
          end

          # fall back to old Tessa fetch if not present
          if instance_variable_defined?(ivar = "@#{name}")
            instance_variable_get(ivar)
          else
            instance_variable_set(
              ivar,
              fetch_tessa_remote_assets(field.id(on: self))
            )
          end
        end

        # field IDs
        if multiple
          dynamic_extensions.send(:define_method, multiple ? "#{name}_ids" : "#{name}_id") do
            # ActiveStorage takes precedence
            attachments = public_send("#{name}_attachments")
            # Use the attachment's keys
            return attachments.map(&:key) if attachments.present?

            # fallback to Tessa's database column
            super
          end
        else
          dynamic_extensions.send(:define_method, multiple ? "#{name}_ids" : "#{name}_id") do
            # ActiveStorage takes precedence
            attachment = public_send("#{name}_attachment")
            # Use the attachment's key
            return attachment.key if attachment.present?

            # fallback to Tessa's database column
            super
          end
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
