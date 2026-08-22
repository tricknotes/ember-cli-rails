require "rack"

module EmberCli
  # Forwards requests made to an Ember application's mount point to its Vite
  # development server.
  #
  # Assets referenced by the Ember application itself (rather than by its
  # `index.html`) are resolved against the document's URL, so they are
  # requested from Rails. Proxying them keeps those references working the
  # same way they do when the application is served out of `dist`.
  class DevServerProxy
    ALLOWED_VERBS = %w[GET HEAD OPTIONS].freeze
    # Hop-by-hop headers, plus the `Content-Encoding` header describing a body
    # that `Net::HTTP` may have decoded already.
    SKIPPED_HEADERS = %w[
      connection
      content-encoding
      keep-alive
      proxy-authenticate
      proxy-authorization
      te
      trailer
      transfer-encoding
      upgrade
    ].freeze

    def initialize(app)
      @app = app
    end

    def call(env)
      request = Rack::Request.new(env)

      unless ALLOWED_VERBS.include?(request.request_method)
        return method_not_allowed
      end

      rack_response(proxy(request))
    end

    private

    attr_reader :app

    delegate :dev_server, to: :app

    def proxy(request)
      path = path_for(request)
      headers = { "accept-encoding" => "identity" }

      case request.request_method
      when "HEAD" then dev_server.head(path, headers)
      when "OPTIONS" then dev_server.options_request(path, headers)
      else dev_server.get(path, headers)
      end
    end

    def path_for(request)
      path = request.path_info.presence || "/"
      query = request.query_string

      if query.present?
        "#{path}?#{query}"
      else
        path
      end
    end

    def rack_response(response)
      body = response.body.to_s

      [response.code.to_i, response_headers(response, body), [body]]
    end

    def response_headers(response, body)
      headers = {}

      response.each_header do |name, value|
        unless SKIPPED_HEADERS.include?(name.downcase)
          headers[name.downcase] = value
        end
      end

      headers["content-length"] ||= body.bytesize.to_s

      headers
    end

    def method_not_allowed
      body = "Method Not Allowed"

      [
        405,
        {
          "allow" => ALLOWED_VERBS.join(", "),
          "content-type" => "text/plain",
          "content-length" => body.bytesize.to_s,
        },
        [body],
      ]
    end
  end
end
