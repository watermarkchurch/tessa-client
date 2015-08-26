module Tessa
  class RackUploadProxy

    def call(env)
      params = env['rack.request.form_hash']
      upload = Tessa::Upload.create({
        name: params["name"],
        size: params["size"],
        date: params["date"],
        mime_type: params["mime_type"],
      }.reject { |k, v| v.nil? })

      env['rack.session'][:tessa_upload_asset_ids] ||= []
      env['rack.session'][:tessa_upload_asset_ids] << upload.asset_id

      response = {
        asset_id: upload.asset_id,
        upload_url: upload.upload_url,
        upload_method: upload.upload_method,
      }

      [200, {"Content-Type" => "application/json"}, [response.to_json]]
    rescue Tessa::RequestFailed
      [500, {"Content-Type" => "application/json"}, [{ "error" => "Failed to retreive upload URL" }.to_json]]
    end

    def self.call(*args)
      new.call(*args)
    end

  end
end

