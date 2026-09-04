require "monitor"
require "net/http"
require "socket"
require "uri"

require "ember_cli/errors"

module EmberCli
  # Manages the Vite development server backing a single Ember application.
  #
  # The server is booted lazily, and the Ember application's `index.html` and
  # assets are read from it over HTTP instead of from the `dist` directory
  # written by `ember build`.
  class DevServer
    DEFAULT_HOST = "127.0.0.1".freeze
    DEFAULT_TIMEOUT = 30
    POLL_INTERVAL = 0.1
    CONNECT_TIMEOUT = 1

    def initialize(name:, paths:, shell:, options: {})
      @name = name
      @paths = paths
      @shell = shell
      @options = options.respond_to?(:fetch) ? options : {}
      @monitor = Monitor.new
    end

    def host
      @host ||= option(:host) { DEFAULT_HOST }.to_s
    end

    def port
      @port ||= option(:port) { available_port }.to_i
    end

    def timeout
      @timeout ||= option(:timeout) { DEFAULT_TIMEOUT }.to_f
    end

    # The origin the browser loads the application's assets from. It defaults
    # to the address the development server binds to, but can be configured
    # separately for setups where the two differ — a development server bound
    # to `0.0.0.0` inside a container, reached by the browser through a
    # published port, for instance.
    def origin
      @origin ||= option(:origin) { "http://#{host}:#{port}" }.to_s.chomp("/")
    end

    # Boots the development server unless something is already listening on
    # its address, and blocks until it accepts connections.
    def start
      return true if listening?

      # Requests are served concurrently, so make sure only one of them boots
      # the development server.
      monitor.synchronize do
        return true if listening?

        shell.start_dev_server(host: host, port: port)

        wait_until_listening!
      end
    end

    def index_html
      response = get("/")

      unless response.is_a?(Net::HTTPSuccess)
        fail BuildError.new(<<~MSG)
          #{name.inspect} failed to serve an `index.html` file.

          #{origin}/ responded with #{response.code} #{response.message}:

          #{response.body}
        MSG
      end

      response.body.to_s
    end

    def get(path, headers = {})
      request(Net::HTTP::Get, path, headers)
    end

    def head(path, headers = {})
      request(Net::HTTP::Head, path, headers)
    end

    def options_request(path, headers = {})
      request(Net::HTTP::Options, path, headers)
    end

    private

    attr_reader :monitor, :name, :options, :paths, :shell

    def option(key)
      options.fetch(key) { options.fetch(key.to_s) { yield } }
    end

    def request(request_class, path, headers)
      start

      uri = URI.join("http://#{connect_host}:#{port}", path)
      # Pass `nil` as the proxy address so that a `http_proxy` environment
      # variable never routes requests for the local server through a proxy.
      Net::HTTP.start(uri.hostname, uri.port, nil, read_timeout: timeout) do |http|
        http.request(request_class.new(uri, headers))
      end
    rescue SystemCallError, IOError, Timeout::Error => error
      fail BuildError.new(<<~MSG)
        #{name.inspect} could not reach its development server at #{origin}.

        #{error.class}: #{error.message}

        Its output is written to #{paths.log}.
      MSG
    end

    # The address Rails connects to the development server on. `0.0.0.0` asks
    # the server to listen on every interface, but is not an address to
    # connect to, so requests go to the loopback interface instead.
    def connect_host
      if host == "0.0.0.0"
        "127.0.0.1"
      else
        host
      end
    end

    def listening?
      Socket.tcp(connect_host, port, connect_timeout: CONNECT_TIMEOUT, &:close)

      true
    rescue SystemCallError, IOError
      false
    end

    def wait_until_listening!
      deadline = now + timeout

      loop do
        return true if listening?

        unless shell.dev_server_running?
          fail BuildError.new(<<~MSG)
            #{name.inspect} failed to start its development server on #{origin}.

            Its output is written to #{paths.log}.
          MSG
        end

        if now >= deadline
          fail BuildError.new(<<~MSG)
            #{name.inspect} timed out after #{timeout.round} seconds waiting for
            its development server to listen on #{origin}.

            Its output is written to #{paths.log}.

            Configure a longer timeout with:

                EmberCli.configure do |config|
                  config.app #{name.to_sym.inspect}, dev_server: { timeout: 60 }
                end

          MSG
        end

        sleep POLL_INTERVAL
      end
    end

    def now
      Process.clock_gettime(Process::CLOCK_MONOTONIC)
    end

    def available_port
      server = TCPServer.new(host, 0)

      begin
        server.addr[1]
      ensure
        server.close
      end
    end
  end
end
