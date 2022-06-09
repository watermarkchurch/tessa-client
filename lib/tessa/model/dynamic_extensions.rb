require 'forwardable'

class Tessa::DynamicExtensions
  extend Forwardable

  attr_reader :field

  def name
    field.name
  end

  def initialize(field)
    @field = field
  end

  class SingleRecord < ::Tessa::DynamicExtensions
    def build(mod)
      mod.class_eval <<~CODE, __FILE__, __LINE__ + 1
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

          def #{field.id_field}
            # Use the attachment's key
            return #{name}_attachment.key if #{name}_attachment.present?

            # fallback to Tessa's database column
            super
          end

          def #{name}=(attachable)
            # Every new upload is going to ActiveStorage
            a = @active_storage_attached_#{name} ||=
              ::ActiveStorage::Attached::One.new("#{name}", self, dependent: :purge_later)
            
            case attachable
            when Tessa::AssetChangeSet
              attachable.changes.each do |change|
                a.attach(change.id) if change.add?
                a.detach if change.remove?
              end
            when nil
              a.detach
            else
              a.attach(attachable)
            end

            # overwrite the tessa ID in the database
            self.#{field.id_field} = nil
          end

          def attributes
            super.merge({
              '#{field.id_field}' => #{field.id_field}
            })
          end
        CODE
      mod
    end
  end

  class MultipleRecord < ::Tessa::DynamicExtensions
    def build(mod)
      mod.class_eval <<~CODE, __FILE__, __LINE__ + 1
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

          def #{field.id_field}
            # Use the attachment's key
            return #{name}_attachments.map(&:key) if #{name}_attachments.present?

            # fallback to Tessa's database column
            super
          end

          def #{name}=(attachables)
            # Every new upload is going to ActiveStorage
            a = @active_storage_attached_#{name} ||=
              ::ActiveStorage::Attached::Many.new("#{name}", self, dependent: :purge_later)

            case attachables
            when Tessa::AssetChangeSet
              attachables.changes.each do |change|
                a.attach(change.id) if change.add?
                raise 'TODO' if change.remove?
              end
            when nil
              a.detach
            else
              a.attach(*attachables)
            end

            # overwrite the tessa ID in the database
            self.#{field.id_field} = nil
          end

          def attributes
            super.merge({
              '#{field.id_field}' => #{field.id_field}
            })
          end
        CODE
      mod
    end
  end

  class SingleFormObject < ::Tessa::DynamicExtensions
    def build(mod)
      mod.class_eval <<~CODE, __FILE__, __LINE__ + 1
          attr_accessor :#{name}_id
          attr_writer :#{name}
          def #{name}
            @#{name} ||=
              if #{name}_id
                ::ActiveStorage::Blob.find_by(key: #{name}_id) ||
                  Tessa::Asset.find(#{name}_id)
              end
          end
        CODE
      mod
    end
  end

  class MultipleFormObject < ::Tessa::DynamicExtensions
    def build(mod)
      mod.class_eval <<~CODE, __FILE__, __LINE__ + 1
          attr_accessor :#{name}_ids
          attr_writer :#{name}
          def #{name}
            @#{name} ||=
              if #{name}_ids.present?
                ::ActiveStorage::Blob.where(key: #{name}_ids).to_a ||
                  Tessa::Asset.find(*#{name}_ids)
              end
          end
        CODE
      mod
    end
  end
end