module Tessa
  class AssetInput < SimpleForm::Inputs::Base
		def input(wrapper_options=nil)
      template.content_tag(
        :div,
        hidden_fields_for(attribute_name),
        "class" => "tessa-upload dropzone #{"multiple" if options[:multiple]}",
        "data-dropzone-options" => (options[:dropzone] || {}).to_json,
      )
    end

    private

    def tessa_field_prefix
      @tessa_field_prefix ||= "#{lookup_model_names.reduce { |str, item| "#{str}[#{item}]" }}[#{attribute_name}]"
    end

    def hidden_fields_for(attribute_name)
      template.hidden_field_tag(
        "#{attribute_name}")
    end

    def meta_for_asset(asset)
      {
        "assetID" => asset.id,
        "name" => asset.meta[:name],
        "size" => asset.meta[:size],
        "mimeType" => asset.meta[:mime_type],
        "url" => asset.private_url,
      }.to_json
    end
  end
end
