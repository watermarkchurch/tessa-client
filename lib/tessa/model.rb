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

        define_method(name) do
          if instance_variable_defined?(ivar = "@#{name}")
            instance_variable_get(ivar)
          else
            instance_variable_set(
              ivar,
              Tessa::Asset.find(public_send(field.id_field))
            )
          end
        end

        define_method("#{name}=") do |value|
          change_set = field.change_set_for(value)

          if !(field.multiple? && value.is_a?(AssetChangeSet))
            new_ids = change_set.scoped_changes.select(&:add?).map(&:id)
            change_set += field.difference_change_set(new_ids, on: self)
          end

          pending_tessa_change_sets[name] += change_set

          field.apply(change_set, on: self)
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
