require "ember-cli-rails"

describe EmberCli::App do
  describe "#to_rack" do
    it "delegates to `#deploy`" do
      deploy = double(to_rack: :delegated)
      app = EmberCli["my-app"]
      allow(app).to receive(:deploy).and_return(deploy)

      to_rack = app.to_rack

      expect(to_rack).to be :delegated
    end

    context "when served by the development server" do
      it "proxies to the development server" do
        app = build_app("frontend", vite: true, environment: "development")

        expect(app.to_rack).to be_a(EmberCli::DevServerProxy)
      end
    end
  end

  describe "#mountable?" do
    it "delegates to `#deploy`" do
      deploy = double(mountable?: :delegated)
      app = EmberCli["my-app"]
      allow(app).to receive(:deploy).and_return(deploy)

      mountable = app.mountable?

      expect(mountable).to be :delegated
    end
  end

  describe "yarn_enabled?" do
    context "when configured with yarn: true" do
      it "returns true" do
        app = EmberCli::App.new("with-yarn", yarn: true)

        yarn_enabled = app.yarn_enabled?

        expect(yarn_enabled).to be true
      end
    end

    context "when configured with yarn: false" do
      it "returns false" do
        app = EmberCli::App.new("without-yarn", yarn: false)

        yarn_enabled = app.yarn_enabled?

        expect(yarn_enabled).to be false
      end
    end
  end

  describe "#bower?" do
    context "when bower.json exists" do
      it "returns true" do
        bower_json_path = double("Pathname", exist?: true)
        stub_paths(bower_json: bower_json_path)
        app = EmberCli::App.new("with bower json")

        bower_required = app.bower?

        expect(bower_required).to be true
      end
    end

    context "when bower.json is absent" do
      it "returns false" do
        bower_json_path = double("Pathname", exist?: false)
        stub_paths(bower_json: bower_json_path)
        app = EmberCli::App.new("without bower json")

        bower_required = app.bower?

        expect(bower_required).to be false
      end
    end
  end

  describe "#compile" do
    it "exits with exit status of 0" do
      passed = EmberCli["my-app"].compile

      expect(passed).to be true
    end
  end

  describe "#test" do
    it "exits with exit status of 0" do
      passed = EmberCli["my-app"].test

      expect(passed).to be true
    end
  end

  describe "#root_path" do
    it "delegates to PathSet" do
      root_path = Pathname.new(".")
      stub_paths(root: root_path)
      app = EmberCli::App.new("foo")

      root_path = app.root_path

      expect(root_path).to eq root_path
    end
  end

  describe "#dist_path" do
    it "delegates to PathSet" do
      dist_path = Pathname.new(".")
      stub_paths(dist: dist_path)
      app = EmberCli::App.new("foo")

      dist_path = app.dist_path

      expect(dist_path).to eq dist_path
    end
  end

  describe "#dev_server?" do
    context "with a Vite-based application in development" do
      it "returns true" do
        app = build_app("frontend", vite: true, environment: "development")

        expect(app.dev_server?).to be true
      end

      it "returns false when the development server is disabled" do
        app = build_app(
          "frontend",
          vite: true,
          environment: "development",
          dev_server: false,
        )

        expect(app.dev_server?).to be false
      end

      it "returns false when another strategy is configured for the environment" do
        app = build_app(
          "frontend",
          vite: true,
          environment: "development",
          deploy: { development: EmberCli::Deploy::File },
        )

        expect(app.dev_server?).to be false
      end
    end

    context "with a classic application in development" do
      it "returns false" do
        app = build_app("frontend", vite: false, environment: "development")

        expect(app.dev_server?).to be false
      end
    end

    context "outside of development" do
      it "returns false" do
        app = build_app("frontend", vite: true, environment: "test")

        expect(app.dev_server?).to be false
      end
    end
  end

  describe "#build" do
    context "when served by the development server" do
      it "starts the development server instead of building" do
        app = build_app("frontend", vite: true, environment: "development")
        dev_server = double(start: true)
        allow(app).to receive(:dev_server).and_return(dev_server)
        allow(app).to receive(:compile)

        app.build

        expect(dev_server).to have_received(:start)
        expect(app).not_to have_received(:compile)
      end
    end
  end

  def build_app(name, vite:, environment:, **options)
    allow(Rails).to receive(:env).
      and_return(ActiveSupport::StringInquirer.new(environment))
    allow(EmberCli).to receive(:env).and_return(environment)
    allow_any_instance_of(EmberCli::PathSet).to receive(:vite?).and_return(vite)

    EmberCli::App.new(name, **options)
  end

  def stub_paths(method_to_value)
    allow_any_instance_of(EmberCli::PathSet).
      to receive(method_to_value.keys.first).
      and_return(method_to_value.values.first)
  end
end
