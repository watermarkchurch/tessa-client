require "tessa/version"

require "tessa/rack_upload_proxy"

if defined?(SimpleForm)
  require "tessa/simple_form"
end

module Tessa
end

if defined?(Rails::Railtie)
  require "tessa/engine"
end
