class CreateSingleAssetModels < ActiveRecord::Migration[5.2]
  def change
    create_table :single_asset_models do |t|
      t.string :title
      t.integer :avatar_id

      t.timestamps
    end
  end
end
