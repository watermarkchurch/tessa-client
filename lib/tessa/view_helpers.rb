module Tessa
  module ViewHelpers
    def tessa_image_tag(asset)
      handle_failure(asset) do
        image_tag(asset.private_url)
      end
    end

    private

    def handle_failure(asset)
      if asset.failure?
        content_tag(:div, asset.message, class: "tessa-asset-failure")
      else
        yield
      end
    end
  end
end

ActionView::Base.send :include, Tessa::ViewHelpers if defined?(ActionView)
