require "generator_spec"
require "generators/ember/heroku/heroku_generator"

describe EmberCli::HerokuGenerator, type: :generator do
  OUTPUT_DIRECTORY = Rails.root.join("tmp", "generator_test_output")
  destination OUTPUT_DIRECTORY

  context "without yarn enabled" do
    it "does not generate a root-level yarn.lock" do
      setup_destination
      configure_application(package_manager: :npm)

      run_generator

      expect(destination_root).to have_structure {
        no_file "yarn.lock"
      }
    end
  end

  context "with yarn enabled" do
    it "generates a root-level yarn.lock" do
      setup_destination
      configure_application(package_manager: :yarn)

      run_generator

      expect(destination_root).to have_structure {
        file "yarn.lock"
      }
    end
  end

  context "without pnpm enabled" do
    it "does not generate a root-level pnpm-lock.yaml" do
      setup_destination
      configure_application(package_manager: :npm)

      run_generator

      expect(destination_root).to have_structure {
        no_file "pnpm-lock.yaml"
      }
    end
  end

  context "with pnpm enabled" do
    it "generates a root-level pnpm-lock.yaml" do
      setup_destination
      configure_application(package_manager: :pnpm)

      run_generator

      expect(destination_root).to have_structure {
        file "pnpm-lock.yaml"
      }
    end
  end

  describe "Gemfile" do
    it "leaves the Gemfile untouched" do
      setup_destination
      configure_application

      run_generator

      expect(gemfile_contents).to eq("")
    end

    def gemfile_contents
      destination_root.join("Gemfile").read
    end
  end

  describe "package.json" do
    it "includes the root directory node_modules" do
      setup_destination
      configure_application

      run_generator

      expect(cache_directories_from_package_json).to include("node_modules")
    end

    context "when no Ember application depends on bower" do
      it "does not include bower as a dependency" do
        setup_destination
        depend_on_bower(false)
        configure_application

        run_generator

        expect(package_json.keys).not_to include("dependencies")
        expect(cache_directories_from_package_json).not_to include_bower
      end
    end

    context "when an Ember application depends on bower" do
      it "includes bower as a dependency" do
        setup_destination
        depend_on_bower(true)
        configure_application

        run_generator

        expect(dependencies_from_package_json).to include("bower" => "*")
        expect(cache_directories_from_package_json).to include_bower
      end
    end

    describe "engines" do
      it "pins the NodeJS version the Ember applications declare" do
        setup_destination
        configure_applications(node_engine: ">= 20.19.0")

        run_generator

        expect(package_json.fetch("engines")).to eq("node" => ">= 20.19.0")
      end

      it "omits engines when no Ember application declares one" do
        setup_destination
        configure_applications(node_engine: nil)

        run_generator

        expect(package_json.keys).not_to include("engines")
      end

      it "omits engines when the Ember applications disagree" do
        setup_destination
        configure_applications(
          { node_engine: ">= 20.19.0" },
          { node_engine: ">= 22.0.0" },
        )

        run_generator

        expect(package_json.keys).not_to include("engines")
      end
    end

    describe "packageManager" do
      it "pins the package manager the Ember applications declare" do
        setup_destination
        configure_applications(package_manager_spec: "pnpm@10.0.0")

        run_generator

        expect(package_json.fetch("packageManager")).to eq("pnpm@10.0.0")
      end

      it "omits packageManager when no Ember application declares one" do
        setup_destination
        configure_applications(package_manager_spec: nil)

        run_generator

        expect(package_json.keys).not_to include("packageManager")
      end

      it "omits packageManager when the Ember applications disagree" do
        setup_destination
        configure_applications(
          { package_manager_spec: "pnpm@10.0.0" },
          { package_manager_spec: "pnpm@9.0.0" },
        )

        run_generator

        expect(package_json.keys).not_to include("packageManager")
      end
    end

    def configure_applications(*attributes)
      apps = attributes.map do |app_attributes|
        instance_double(
          EmberCli::App,
          {
            bower?: false,
            cached_directories: [],
            node_engine: nil,
            package_manager_spec: nil,
            pnpm?: false,
            yarn?: false,
          }.merge(app_attributes),
        )
      end

      allow(EmberCli).to receive(:apps).
        and_return(apps.map.with_index { |app, i| ["app-#{i}", app] }.to_h)
    end

    def depend_on_bower(bower_enabled)
      allow_any_instance_of(EmberCli::App).
        to receive(:bower?).and_return(bower_enabled)

      allow_any_instance_of(EmberCli::App).
        to receive(:cached_directories).and_return(
          cached_directories(bower_enabled),
        )
    end

    def cached_directories(bower_enabled)
      if bower_enabled
        [OUTPUT_DIRECTORY.join("bower_components")]
      else
        []
      end
    end

    def include_bower
      include(/bower_components/)
    end

    def cache_directories_from_package_json
      package_json.fetch("cacheDirectories")
    end

    def dependencies_from_package_json
      package_json.fetch("dependencies")
    end

    def package_json
      JSON.parse(package_json_contents)
    end

    def package_json_contents
      destination_root.join("package.json").read
    end
  end

  # Register only this application: the dummy project's own applications
  # would otherwise take part in the generator's `EmberCli.any?` checks.
  def configure_application(**options)
    app = EmberCli::App.new("my-app", **options)

    allow(EmberCli).to receive(:apps).and_return("my-app" => app)
  end

  def setup_destination
    prepare_destination

    create_empty_gemfile
  end

  def create_empty_gemfile
    FileUtils.touch(destination_root.join("Gemfile"))
  end
end
