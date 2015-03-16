module Tessa
  module ResponseFactory

    def new_from_response(response)
      raise RequestFailed.new("Tessa responded with #{response.status}", response) unless response.success?
      case json = JSON.parse(response.body)
      when Array
        json.map { |record| new record }
      when Hash
        new json
      end
    end

  end
end
