require 'spec_helper'

RSpec.describe Tessa::Upload do
  describe "#initialize" do
    context "with all arguments" do
      subject(:upload) { described_class.new(args) }
      let(:args) {
        {
          success_url: "http://example.com/success",
          cancel_url: "http://example.com/cancel",
          upload_url: "http://example.com/upload",
          upload_method: "put",
        }
      }

      it "sets success_url to attribute"
      it "sets cancel_url to attribute"
      it "sets upload_url to attribute"
      it "sets upload_method to attribute"
    end
  end

  describe "::create" do
    it "calls post('/uploads') on connection"
    it "calls new with the response"

    describe ":strategy param" do
      it "defaults to config.default_strategy"
      it "overrides with :strategy argument"
    end

    it "sets :name param from argument"
    it "sets :size param from argument"
    it "sets :mime_type param from argument"
  end

end
