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
      if asset&.is_a?(String)
        # This happens if the controller rejects the change with errors and re-renders the form.
        # In this case our field value would be the signed upload ID.
        return hidden_fileds_for_signed_id(attribute_name, asset)
      end

      if asset&.key.present?
        @builder.hidden_field("#{attribute_name}", {
          value: asset.key,
          data: {
            meta: meta_for_blob(asset).merge({
              # this allows us to find the hidden HTML input to remove it if we remove the asset
              "signedID" => blob.key,
            })
          }
        })
      end

      return @builder.hidden_field("#{attribute_name}", value: nil)
    end

    def hidden_fileds_for_signed_id(attribute_name, signed_id)
      if blob = ActiveStorage::Blob.find_signed(signed_id)
        return @builder.hidden_field("#{attribute_name}", {
          value: signed_id,
          data: {
            meta: meta_for_blob(blob).merge({
              'signedID' => signed_id
            })
          }
        })
      end

      # The form post sent some other string which was not a signed ID
      return @builder.hidden_field("#{attribute_name}", value: nil)
    end

    # These get read by the JS to populate the preview in Dropzone
    def meta_for_blob(blob)
      {
        "name" => blob.filename,
        "size" => blob.byte_size,
        "mimeType" => blob.content_type,
        "url" => blob.service_url(disposition: :inline, expires_in: 1.hour),
      }.as_json
    end
  end
end
