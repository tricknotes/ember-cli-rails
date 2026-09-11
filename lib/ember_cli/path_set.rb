require "ember_cli/helpers"

module EmberCli
  class PathSet
    PACKAGE_MANAGERS = %i[npm yarn pnpm].freeze

    # Every name Vite resolves its configuration file from. An application
    # that keeps its configuration under any of them is Vite-based.
    VITE_CONFIG_FILES = %w[
      vite.config.js
      vite.config.mjs
      vite.config.cjs
      vite.config.ts
      vite.config.mts
      vite.config.cts
    ].freeze

    # npm ships with NodeJS, so it has no installation instructions of its own
    # to point at when its executable is missing.
    INSTALL_INSTRUCTIONS = {
      yarn: "https://yarnpkg.com/lang/en/docs/install/",
      pnpm: "https://pnpm.io/installation",
    }.freeze

    def initialize(app:, rails_root:, ember_cli_root:, environment:)
      @app = app
      @rails_root = rails_root
      @environment = environment
      @ember_cli_root = ember_cli_root
    end

    def root
      path = app_options.fetch(:path){ default_root }
      pathname = Pathname.new(path)
      if pathname.absolute?
        pathname
      else
        rails_root.join(path)
      end
    end

    def tmp
      @tmp ||= root.join("tmp").tap(&:mkpath)
    end

    def log
      @log ||= logs.join("ember-#{app_name}.#{environment}.log")
    end

    def dist
      @dist ||= ember_cli_root.join("apps", app_name).tap(&:mkpath)
    end

    def gemfile
      @gemfile ||= root.join("Gemfile")
    end

    def package_json
      @package_json ||= root.join("package.json")
    end

    def bower_json
      root.join("bower.json")
    end

    # Apps generated with the Vite-based blueprint (`ember-cli >= 6.8`)
    # ship a Vite config file at their root.
    def vite?
      VITE_CONFIG_FILES.any? { |config| root.join(config).exist? }
    end

    def ember
      @ember ||= begin
        root.join("node_modules", "ember-cli", "bin", "ember").tap do |path|
          unless path.executable?
            fail DependencyError.new <<-MSG.strip_heredoc
              No `ember-cli` executable found for `#{app_name}`.

              Install it:

                  $ cd #{root}
                  $ #{package_manager} install

            MSG
          end
        end
      end
    end

    def vite
      @vite ||= begin
        root.join("node_modules", ".bin", "vite").tap do |path|
          unless path.executable?
            fail DependencyError.new <<-MSG.strip_heredoc
              No `vite` executable found for `#{app_name}`.

              Install it:

                  $ cd #{root}
                  $ #{package_manager} install

            MSG
          end
        end
      end
    end

    def lockfile
      @lockfile ||= tmp.join("build.lock")
    end

    def build_error_file
      @build_error_file ||= tmp.join("error.txt")
    end

    def bower
      @bower ||= begin
        path_for_executable("bower").tap do |bower_path|
          if bower_json.exist? && (bower_path.blank? || !bower_path.executable?)
            fail DependencyError.new <<-MSG.strip_heredoc
                Bower is required by EmberCLI

                Install it with:

                    $ npm install -g bower

            MSG
          end
        end
      end
    end

    def bower_components
      @bower_components ||= root.join("bower_components")
    end

    def npm
      @npm ||= path_for_executable("npm")
    end

    def yarn
      if yarn?
        @yarn ||= package_manager_executable(:yarn)
      end
    end

    def pnpm
      if pnpm?
        @pnpm ||= package_manager_executable(:pnpm)
      end
    end

    def node_modules
      @node_modules ||= root.join("node_modules")
    end

    # The package manager that installs the application's NodeJS
    # dependencies: the one the `package_manager` option names, else the one
    # whose executable a `yarn_path` or `pnpm_path` option names, else npm.
    # The deprecated `yarn: true` still selects yarn, with a warning.
    def package_manager
      @package_manager ||= begin
        requested = app_options[:package_manager]

        if requested.present?
          requested.to_s.to_sym.tap do |name|
            unless PACKAGE_MANAGERS.include?(name)
              fail ArgumentError,
                "Unsupported package manager #{requested.inspect} for " \
                "`#{app_name}`; use one of #{PACKAGE_MANAGERS.inspect}"
            end
          end
        elsif app_options[:yarn].present?
          EmberCli.deprecator.warn(
            "The `yarn` option of the `#{app_name}` Ember application is " \
            "deprecated; configure it with `package_manager: :yarn` instead",
          )

          :yarn
        elsif app_options[:yarn_path].present?
          :yarn
        elsif app_options[:pnpm_path].present?
          :pnpm
        else
          :npm
        end
      end
    end

    def yarn?
      package_manager == :yarn
    end

    def pnpm?
      package_manager == :pnpm
    end

    def tee
      @tee ||= path_for_executable("tee")
    end

    def bundler
      @bundler ||= path_for_executable("bundler")
    end

    def cached_directories
      [
        node_modules,
        (bower_components if bower_json.exist?),
      ].compact
    end

    private

    attr_reader :app, :ember_cli_root, :environment, :rails_root

    def path_for_executable(command)
      path = app_options.fetch("#{command}_path") { which(command) }

      if path.present?
        Pathname.new(path)
      end
    end

    def package_manager_executable(name)
      path_for_executable(name.to_s).tap do |path|
        unless File.executable?(path.to_s)
          fail DependencyError.new(<<-MSG.strip_heredoc)
              EmberCLI has been configured to install NodeJS dependencies with #{name}, but the #{name} executable is unavailable.

              Install it by following the instructions at #{INSTALL_INSTRUCTIONS.fetch(name)}

          MSG
        end
      end
    end

    def app_name
      app.name
    end

    def app_options
      app.options.with_indifferent_access
    end

    def which(executable)
      Helpers.which(executable)
    end

    def logs
      rails_root.join("log").tap(&:mkpath)
    end

    def default_root
      rails_root.join(app_name)
    end
  end
end
