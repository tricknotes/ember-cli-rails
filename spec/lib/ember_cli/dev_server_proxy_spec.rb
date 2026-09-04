require "ember_cli/dev_server_proxy"

describe EmberCli::DevServerProxy do
  describe "#call" do
    it "forwards the request path and query string to the development server" do
      dev_server = build_dev_server
      proxy = EmberCli::DevServerProxy.new(double(dev_server: dev_server))

      proxy.call(rack_env("/assets/logo.png", query: "v=1"))

      expect(dev_server).to have_received(:get).
        with("/assets/logo.png?v=1", "accept-encoding" => "identity")
    end

    it "requests the root when mounted without a nested path" do
      dev_server = build_dev_server
      proxy = EmberCli::DevServerProxy.new(double(dev_server: dev_server))

      proxy.call(rack_env(""))

      expect(dev_server).to have_received(:get).
        with("/", "accept-encoding" => "identity")
    end

    it "returns the development server's status, headers, and body" do
      dev_server = build_dev_server(
        body: "png-bytes",
        headers: { "content-type" => "image/png" },
      )
      proxy = EmberCli::DevServerProxy.new(double(dev_server: dev_server))

      status, headers, body = proxy.call(rack_env("/assets/logo.png"))

      expect(status).to eq(200)
      expect(headers).to include(
        "content-type" => "image/png",
        "content-length" => "9",
      )
      expect(body).to eq(["png-bytes"])
    end

    it "returns the development server's error responses" do
      dev_server = build_dev_server(code: "404", body: "Not Found")
      proxy = EmberCli::DevServerProxy.new(double(dev_server: dev_server))

      status, _, body = proxy.call(rack_env("/missing.png"))

      expect(status).to eq(404)
      expect(body).to eq(["Not Found"])
    end

    it "drops hop-by-hop headers" do
      dev_server = build_dev_server(headers: {
        "content-type" => "text/css",
        "connection" => "keep-alive",
        "transfer-encoding" => "chunked",
        "content-encoding" => "gzip",
      })
      proxy = EmberCli::DevServerProxy.new(double(dev_server: dev_server))

      _, headers, _ = proxy.call(rack_env("/app.css"))

      expect(headers).to include("content-type" => "text/css")
      expect(headers.keys).
        not_to include("connection", "transfer-encoding", "content-encoding")
    end

    it "keeps the development server's `content-length` when it sends one" do
      dev_server = build_dev_server(
        body: "",
        headers: { "content-length" => "23905" },
      )
      proxy = EmberCli::DevServerProxy.new(double(dev_server: dev_server))

      _, headers, _ = proxy.call(rack_env("/assets/logo.png", method: "HEAD"))

      expect(headers).to include("content-length" => "23905")
    end

    it "sends `HEAD` and `OPTIONS` requests with their own verbs" do
      dev_server = build_dev_server
      proxy = EmberCli::DevServerProxy.new(double(dev_server: dev_server))

      proxy.call(rack_env("/app.css", method: "HEAD"))
      proxy.call(rack_env("/app.css", method: "OPTIONS"))

      expect(dev_server).to have_received(:head).once
      expect(dev_server).to have_received(:options_request).once
      expect(dev_server).not_to have_received(:get)
    end

    it "responds with `405 Method Not Allowed` to other verbs" do
      dev_server = build_dev_server
      proxy = EmberCli::DevServerProxy.new(double(dev_server: dev_server))

      status, headers, _ = proxy.call(rack_env("/app.css", method: "POST"))

      expect(status).to eq(405)
      expect(headers).to include("allow" => "GET, HEAD, OPTIONS")
      expect(dev_server).not_to have_received(:get)
    end
  end

  def build_dev_server(code: "200", body: "", headers: {})
    response = build_response(code: code, body: body, headers: headers)

    double(
      "EmberCli::DevServer",
      get: response,
      head: response,
      options_request: response,
    )
  end

  def build_response(code:, body:, headers:)
    double("Net::HTTPResponse", code: code, body: body).tap do |response|
      allow(response).to receive(:each_header) do |&block|
        headers.each { |name, value| block.call(name, value) }
      end
    end
  end

  def rack_env(path, method: "GET", query: "")
    Rack::MockRequest.env_for("http://example.com/mounted#{path}").merge(
      "REQUEST_METHOD" => method,
      "SCRIPT_NAME" => "/mounted",
      "PATH_INFO" => path,
      "QUERY_STRING" => query,
    )
  end
end
