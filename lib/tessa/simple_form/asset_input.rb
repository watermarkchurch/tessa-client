module Tessa
  class AssetInput < SimpleForm::Inputs::Base
		def input(wrapper_options=nil)
      merged_input_options = merge_wrapper_options(input_html_options, wrapper_options)
      field = object.class.tessa_fields[attribute_name]

      template.content_tag(
        :div,
        hidden_fields_for(object.public_send(attribute_name)),
        "class" => "tessa-upload dropzone #{"multiple" if field.multiple?}",
        "data-asset-field-prefix" => tessa_field_prefix,
        "data-dropzone-options" => (options[:dropzone] || {}).to_json,
        "data-tessa-params" => (options[:tessa_params] || {}).to_json,
      )
    end

    private

    def tessa_field_prefix
      @tessa_field_prefix ||= "#{lookup_model_names.reduce { |str, item| "#{str}[#{item}]" }}[#{attribute_name}]"
    end

    def hidden_fields_for(assets)
      [*assets].collect do |asset|
        template.hidden_field_tag(
          "#{tessa_field_prefix}[#{asset.id}][action]",
          "add",
          "data-meta" => meta_for_asset(asset),
          "id" => "tessa_asset_action_#{asset.id}"
        )
      end.join.html_safe
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