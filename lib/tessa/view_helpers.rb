module Tessa
  module ViewHelpers
    def tessa_image_tag(asset)
      if asset.failure?
        content_tag(:div, "Image not available")
      else
        image_tag(asset.private_url)
      end
    end
  end
end

ActionView::Base.send :include, Tessa::ViewHelpers if defined?(ActionView)
