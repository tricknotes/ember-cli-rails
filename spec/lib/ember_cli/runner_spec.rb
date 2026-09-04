require "ember_cli/runner"

describe EmberCli::Runner do
  describe "#run!" do
    context "when the command fails" do
      it "writes output to `out` streams" do
        stdout = StringIO.new
        logfile = StringIO.new
        runner = EmberCli::Runner.new(
          err: [],
          out: [stdout, logfile],
        )

        expect { runner.run!(command_with_error(out: "out")) }.
          to raise_error(EmberCli::BuildError, /failed with status 1/)

        expect(split_output_from_stream(stdout)).to eq(%w[out out])
        expect(split_output_from_stream(logfile)).to eq(%w[out out])
      end

      it "writes errors to `err` streams" do
        stderr = StringIO.new
        logfile = StringIO.new
        runner = EmberCli::Runner.new(
          err: [stderr, logfile],
          out: [],
        )

        expect { runner.run!(command_with_error(err: "err")) }.
          to raise_error(EmberCli::BuildError, /failed with status 1/)

        expect(split_output_from_stream(stderr)).to eq(%w[err err])
        expect(split_output_from_stream(logfile)).to eq(%w[err err])
      end
    end

    it "executes the command" do
      out = StringIO.new
      err = StringIO.new
      runner = EmberCli::Runner.new(err: [err], out: [out])

      status = runner.run!(command("out"))

      [err, out].each(&:rewind)

      expect(status).to be_success
      expect(split_output_from_stream(err)).to be_empty
      expect(split_output_from_stream(out)).to eq(%w[out])
    end

    def split_output_from_stream(stream)
      stream.rewind

      stream.read.split
    end

    def command(output)
      "echo '#{output}'"
    end

    def command_with_error(out: "", err: "")
      [
        "echo '#{out}'",
        "echo '#{err}' > /dev/stderr",
        "echo '#{out}'",
        "echo '#{err}' > /dev/stderr",
        "exit 1",
      ].join("; ")
    end
  end
end
