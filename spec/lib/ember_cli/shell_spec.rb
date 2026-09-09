require "tmpdir"

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

  describe "#install" do
    it "prunes and installs with npm by default" do
      shell = build_installing_shell(package_manager: :npm)

      shell.install

      expect(commands_run).to eq ["npm prune", "npm install"]
    end

    it "installs with yarn when yarn is the package manager" do
      shell = build_installing_shell(package_manager: :yarn)

      shell.install

      expect(commands_run).to eq ["yarn install"]
    end

    it "installs with pnpm when pnpm is the package manager" do
      shell = build_installing_shell(package_manager: :pnpm)

      shell.install

      expect(commands_run).to eq ["pnpm install"]
    end

    # Each package manager is a script that records its command line, and
    # `ember` is `true` so that the installed dependencies count as valid.
    def build_installing_shell(package_manager:)
      paths = double(
        "EmberCli::PathSet",
        package_manager: package_manager,
        npm: fake_package_manager("npm"),
        yarn: fake_package_manager("yarn"),
        pnpm: fake_package_manager("pnpm"),
        ember: "true",
        gemfile: install_root.join("Gemfile"),
        bower_json: install_root.join("bower.json"),
        root: install_root,
        log: Pathname.new(File::NULL),
      )

      EmberCli::Shell.new(paths: paths)
    end

    def fake_package_manager(name)
      install_root.join(name).tap do |script|
        script.write(<<~SH)
          #!/bin/sh
          echo "#{name} $*" >> #{commands_log}
        SH
        script.chmod(0o755)
      end
    end

    def commands_run
      commands_log.read.lines(chomp: true)
    end

    def commands_log
      install_root.join("commands.log")
    end

    def install_root
      @install_root ||= Pathname.new(Dir.mktmpdir("ember-cli-rails-install"))
    end

    after do
      if @install_root
        @install_root.rmtree
      end
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
