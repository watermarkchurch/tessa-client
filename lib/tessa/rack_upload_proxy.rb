module Tessa
  class RackUploadProxy

    def call(env)
      # Call in to ActiveStorage to create a DirectUpload blob
      params = env['rack.request.form_hash']

      blob = ActiveStorage::Blob.create_before_direct_upload!({
        filename: params["name"],
        byte_size: params["size"],
        content_type: params["mime_type"]
        # Note: we don't yet calculate the MD5 client side so can't require it here
      }.reject { |k, v| v.nil? })

      response = {
        asset_id: blob.signed_id,
        upload_url: blob.service_url_for_direct_upload,
        upload_method: 'POST', # ActiveStorage is always POST
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

