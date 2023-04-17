require "tessa/version"

if defined?(SimpleForm)
  require "tessa/simple_form"
end

module Tessa
end

if defined?(Rails::Railtie)
  require "tessa/engine"
end
