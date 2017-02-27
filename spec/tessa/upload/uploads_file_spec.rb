require 'spec_helper'

RSpec.describe Tessa::Upload::UploadsFile do
  describe "#initialize" do
    it "requires an upload and sets it to attribute" do
      expect { described_class.new }.to raise_error(ArgumentError)
      obj = described_class.new(upload: :upload)
      expect(obj.upload).to eq(:upload)
    end

    it "optionally takes a connection" do
      obj = described_class.new(upload: :upload, connection: :conn)
      expect(obj.connection).to eq(:conn)
    end

    it "defaults connection to empty Faraday connection" do
      expect(described_class).to receive(:connection_factory).and_return(:foo)
      obj = described_class.new(upload: :upload)
      expect(obj.connection).to eq(:foo)
    end
  end

  describe "#call" do
    let(:upload) {
      instance_double(
        Tessa::Upload,
        upload_url: "http://upload/path?arg=1",
        upload_method: "post"
      )
    }
    let(:connection) {
      Faraday.new { |f| f.adapter :test, stubs }
    }
    subject(:task) { described_class.new(upload: upload, connection: connection) }

    context "uploads file successfully" do
      let(:stubs) {
        Faraday::Adapter::Test::Stubs.new do |stub|
          stub.post("http://upload/path?arg=1") { |env|
            [200, {}, '']
          }
        end
      }

      it "calls the upload_url with upload_method HTTP method" do
        file = Tempfile.new("test")
        file.write "hello there"
        file.close
        expect(connection).to receive(:post).with("http://upload/path?arg=1", "hello there").and_call_original
        expect(task.call(file.path)).to be_truthy
      end
    end

    context "uploads file successfully" do
      let(:stubs) {
        Faraday::Adapter::Test::Stubs.new do |stub|
          stub.post("http://upload/path?arg=1") { |env|
            [500, {}, '']
          }
        end
      }

      it "calls the upload_url with upload_method HTTP method" do
        file = Tempfile.new("test")
        file.write "hello there"
        file.close
        expect(connection).to receive(:post).with("http://upload/path?arg=1", "hello there").and_call_original
        expect(task.call(file.path)).to be_falsey
      end
    end
  end

  describe ".connection_factory" do
    it "returns a new Faraday::Connection with the default adapter" do
      obj = described_class.connection_factory
      expect(obj).to be_a(Faraday::Connection)
      expect(obj.builder.handlers)
        .to eq([Faraday::Adapter::NetHttp])
    end
  end

end
