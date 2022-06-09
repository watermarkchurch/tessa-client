module Tessa::ActiveStorage
  class AssetWrapper < SimpleDelegator
    def public_url
      Rails.application.routes.url_helpers.
        rails_blob_url(__getobj__, disposition: :inline)
    end

    def private_url
      service_url(disposition: :inline)
    end

    def private_download_url
      service_url(disposition: 'attachment')
    end

    def meta
      {}
    end

    def failure?
      false
    end
  end
end