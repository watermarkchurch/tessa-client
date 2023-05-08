module Tessa
  class AssetInput < SimpleForm::Inputs::Base
		def input(wrapper_options=nil)
      raise StandardError, "AssetInput with multiple: true not yet supported" if options[:multiple]

      template.content_tag(
        :div,
        hidden_fields_for(attribute_name),
        "class" => "tessa-upload dropzone #{"multiple" if options[:multiple]}",
        "data-dropzone-options" => (options[:dropzone] || {}).to_json,
        "data-input-name" => "#{object_name}[#{attribute_name}]",
        "data-direct-upload-url" => Rails.application.routes.url_helpers.rails_direct_uploads_path,
      )
    end

    private

    def hidden_fields_for(attribute_name)
      asset = object.public_send(attribute_name)
      unless asset&.key.present?
        return @builder.hidden_field("#{attribute_name}", value: nil)
      end

      @builder.hidden_field("#{attribute_name}",
        value: asset.key,
        data: {
          # These get read by the JS to populate the preview in Dropzone
          meta: meta_for_asset(asset)
        })
    end

    def meta_for_asset(asset)
      {
        # this allows us to find the hidden HTML input to remove it if we remove the asset
        "signedID" => asset.key,
        "name" => asset.filename,
        "size" => asset.byte_size,
        "mimeType" => asset.content_type,
        "url" => asset.service_url(disposition: :inline, expires_in: 1.hour),
      }.to_json
    end
  end
end
