require "html_page/renderer"
require "ember_cli/path_set"
require "ember_cli/shell"
require "ember_cli/build_monitor"
require "ember_cli/deploy/dev_server"
require "ember_cli/deploy/file"
require "ember_cli/dev_server"

module EmberCli
  class App
    attr_reader :name, :options, :paths

    def initialize(name, **options)
      @name = name.to_s
      @options = options
      @paths = PathSet.new(
        app: self,
        environment: Rails.env,
        rails_root: Rails.root,
        ember_cli_root: EmberCli.root,
      )
      @shell = Shell.new(
        paths: @paths,
        env: env_hash,
        options: options,
      )
      @build = BuildMonitor.new(name, @paths)
    end

    def root_path
      paths.root
    end

    def dist_path
      paths.dist
    end

    def cached_directories
      paths.cached_directories
    end

    def compile
      @compiled ||= begin
        prepare
        exit_status = @shell.compile
        @build.check!

        exit_status.success?
      end
    end

    def build
      unless EmberCli.skip?
        if dev_server?
          # Vite's own development server rebuilds and hot-reloads the
          # application, so there is nothing to build ahead of time.
          dev_server.start
        else
          build_for_environment

          @build.wait!
        end
      end
    end

    def index_html(head:, body:, mount_point: nil)
      html = HtmlPage::Renderer.new(
        head: head,
        body: body,
        content: remap_to_mount_point(deploy.index_html, mount_point),
      )

      html.render
    end

    def install_dependencies
      @shell.install
    end

    def test
      prepare

      @shell.test.success?
    end

    def check_for_errors!
      @build.check!
    end

    def mountable?
      deploy.mountable?
    end

    def yarn_enabled?
      options.fetch(:yarn, false)
    end

    def bower?
      paths.bower_json.exist?
    end

    def to_rack
      deploy.to_rack
    end

    def dev_server
      @dev_server ||= DevServer.new(
        name: name,
        paths: paths,
        shell: @shell,
        options: dev_server_options,
      )
    end

    # Whether this application is served by Vite's development server rather
    # than out of the directory `ember build` writes to.
    def dev_server?
      strategy = deploy_strategy

      strategy.is_a?(Class) &&
        strategy.ancestors.include?(EmberCli::Deploy::DevServer)
    end

    private

    def development?
      env.to_s == "development"
    end

    def test?
      env.to_s == "test"
    end

    # The `index.html` of a Vite build refers to its assets with root-relative
    # URLs. When the application is mounted somewhere other than `/`, remap
    # them onto the mount point, where `mount_ember_assets` serves them.
    # References that already carry the mount point — a `rootURL` configured
    # to match it — are left alone.
    def remap_to_mount_point(html, mount_point)
      prefix = mount_point.to_s.chomp("/")

      if prefix.empty? || !paths.vite?
        return html
      end

      already_mounted = Regexp.escape(prefix.delete_prefix("/"))

      html.gsub(%r{(\s)(src|href)=(["'])/(?!/)(?!#{already_mounted}/)}i) do
        "#{$1}#{$2}=#{$3}#{prefix}/"
      end
    end

    def deploy
      deploy_strategy.new(self)
    end

    def deploy_strategy
      strategy = options.fetch(:deploy, {})

      if strategy.respond_to?(:fetch)
        strategy.fetch(rails_env) { default_deploy_strategy }
      else
        strategy
      end
    end

    def default_deploy_strategy
      if development? && paths.vite? && dev_server_enabled?
        EmberCli::Deploy::DevServer
      else
        EmberCli::Deploy::File
      end
    end

    def dev_server_option
      options.fetch(:dev_server, true)
    end

    def dev_server_enabled?
      dev_server_option != false
    end

    def dev_server_options
      option = dev_server_option

      if option.respond_to?(:fetch)
        option
      else
        {}
      end
    end

    def rails_env
      Rails.env.to_s.to_sym
    end

    def env
      EmberCli.env
    end

    def build_for_environment
      if development?
        if paths.vite?
          # The Vite-based blueprint (`ember-cli >= 6.8`) has no
          # `ember-cli-rails-addon` to manage the build lock, so build
          # synchronously instead of watching for changes.
          compile
        else
          build_and_watch
        end
      elsif test?
        compile
      end
    end

    def build_and_watch
      prepare
      @shell.build_and_watch
    end

    def prepare
      @prepared ||= begin
        @build.reset
        true
      end
    end

    def excluded_ember_deps
      Array.wrap(options[:exclude_ember_deps]).join("?")
    end

    def env_hash
      ENV.to_h.tap do |vars|
        vars["RAILS_ENV"] = Rails.env
        vars["EXCLUDE_EMBER_ASSETS"] = excluded_ember_deps
        vars["BUNDLE_GEMFILE"] = paths.gemfile.to_s if paths.gemfile.exist?
      end
    end
  end
end
