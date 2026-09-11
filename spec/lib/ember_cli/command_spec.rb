require "ember_cli/command"

describe EmberCli::Command do
  describe "#test" do
    it "builds an `ember test` command" do
      paths = build_paths(ember: "path/to/ember")
      command = build_command(paths: paths)

      expect(command.test).to eq("path\/to\/ember test --environment test")
    end
  end

  describe "#build" do
    it "builds an `ember build` command" do
      paths = build_paths(ember: "path/to/ember")
      command = build_command(paths: paths)

      expect(command.build).to match(%r{path\/to\/ember build})
    end

    context "when building in production" do
      it "includes the `--environment production` flag" do
        paths = build_paths
        command = build_command(paths: paths)
        allow(EmberCli).to receive(:env).and_return("production")

        expect(command.build).to match(/--environment 'production'/)
      end
    end

    context "when building in any other environment" do
      it "includes the `--environment development` flag" do
        paths = build_paths
        command = build_command(paths: paths)
        allow(EmberCli).to receive(:env).and_return("test")

        expect(command.build).to match(/--environment 'development'/)
      end
    end

    it "includes the `--output-path` flag" do
      paths = build_paths(dist: "path/to/dist")
      command = build_command(paths: paths)

      expect(command.build).to match(%r{--output-path 'path\/to\/dist'})
    end

    context "when configured not to watch" do
      it "excludes the `--watch` flag" do
        paths = build_paths
        command = build_command(paths: paths)

        expect(command.build).not_to match(/--watch/)
      end
    end

    context "when configured not to be silent" do
      it "exludes the `--silent` flag" do
        paths = build_paths
        command = build_command(paths: paths)

        expect(command.build).not_to match(/--silent/)

        paths = build_paths
        command = build_command(paths: paths, options: { silent: false })

        expect(command.build).not_to match(/--silent/)
      end
    end

    context "when configured to be silent" do
      it "includes `--silent` flag" do
        paths = build_paths
        command = build_command(paths: paths, options: { silent: true })

        expect(command.build).to match(/--silent/)
      end
    end

    context "when configured to watch" do
      it "includes the `--watch` flag" do
        paths = build_paths
        command = build_command(paths: paths)

        expect(command.build(watch: true)).to match(/--watch/)
      end

      it "defaults to configuration for the `--watcher` flag" do
        paths = build_paths
        command = build_command(paths: paths)
        allow(EmberCli).
          to receive(:configuration).
          and_return(build_paths(watcher: "bar"))

        expect(command.build(watch: true)).to match(/--watcher 'bar'/)
      end

      context "when a watcher is configured" do
        it "configures the build with the value" do
          paths = build_paths
          command = build_command(paths: paths, options: { watcher: "foo" })

          expect(command.build(watch: true)).to match(/--watcher 'foo'/)
        end
      end
    end
  end

  describe "#build for a Vite-based application" do
    it "builds a `vite build` command writing to the output path" do
      paths = build_paths(vite?: true, vite: "path/to/vite", dist: "path/to/dist")
      command = build_command(paths: paths)

      expect(command.build).to match(%r{path/to/vite build})
      expect(command.build).to match(/--mode 'development'/)
      expect(command.build).to match(%r{--outDir 'path/to/dist'})
      expect(command.build).to match(/--emptyOutDir/)
    end

    it "does not pass the flags `ember build` takes" do
      paths = build_paths(vite?: true, vite: "path/to/vite")
      command = build_command(paths: paths, options: { watcher: "events" })

      expect(command.build(watch: true)).not_to match(/--watch/)
      expect(command.build(watch: true)).not_to match(/--environment/)
    end

    it "quiets the build when configured to be silent" do
      paths = build_paths(vite?: true, vite: "path/to/vite")

      expect(build_command(paths: paths).build).not_to match(/--logLevel/)

      command = build_command(paths: paths, options: { silent: true })

      expect(command.build).to match(/--logLevel error/)
    end
  end

  def build_paths(**options)
    double({ vite?: false }.merge(options)).as_null_object
  end

  def build_command(**options)
    EmberCli::Command.new(**options)
  end
end
