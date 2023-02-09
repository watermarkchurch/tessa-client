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
          end

          def #{field.id_field}
            # Use the attachment's key
            return #{name}_attachment.key if #{name}_attachment.present?
          end

          def #{name}=(attachable)
            # Every new upload is going to ActiveStorage
            a = @active_storage_attached_#{name} ||=
              ::ActiveStorage::Attached::One.new("#{name}", self, dependent: :purge_later)
            
            case attachable
            when Tessa::AssetChangeSet
              attachable.changes.select(&:remove?).each { a.detach }
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
              '#{field.id_field}' => #{field.id_field},
              '_tessa_#{field.id_field}' => super['#{field.id_field}']
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
            ]
          end

          def #{field.id_field}
            [
              # Use the attachment's key
              *#{name}_attachments.map(&:key),
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
                  ids&.delete(change.id.to_i)
                  self.#{field.id_field} = ids&.any? ? ids : nil
                end
              end
              attachables.changes.select(&:add?).each do |change|
                next if #{field.id_field}.include? change.id

                a.attach(change.id)
              end
            when nil
              a.detach
              self.#{field.id_field} = nil
            else
              a.attach(*attachables)
              self.#{field.id_field} = nil
            end
          end

          def attributes
            super.merge({
              '#{field.id_field}' => #{field.id_field},
              '_tessa_#{field.id_field}' => super['#{field.id_field}']
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
          attr_accessor :#{name}
        CODE
      mod
    end
  end

  class MultipleFormObject < ::Tessa::DynamicExtensions
    def build(mod)
      mod.class_eval <<~CODE, __FILE__, __LINE__ + 1
          attr_accessor :#{name}_ids
          attr_accessor :#{name}
        CODE
      mod
    end
  end
end
