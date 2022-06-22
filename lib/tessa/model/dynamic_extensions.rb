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
              attachable.changes.select(&:remove?).each { a.detatch }
              attachable.changes.select(&:add?).each do |change|
                next if #{field.id_field} == change.id

                a.attach(change.id)
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
            field = self.class.tessa_fields["#{name}".to_sym]
            tessa_ids = field.id(on: self) - #{name}_attachments.map(&:key)
            
            @#{name} ||= [
              *#{name}_attachments.map { |a| Tessa::ActiveStorage::AssetWrapper.new(a) },
              *fetch_tessa_remote_assets(tessa_ids)
            ]
          end

          def #{field.id_field}
            [
              # Use the attachment's key
              *#{name}_attachments.map(&:key),
              # include from Tessa's database column
              *super
            ]
          end

          def #{name}=(attachables)
            # Every new upload is going to ActiveStorage
            a = @active_storage_attached_#{name} ||=
              ::ActiveStorage::Attached::Many.new("#{name}", self, dependent: :purge_later)

            case attachables
            when Tessa::AssetChangeSet
              attachables.changes.select(&:remove?).each do |change|
                if existing = #{name}_attachments.find { |a| a.key == change.id }
                  existing.destroy
                else
                  ids = self.#{field.id_field}
                  ids.delete(change.id.to_i)
                  self.#{field.id_field} = ids
                end
              end
              attachables.changes.select(&:add?).each do |change|
                next if #{field.id_field}.include? change.id

                a.attach(change.id)
              end
            when nil
              a.detach
            else
              a.attach(*attachables)
            end
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
            @#{name} ||= fetch_tessa_remote_assets(#{name}_id)
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
            @#{name} ||= fetch_tessa_remote_assets(#{name}_ids)
          end
        CODE
      mod
    end
  end
end