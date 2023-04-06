require "tessa/version"

require "tessa/rack_upload_proxy"
require "tessa/view_helpers"


if defined?(SimpleForm)
  require "tessa/simple_form"
end

module Tessa
end

if defined?(Rails::Railtie)
  require "tessa/engine"
end
