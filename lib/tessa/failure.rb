require 'delegate'

module Tessa
  class Failure < SimpleDelegator

    attr_reader :message

    def self.factory(id:, error:)
      message = case error.response.status
      when /5\d{2}/
        "The service is unavailable at this time."
      when /4\d{2}/
        "There was a problem retrieving the data for that asset."
      else
        "An error occurred."
      end

      new(id, message)
    end

    def initialize(id, message)
      @message = message
      super(Asset.new(id: id))
    end

    def failure?
      true
    end
  end
end
