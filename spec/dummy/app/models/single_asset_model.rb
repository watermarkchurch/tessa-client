class SingleAssetModel < ActiveRecord::Base
  include Tessa::Model

  asset :map
end
