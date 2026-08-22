require "ember_cli/command"
require "ember_cli/runner"

module EmberCli
  class Shell
    def initialize(paths:, env: {}, options: {})
      @paths = paths
      @env = env
      @ember = Command.new(
        paths: paths,
        options: options,
      )
      @on_exit ||= at_exit { stop }
    end

    def compile
      run! ember.build
    end

    def build_and_watch
      unless running?
        lock_buildfile
        self.pid = spawn(
          ember.build(watch: true),
          err: paths.build_error_file.to_s,
        )
        detach
      end
    end

    def start_dev_server(host:, port:)
      unless dev_server_running?
        # Run the development server in its own process group so that the
        # whole tree can be signaled when Rails exits.
        self.dev_server_pid = spawn(
          ember.dev_server(host: host, port: port),
          out: [paths.log.to_s, "a"],
          err: [:child, :out],
          pgroup: true,
        )
        Process.detach(dev_server_pid)
      end

      dev_server_pid
    end

    def dev_server_running?
      process_running?(dev_server_pid)
    end

    def stop
      if pid.present?
        signal(pid)
        self.pid = nil
      end

      if dev_server_pid.present?
        signal(-dev_server_pid)
        self.dev_server_pid = nil
      end
    end

    def install
      if paths.gemfile.exist?
        run! "#{paths.bundler} install"
      end

      if invalid_ember_dependencies?
        clean_ember_dependencies!
      end

      if paths.yarn
        run! "#{paths.yarn} install"
      else
        run! "#{paths.npm} prune && #{paths.npm} install"
      end

      if paths.bower_json.exist?
        run! "#{paths.bower} prune && #{paths.bower} install"
      end
    end

    def test
      run! ember.test
    end

    private

    attr_accessor :dev_server_pid, :pid
    attr_reader :ember, :env, :options, :paths

    delegate :run, :run!, to: :runner

    def invalid_ember_dependencies?
      !run("#{paths.ember} version").success?
    rescue DependencyError
      false
    end

    def clean_ember_dependencies!
      ember_dependency_directories.flat_map(&:children).each(&:rmtree)
    end

    def ember_dependency_directories
      [
        paths.node_modules,
        paths.bower_components,
      ].select(&:exist?)
    end

    def spawn(command, **redirects)
      Kernel.spawn(
        env,
        command,
        chdir: paths.root.to_s,
        **redirects,
      ) || exit(1)
    end

    def signal(process_id)
      Process.kill(:INT, process_id)
    rescue Errno::ESRCH, Errno::EPERM
      nil
    end

    def runner
      Runner.new(
        options: { chdir: paths.root.to_s },
        out: [$stdout, paths.log.open("a")],
        err: [$stderr],
        env: env,
      )
    end

    def running?
      process_running?(pid)
    end

    def process_running?(process_id)
      process_id.present? && !!Process.getpgid(process_id)
    rescue Errno::ESRCH
      false
    end

    def lock_buildfile
      FileUtils.touch(paths.lockfile)
    end

    def detach
      Process.detach pid
    end
  end
end
