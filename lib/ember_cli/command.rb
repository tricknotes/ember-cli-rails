require "terrapin"

module EmberCli
  class Command
    def initialize(paths:, options: {})
      @paths = paths
      @options = options
    end

    def test
      line = Terrapin::CommandLine.new(paths.ember, "test --environment test")

      line.command
    end

    def build(watch: false)
      ember_build(watch: watch)
    end

    # Boots Vite's development server for an application generated with the
    # Vite-based blueprint (`ember-cli >= 6.8`). This is what the blueprint's
    # own `npm start` script runs.
    def dev_server(host:, port:)
      line = Terrapin::CommandLine.new(paths.vite, [
        "--host :host",
        "--port :port",
        "--strictPort",
        "--clearScreen false",
      ].join(" "))

      line.command(host: host.to_s, port: port.to_s)
    end

    private

    attr_reader :options, :paths

    def process_watcher
      options.fetch(:watcher) { EmberCli.configuration.watcher }
    end

    def silent?
      options.fetch(:silent) { false }
    end

    def ember_build(watch: false)
      line = Terrapin::CommandLine.new(paths.ember, [
        "build",
        ("--watch" if watch),
        ("--watcher :watcher" if process_watcher),
        ("--silent" if silent?),
        "--environment :environment",
        "--output-path :output_path",
      ].compact.join(" "))

      line.command(
        environment: build_environment,
        output_path: paths.dist,
        watcher: process_watcher,
      )
    end

    def build_environment
      if EmberCli.env == "production"
        "production"
      else
        "development"
      end
    end
  end
end
