require 'spec_helper'

RSpec.describe Tessa::Config do
  subject(:config) { Tessa::Config.new }

  describe "#backends" do
    it "defaults to empty hash" do
      expect(config.backends).to eq({})
    end
  end

  describe "default_backend" do
    it "sets default_backend with given value" do
      backend = :s3
      config.backends = { backend => :value }
      config.default_backend = backend
      expect(config.default_backend).to eq(:value)
    end
  end
end
