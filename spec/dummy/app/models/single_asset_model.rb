class SingleAssetModel < ActiveRecord::Base
  include Tessa::Model

  has_one_attached :asset
end
