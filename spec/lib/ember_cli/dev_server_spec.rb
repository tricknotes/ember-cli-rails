require "webrick"

require "ember_cli/dev_server"

describe EmberCli::DevServer do
  describe "#origin" do
    it "defaults to the loopback interface" do
      dev_server = build_dev_server(options: { port: 4200 })

      origin = dev_server.origin

      expect(origin).to eq("http://127.0.0.1:4200")
    end

    it "honors a configured host and port" do
      dev_server = build_dev_server(options: { host: "0.0.0.0", port: 1234 })

      origin = dev_server.origin

      expect(origin).to eq("http://0.0.0.0:1234")
    end

    it "accepts string keys" do
      dev_server = build_dev_server(options: { "host" => "0.0.0.0", "port" => 1234 })

      origin = dev_server.origin

      expect(origin).to eq("http://0.0.0.0:1234")
    end
  end

  describe "#port" do
    it "allocates an available port when none is configured" do
      dev_server = build_dev_server

      port = dev_server.port

      expect(port).to be > 0
      expect(dev_server.port).to eq(port)
    end
  end

  describe "#start" do
    it "boots the development server and waits for it to listen" do
      server = null_server
      shell = FakeShell.new { |host, port| server.listen(host, port) }
      dev_server = build_dev_server(shell: shell)

      started = dev_server.start

      expect(started).to be true
      expect(shell.started_with).to eq(host: "127.0.0.1", port: dev_server.port)
    end

    it "reuses a development server that is already listening" do
      server = null_server
      server.listen("127.0.0.1", 0)
      shell = FakeShell.new
      dev_server = build_dev_server(shell: shell, options: { port: server.port })

      started = dev_server.start

      expect(started).to be true
      expect(shell.started_with).to be_nil
    end

    it "raises when the development server exits before it listens" do
      shell = FakeShell.new(running: false)
      dev_server = build_dev_server(shell: shell)

      expect { dev_server.start }.to raise_error(
        EmberCli::BuildError,
        /failed to start its development server/,
      )
    end

    it "raises when the development server does not listen in time" do
      dev_server = build_dev_server(options: { timeout: 0 })

      expect { dev_server.start }.to raise_error(
        EmberCli::BuildError,
        /timed out after 0 seconds/,
      )
    end
  end

  describe "#index_html" do
    it "returns the document served by the development server" do
      server = null_server
      server.listen("127.0.0.1", 0, body: "<html></html>")
      dev_server = build_dev_server(options: { port: server.port })

      index_html = dev_server.index_html

      expect(index_html).to eq("<html></html>")
      expect(server.requested_paths).to eq(["/"])
    end

    it "raises when the development server fails to render the document" do
      server = null_server
      server.listen("127.0.0.1", 0, status: 500, body: "Internal Server Error")
      dev_server = build_dev_server(options: { port: server.port })

      expect { dev_server.index_html }.to raise_error(
        EmberCli::BuildError,
        /responded with 500/,
      )
    end
  end

  describe "#get" do
    it "requests a path from the development server" do
      server = null_server
      server.listen("127.0.0.1", 0, body: "png-bytes")
      dev_server = build_dev_server(options: { port: server.port })

      response = dev_server.get("/assets/logo.png?v=1")

      expect(response.body).to eq("png-bytes")
      expect(server.requested_paths).to eq(["/assets/logo.png?v=1"])
    end

    it "ignores a configured HTTP proxy" do
      server = null_server
      server.listen("127.0.0.1", 0, body: "ok")
      dev_server = build_dev_server(options: { port: server.port })

      response = with_env("http_proxy" => "http://proxy.invalid:3128") do
        dev_server.get("/")
      end

      expect(response.body).to eq("ok")
    end

    it "raises when the development server is unreachable" do
      dev_server = build_dev_server(options: { port: unused_port })
      allow(dev_server).to receive(:start).and_return(true)

      expect { dev_server.get("/") }.to raise_error(
        EmberCli::BuildError,
        /could not reach its development server/,
      )
    end
  end

  # A stand-in for `EmberCli::Shell` that records how the development server
  # was booted, and optionally boots a stub HTTP server in its place.
  class FakeShell
    attr_reader :started_with

    def initialize(running: true, &on_start)
      @running = running
      @on_start = on_start
    end

    def start_dev_server(host:, port:)
      @started_with = { host: host, port: port }
      @on_start&.call(host, port)
    end

    def dev_server_running?
      @running
    end
  end

  # A stub for Vite's development server.
  class NullServer
    attr_reader :port, :requested_paths

    def initialize
      @requested_paths = []
    end

    def listen(host, port, status: 200, body: "")
      @server = WEBrick::HTTPServer.new(
        BindAddress: host,
        Port: port,
        Logger: WEBrick::Log.new(File::NULL),
        AccessLog: [],
      )
      @port = @server.config[:Port]

      @server.mount_proc "/" do |request, response|
        @requested_paths << [request.path, request.query_string].compact.
          reject(&:empty?).join("?")
        response.status = status
        response.body = body
      end

      @thread = Thread.new { @server.start }

      @port
    end

    def shutdown
      @server&.shutdown
      @thread&.join
    end
  end

  def null_server
    NullServer.new.tap { |server| servers << server }
  end

  def servers
    @servers ||= []
  end

  after { servers.each(&:shutdown) }

  def unused_port
    server = TCPServer.new("127.0.0.1", 0)

    begin
      server.addr[1]
    ensure
      server.close
    end
  end

  def with_env(variables)
    original = variables.keys.index_with { |key| ENV[key] }
    ENV.update(variables)

    yield
  ensure
    original.each { |key, value| ENV[key] = value }
  end

  def build_dev_server(shell: FakeShell.new, options: {})
    EmberCli::DevServer.new(
      name: "my-app",
      paths: double("EmberCli::PathSet", log: "log/ember-my-app.development.log"),
      shell: shell,
      options: options,
    )
  end
end
