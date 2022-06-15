class MultipleAssetModel < ActiveRecord::Base
  # Necessary to have an array of integers in sqlite
  serialize :another_place, Array

  include Tessa::Model

  asset :multiple_field, multiple: true, id_field: "another_place"
end
