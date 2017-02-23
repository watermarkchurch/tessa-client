class Tessa::Upload::UploadsFile
  attr_reader :upload, :connection

  def initialize(upload:, connection: self.class.connection_factory)
    @upload = upload
    @connection = connection
  end

  def call(file)
    connection
      .public_send(upload.upload_method, upload.upload_url, File.read(file))
      .success?
  end

  def self.connection_factory
    Faraday.new do |conn|
      conn.adapter Faraday.default_adapter
    end
  end
end
