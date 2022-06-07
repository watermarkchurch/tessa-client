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
        tessa_fields[name] = Field.new(args.merge(name: name))

        # Create and insert a dynamic module into the module tree, which allows
        # us to override attribute methods and call super()
        dynamic_extensions = 
          if !multiple
            Module.new do
              class_eval <<~CODE, __FILE__, __LINE__ + 1
                def #{name}
                  # has_one_attached defines the getter using class_eval so we can't call
                  # super() here.
                  if #{name}_attachment.present?
                    return Tessa::ActiveStorage::AssetWrapper.new(#{name}_attachment)
                  end

                  # fall back to old Tessa fetch if not present
                  if field = self.class.tessa_fields["#{name}".to_sym]
                    @#{name} ||= fetch_tessa_remote_assets(field.id(on: self))
                  end
                end

                def #{name}_id
                  # Use the attachment's key
                  return #{name}_attachment.key if #{name}_attachment.present?

                  # fallback to Tessa's database column
                  super
                end

                def #{name}=(attachable)
                  # Every new upload is going to ActiveStorage
                  ActiveStorage::Attached::One.new("#{name}", self, dependent: :purge_later)
                    .attach(attachable)
                end
                CODE
            end
          else
            Module.new do
              class_eval <<~CODE, __FILE__, __LINE__ + 1
                def #{name}
                  if #{name}_attachments.present?
                    return #{name}_attachments.map do |a|
                      Tessa::ActiveStorage::AssetWrapper.new(a)
                    end
                  end

                  # fall back to old Tessa fetch if not present
                  if field = self.class.tessa_fields["#{name}".to_sym]
                    @#{name} ||= fetch_tessa_remote_assets(field.id(on: self))
                  end
                end

                def #{name}_ids
                  # Use the attachment's key
                  return #{name}_attachments.map(&:key) if #{name}_attachments.present?

                  # fallback to Tessa's database column
                  super
                end

                def #{name}=(attachables)
                  # Every new upload is going to ActiveStorage
                  ActiveStorage::Attached::Many.new("#{name}", self, dependent: :purge_later)
                    .attach(attachables)
                end
              CODE
            end
          end

        include dynamic_extensions

        # Undefine the activestorage default attribute method so it falls back
        # to our dynamic module
        remove_method "#{name}"
        remove_method "#{name}="
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
