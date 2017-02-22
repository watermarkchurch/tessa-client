class Tessa::Upload::UploadsFile
  attr_reader :upload, :connection

  def initialize(upload:, connection: self.class.connection_factory)
    @upload = upload
    @connection = connection
  end

  def call(file)
    params = { file: Faraday::UploadIO.new(file, "application/octet-stream") }
    connection
      .public_send(upload.upload_method, upload.upload_url, params)
      .success?
  end

  def self.connection_factory
    Faraday.new do |conn|
      conn.request :multipart
      conn.request :url_encoded
      conn.adapter Faraday.default_adapter
    end
  end
end
