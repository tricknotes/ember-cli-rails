require "ember_cli/helpers"

module EmberCli
  class PathSet
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

    def bower_json
      root.join("bower.json")
    end

    # Apps generated with the Vite-based blueprint (`ember-cli >= 6.8`)
    # ship a Vite config file at their root.
    def vite?
      %w[vite.config.mjs vite.config.js vite.config.ts].
        any? { |config| root.join(config).exist? }
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
        @yarn ||= path_for_executable("yarn").tap do |yarn|
          unless File.executable?(yarn.to_s)
            fail DependencyError.new(<<-MSG.strip_heredoc)
                EmberCLI has been configured to install NodeJS dependencies with Yarn, but the Yarn executable is unavailable.

                Install it by following the instructions at https://yarnpkg.com/lang/en/docs/install/

            MSG
          end
        end
      end
    end

    def node_modules
      @node_modules ||= root.join("node_modules")
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

    def package_manager
      if yarn?
        "yarn"
      else
        "npm"
      end
    end

    def yarn?
      app_options[:yarn] || app_options[:yarn_path]
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
