require "open3"

require "ember_cli/errors"

module EmberCli
  class Runner
    def initialize(out:, err:, env: {}, options: {})
      @env = env
      @output_streams = Array(out)
      @error_streams = Array(err)
      @options = options
      @threads = []
    end

    def run(command)
      Open3.popen3(env, command, options) do |stdin, stdout, stderr, process|
        stdin.close

        threads << redirect_stream_in_thread(stdout, write_to: output_streams)
        threads << redirect_stream_in_thread(stderr, write_to: error_streams)

        threads.each(&:join)
        process.value
      end
    end

    def run!(command)
      run(command).tap do |status|
        unless status.success?
          fail BuildError, "`#{command}` failed with status #{status.exitstatus}"
        end
      end
    end

    protected

    attr_reader :env, :error_streams, :options, :output_streams, :threads

    private

    def redirect_stream_in_thread(stream, write_to:)
      Thread.new do
        Thread.current.abort_on_exception = true

        while line = stream.gets
          write_to.each { |redirection_stream| redirection_stream.puts(line) }
        end
      end
    end
  end
end
