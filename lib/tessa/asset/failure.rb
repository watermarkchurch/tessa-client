require 'delegate'

class Tessa::Asset::Failure < SimpleDelegator

  attr_reader :message

  def initialize(id:, message:)
    @message = message
    super(::Tessa::Asset.new(id: id))
  end

  def self.factory(id:, response:)
    new(id: id, message: message_from_status(response.status))
  end

  def self.message_from_status(status)
    case status
    when /5\d{2}/
      "The service is unavailable at this time."
    when /4\d{2}/
      "There was a problem retrieving the data for that asset."
    else
      "An error occurred."
    end
  end

  def failure?
    true
  end

  def meta
    {
      name: "Not Found",
      size: "0",
      mime_type: "application/octet-stream"
    }
  end
end
