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
        self.pid = spawn ember.build(watch: true)
        detach
      end
    end

    def stop
      if pid.present?
        Process.kill(:INT, pid)
        self.pid = nil
      end
    end

    def install
      if paths.gemfile.exist?
        run! "#{paths.bundler} install"
      end

      run! "#{paths.ember} version || rm -rf #{paths.npm_deps} #{paths.bower_deps}"
      run! "#{paths.npm} prune && #{paths.npm} install"
      run! "#{paths.bower} prune && #{paths.bower} install"
    end

    def test
      run! ember.test
    end

    private

    attr_accessor :pid
    attr_reader :ember, :env, :options, :paths

    def spawn(command)
      Kernel.spawn(
        env,
        command,
        chdir: paths.root.to_s,
        err: paths.build_error_file.to_s,
      ) || exit(1)
    end

    def run!(command)
      Runner.new(
        options: { chdir: paths.root.to_s },
        out: paths.log,
        err: $stderr,
        env: env,
      ).run!(command)
    end

    def running?
      pid.present? && Process.getpgid(pid)
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
