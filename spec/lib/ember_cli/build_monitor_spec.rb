require "ember_cli/errors"
require "ember_cli/build_monitor"

describe EmberCli::BuildMonitor do
  BLANK_LINE = ""

  describe "#reset" do
    context "when there is a build error" do
      it "deletes the build file" do
        error_file = error_file_with_contents
        paths = build_paths(error_file)
        monitor = EmberCli::BuildMonitor.new(nil, paths)

        monitor.reset

        expect(error_file).to have_received(:delete)
      end
    end

    context "when there are only deprecation warnings" do
      it "deletes the build file" do
        error_file = error_file_with_contents(["DEPRECATION: A warning"])
        paths = build_paths(error_file)
        monitor = EmberCli::BuildMonitor.new(nil, paths)

        monitor.reset

        expect(error_file).to have_received(:delete)
      end
    end

    context "when there is not a build error" do
      it "does nothing" do
        error_file = missing_error_file
        paths = build_paths(error_file)
        monitor = EmberCli::BuildMonitor.new(nil, paths)

        monitor.reset

        expect(error_file).not_to have_received(:delete)
      end
    end
  end

  describe "#check!" do
    context "when the error file has content" do
      it "raises a BuildError" do
        paths = build_paths(error_file_with_contents(["first-line"]))
        monitor = EmberCli::BuildMonitor.new("app-name", paths)

        expect { monitor.check! }.
          to raise_error(
            EmberCli::BuildError,
            %{"app-name" has failed to build: first-line},
          )
      end
    end

    context "when the error file describes the file that failed to build" do
      it "raises a BuildError reporting every line of the failure" do
        error_file = error_file_with_contents(
          [
            "Build failed.",
            "File: app/templates/application.hbs",
            "Parse error on line 4:",
            "    at AStackTrace",
          ])
        paths = build_paths(error_file)
        monitor = EmberCli::BuildMonitor.new("app-name", paths)

        expect { monitor.check! }.
          to raise_error(
            EmberCli::BuildError,
            %{"app-name" has failed to build: Build failed.\nFile: app/templates/application.hbs\nParse error on line 4:},
          )
      end

      it "sets the backtrace to the lines of the failure" do
        error_file = error_file_with_contents(
          [
            "File: app/templates/application.hbs",
            "Parse error on line 4:",
          ])
        paths = build_paths(error_file)
        monitor = EmberCli::BuildMonitor.new("app-name", paths)

        expect { monitor.check! }.to raise_error(EmberCli::BuildError) do |error|
          expect(error.backtrace).to eq(
            [
              "File: app/templates/application.hbs",
              "Parse error on line 4:",
            ])
        end
      end
    end

    context "when the error file's lines end in newlines" do
      it "raises a BuildError without the trailing newlines" do
        error_file = error_file_with_contents(
          [
            "File: app/templates/application.hbs\n",
            "Parse error on line 4:\n",
          ])
        paths = build_paths(error_file)
        monitor = EmberCli::BuildMonitor.new("app-name", paths)

        expect { monitor.check! }.
          to raise_error(
            EmberCli::BuildError,
            %{"app-name" has failed to build: File: app/templates/application.hbs\nParse error on line 4:},
          )
      end
    end

    context "when the error file only contains deprecation warnings" do
      it "does not raise a BuildError" do
        error_file = error_file_with_contents(
          [
            BLANK_LINE,
            "DEPRECATION: A warning",
            "    at AStackTrace",
          ])
        paths = build_paths(error_file)
        monitor = EmberCli::BuildMonitor.new(nil, paths)

        expect(monitor.check!).to be true
      end
    end

    context "when the error file contains a ASCII colored deprecation" do
      it "does not raise a BuildError" do
        error_file = error_file_with_contents(
          [
            BLANK_LINE,
            "\e[33mDEPRECATION: A warning",
            "    at AStackTrace\e[39m",
          ])
        paths = build_paths(error_file)
        monitor = EmberCli::BuildMonitor.new(nil, paths)

        expect(monitor.check!).to be true
      end
    end

    context "when the error file contains an ASCII colored Building notice" do
      it "does not raise a BuildError" do
        error_file = error_file_with_contents(
          [
            "- \e[32mBuilding\e[39m"
          ])
        paths = build_paths(error_file)
        monitor = EmberCli::BuildMonitor.new(nil, paths)

        expect(monitor.check!).to be true
      end
    end

    context "when the error file contains both errors & deprecation warnings" do
      it "raises a BuildError" do
        error_file = error_file_with_contents(
          [
            BLANK_LINE,
            "DEPRECATION: A warning",
            "    at AStackTrace",
            BLANK_LINE,
            "SyntaxError: things went wrong",
          ])
        paths = build_paths(error_file)
        monitor = EmberCli::BuildMonitor.new("app-name", paths)

        expect { monitor.check! }.
          to raise_error(
            EmberCli::BuildError,
            %{"app-name" has failed to build: SyntaxError: things went wrong},
          )
      end
    end

    context "when the error file exists but is empty" do
      it "does not raise a BuildError" do
        paths = build_paths(blank_error_file)
        monitor = EmberCli::BuildMonitor.new(nil, paths)

        expect(monitor.check!).to be true
      end
    end

    context "when the error file is missing" do
      it "does not raise a BuildError" do
        paths = build_paths(missing_error_file)
        monitor = EmberCli::BuildMonitor.new(nil, paths)

        expect(monitor.check!).to be true
      end
    end
  end

  def build_paths(error_file)
    double(build_error_file: error_file)
  end

  def error_file_with_contents(contents = ["foo"])
    build_error_file(exist?: true, size?: true, readlines: contents)
  end

  def blank_error_file
    build_error_file(exist?: true, size?: false)
  end

  def missing_error_file
    build_error_file(exist?: false)
  end

  def build_error_file(**options)
    double(**options).tap do |stub|
      allow(stub).to receive(:delete)
    end
  end
end
