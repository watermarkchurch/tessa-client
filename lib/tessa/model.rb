module Tessa
  module Model

    def self.included(base)
      base.send :include, InstanceMethods
      base.extend ClassMethods
    end

    module InstanceMethods

      def pending_tessa_change_sets
        @pending_tessa_change_sets ||= Hash.new { AssetChangeSet.new }
      end

    end

    module ClassMethods

      def asset(name, args={})
        field = tessa_fields[name] = ModelField.new(args.merge(name: name))

        define_method(name) {}

        define_method("#{name}=") do |value|
          change_set = field.change_set_for(value)

          # Handle removing previous items in change set
          if !field.multiple? || !value.is_a?(AssetChangeSet)
            previous_ids = [*public_send(field.id_field)]
            new_ids = change_set.scoped_changes.select(&:add?).map(&:id)
            (previous_ids - new_ids).each do |id|
              change_set.remove(id)
            end
          end

          pending_tessa_change_sets[name] += change_set

          field.set(value, on: self)
        end
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
