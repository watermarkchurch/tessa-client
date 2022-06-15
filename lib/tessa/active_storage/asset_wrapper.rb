module Tessa::ActiveStorage
  class AssetWrapper < SimpleDelegator
    def public_url
      Rails.application.routes.url_helpers.
        rails_blob_url(__getobj__, disposition: :inline)
    end

    def private_url(expires_in: 1.day)
      service_url(disposition: :inline, expires_in: expires_in)
    end

    def private_download_url(expires_in: 1.day)
      service_url(disposition: 'attachment', expires_in: expires_in)
    end

    def meta
      {}
    end

    def failure?
      false
    end
  end
end