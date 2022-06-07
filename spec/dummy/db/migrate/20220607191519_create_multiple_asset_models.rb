class CreateMultipleAssetModels < ActiveRecord::Migration[5.2]
  def change
    create_table :multiple_asset_models do |t|
      t.string :title
      t.string :another_place, default: '[]'

      t.timestamps
    end
  end
end
