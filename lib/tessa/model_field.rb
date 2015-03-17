module Tessa
  class ModelField
    include Virtus.model

    attribute :model
    attribute :name, String
    attribute :multiple, Boolean, default: false
    attribute :id_field, String

    def id_field
      super || "#{name}#{default_id_field_suffix}"
    end

    private

    def default_id_field_suffix
      if multiple
        "_ids"
      else
        "_id"
      end
    end
  end
end
