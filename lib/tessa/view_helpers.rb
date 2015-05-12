module Tessa
  module ViewHelpers
    def tessa_image_tag(asset)
      if asset.failure?
        content_tag(:div, asset.message, class: "tessa-asset-failure")
      else
        image_tag(asset.private_url)
      end
    end
  end
end

ActionView::Base.send :include, Tessa::ViewHelpers if defined?(ActionView)
