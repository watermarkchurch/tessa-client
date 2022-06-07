class SingleAssetModel < ActiveRecord::Base
  include Tessa::Model

  asset :avatar
end
