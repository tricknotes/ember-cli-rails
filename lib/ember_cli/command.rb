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
      if paths.vite?
        vite_build
      else
        ember_build(watch: watch)
      end
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

    def build_environment
      if EmberCli.env == "production"
        "production"
      else
        "development"
      end
    end

    # The Vite-based blueprint (`ember-cli >= 6.8`)
    #
    # Builds the application the way its own `build` script does.
    # `ember build` still drives such a build today, but `ember build --help`
    # calls it a "Vestigial command in Vite-based projects" and has dropped
    # every option but `--environment`, `--suppress-sizes` and
    # `--output-path`.
    #
    # `--emptyOutDir` is needed because the output directory is outside the
    # Ember application, where Vite leaves stale files in place unless asked
    # to clear them.
    def vite_build
      line = Terrapin::CommandLine.new(paths.vite, [
        "build",
        "--mode :mode",
        "--outDir :output_path",
        "--emptyOutDir",
        ("--logLevel error" if silent?),
      ].compact.join(" "))

      line.command(
        mode: build_environment,
        output_path: paths.dist,
      )
    end

    # The classic blueprint
    #
    # Builds the application with `ember build`, which watches for changes
    # when asked. A Vite-based project has no equivalent: `ember build` there
    # refuses `--watch`, and its development server watches instead.
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
  end
end
