
class SingleAssetModelForm
  include ActiveModel::Model
  include Tessa::Model

  ATTRIBUTES = %w[
    title
    avatar_id
  ]

  attr_accessor :single_asset_model
  attr_accessor *ATTRIBUTES

  asset :avatar

  def self.from_single_asset_model(model, attrs = {})
    new(
      model.attributes
        .slice(*ATTRIBUTES)
        .merge(attrs)
        .merge(single_asset_model: model) 
    )
  end

end