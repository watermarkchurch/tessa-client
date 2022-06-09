module Tessa
  class RackUploadProxy

    def call(env)
      request = Rack::Request.new(env)
      ::ActiveStorage::Current.host ||= request.base_url

      # Call in to ActiveStorage to create a DirectUpload blob
      params = env['rack.request.form_hash']

      blob = ::ActiveStorage::Blob.create_before_direct_upload!({
        filename: params["name"],
        byte_size: params["size"],
        content_type: params["mime_type"],
        checksum: params["checksum"]
      })

      env['rack.session'][:tessa_upload_asset_ids] ||= []
      env['rack.session'][:tessa_upload_asset_ids] << blob.signed_id

      response = {
        asset_id: blob.signed_id,
        upload_url: blob.service_url_for_direct_upload,
        upload_method: 'PUT', # ActiveStorage is always PUT
        upload_headers: blob.service_headers_for_direct_upload
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

