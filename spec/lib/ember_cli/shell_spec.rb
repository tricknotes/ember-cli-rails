require "ember_cli/shell"

describe EmberCli::Shell do
  describe "#test" do
    it "returns a successful status when the suite passes" do
      shell = build_shell(ember: "true")

      status = shell.test

      expect(status).to be_success
    end

    it "returns an unsuccessful status when the suite fails" do
      shell = build_shell(ember: "false")

      status = shell.test

      expect(status).not_to be_success
    end
  end

  # The `ember` executable is the seam: `Command#test` builds the command
  # line from it, so `true` and `false` stand in for a passing and a failing
  # `ember test` run.
  def build_shell(ember:)
    paths = double(
      "EmberCli::PathSet",
      ember: ember,
      root: Pathname.new(Dir.pwd),
      log: Pathname.new(File::NULL),
    )

    EmberCli::Shell.new(paths: paths)
  end
end
