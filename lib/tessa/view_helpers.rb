module Tessa
  module ViewHelpers
    def tessa_image_tag(asset, private: false)
      handle_asset_failure(asset) do
        image_tag(
          private ? asset.private_url : asset.public_url
        )
      end
    end

    private

    def handle_asset_failure(asset)
      if asset.failure?
        content_tag(:div, asset.message, class: "tessa-asset-failure")
      else
        yield
      end
    end
  end
end

ActionView::Base.send :include, Tessa::ViewHelpers if defined?(ActionView)
