module Tessa
  module ControllerHelpers

    def params_for_asset(changes)
      Tessa::AssetChangeSet.new(
        changes: changes,
        scoped_ids: tessa_upload_asset_ids,
      )
    end

    def tessa_upload_asset_ids
      session[:tessa_upload_asset_ids] ||= []
    end

  end
end
