module Tessa
  # Since we no longer connect to the Tessa service, fake out the Tessa connection
  # so that it always returns 503
  class FakeConnection

    [:get, :head, :put, :post, :patch, :delete].each do |method|
      define_method(method) do |*args|
        if defined?(Bugsnag)
          Bugsnag.notify("Tessa::FakeConnection##{method} invoked")
        end
        Tessa::FakeConnection::Response.new()
      end
    end

    class Response
      def success?
        false
      end

      def status
        503
      end

      def body
        '{ "error": "The Tessa connection is no longer implemented." }'
      end
    end
  end
end