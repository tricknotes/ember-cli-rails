require "fileutils"
require "ember_cli/path_set"

describe EmberCli::PathSet do
  describe "#root" do
    it "depends on the app name" do
      app = build_app(name: "foo")

      path_set = build_path_set(app: app)

      expect(path_set.root).to eq rails_root.join("foo")
    end

    it "can be overridden" do
      app = build_app(name: "foo", options: { path: "not-foo" })

      path_set = build_path_set(app: app)

      expect(path_set.root).to eq rails_root.join("not-foo")
    end
  end

  describe "#tmp" do
    it "is a child of #root" do
      app = build_app

      path_set = build_path_set(app: app)

      expect(path_set.tmp).to exist
      expect(path_set.tmp).to eq rails_root.join(app.name, "tmp")
    end
  end

  describe "#log" do
    it "depends on the environment" do
      app = build_app(name: "foo")
      path_set = build_path_set(app: app, environment: "bar")

      expect(path_set.log).to eq rails_root.join("log", "ember-foo.bar.log")
      expect(rails_root.join("log")).to exist
    end
  end

  describe "#dist" do
    it "depends on the app name" do
      app = build_app(name: "foo")

      path_set = build_path_set(app: app)

      expect(path_set.dist).to exist
      expect(path_set.dist).to eq ember_cli_root.join("apps", "foo")
    end
  end

  describe "#gemfile" do
    it "is a child of #root" do
      app = build_app(name: "foo")

      path_set = build_path_set(app: app)

      expect(path_set.gemfile).to eq rails_root.join("foo", "Gemfile")
    end
  end

  describe "#lockfile" do
    it "is a child of #tmp" do
      path_set = build_path_set

      expect(path_set.lockfile).to eq path_set.tmp.join("build.lock")
    end
  end

  describe "#build_error_file" do
    it "is a child of #tmp" do
      path_set = build_path_set

      expect(path_set.build_error_file).to eq path_set.tmp.join("error.txt")
    end
  end

  describe "#ember" do
    it "is an executable child of #node_modules" do
      app = build_app
      path_set = build_path_set(app: app)
      ember_path = rails_root.join(app.name, "node_modules", "ember-cli", "bin", "ember")
      create_executable(ember_path)

      ember = path_set.ember

      expect(ember).to eq(ember_path).and(be_executable)
    end

    it "raises a DependencyError if the file isn't executable" do
      path_set = build_path_set

      expect { path_set.ember }.to raise_error(EmberCli::DependencyError)
    end
  end

  describe "#bower" do
    it "can be overridden" do
      fake_bower = create_executable(ember_cli_root.join("bower"))
      app = build_app(options: { bower_path: fake_bower.to_s })
      path_set = build_path_set(app: app)

      bower = path_set.bower

      expect(bower).to eq(fake_bower).and(be_executable)
    end

    it "can be inferred from the $PATH" do
      fake_bower = create_executable(ember_cli_root.join("bower"))
      stub_which(bower: fake_bower.to_s)
      path_set = build_path_set

      bower = path_set.bower

      expect(bower).to eq(fake_bower).and(be_executable)
    end

    context "when it is missing from the $PATH" do
      context "bower.json exists" do
        it "raises a helpful exception" do
          app = build_app
          create_file(app_root_for(app).join("bower.json"))
          stub_which(bower: nil)
          path_set = build_path_set

          expect { path_set.bower }.
            to raise_error(EmberCli::DependencyError, /bower is required/i)
        end

        context "bower.json is missing" do
          it "returns nil" do
            stub_which(bower: nil)
            path_set = build_path_set

            bower = path_set.bower

            expect(bower).to be_nil
          end
        end
      end
    end
  end

  describe "#bower_json" do
    it "is a child of #root" do
      app = build_app
      path_set = build_path_set(app: app)

      bower_json = path_set.bower_json

      expect(bower_json).to eq app_root_for(app).join("bower.json")
    end
  end

  describe "#vite?" do
    it "is false when the app has no Vite config" do
      path_set = build_path_set

      expect(path_set).not_to be_vite
    end

    it "is true when the app has a vite.config.mjs" do
      app = build_app
      create_file(app_root_for(app).join("vite.config.mjs"))
      path_set = build_path_set(app: app)

      expect(path_set).to be_vite
    end

    it "is true when the app has a vite.config.js" do
      app = build_app
      create_file(app_root_for(app).join("vite.config.js"))
      path_set = build_path_set(app: app)

      expect(path_set).to be_vite
    end
  end

  describe "#bower_components" do
    it "is a child of #root" do
      app = build_app(name: "foo")

      path_set = build_path_set(app: app)

      expect(path_set.bower_components).
        to eq rails_root.join("foo", "bower_components")
    end
  end

  describe "#npm" do
    it "can be overridden" do
      fake_npm = create_executable(ember_cli_root.join("npm"))
      app = build_app(options: { npm_path: fake_npm.to_s })
      path_set = build_path_set(app: app)

      npm = path_set.npm

      expect(npm).to eq(fake_npm).and(be_executable)
    end

    it "can be inferred from the $PATH" do
      fake_npm = create_executable(ember_cli_root.join("npm"))
      stub_which(npm: fake_npm.to_s)
      path_set = build_path_set

      npm = path_set.npm

      expect(npm).to eq(fake_npm).and(be_executable)
    end
  end

  describe "#yarn" do
    it "can be overridden" do
      fake_yarn = create_executable(ember_cli_root.join("yarn"))
      app = build_app(options: { yarn_path: fake_yarn.to_s })
      path_set = build_path_set(app: app)

      yarn = path_set.yarn

      expect(yarn).to eq(fake_yarn).and(be_executable)
    end

    it "can be inferred from the $PATH" do
      fake_yarn = create_executable(ember_cli_root.join("yarn"))
      stub_which(yarn: fake_yarn.to_s)
      app = build_app(options: { yarn: true })
      path_set = build_path_set(app: app)
      create_executable(fake_yarn)

      yarn = path_set.yarn

      expect(yarn).to eq(fake_yarn).and(be_executable)
    end

    context "when the executable isn't installed on the system" do
      context "and yarn is requested" do
        it "raises a DependencyError" do
          stub_which(yarn: nil)
          app = build_app(options: { yarn: true })
          path_set = build_path_set(app: app)

          expect { path_set.yarn }.to raise_error(EmberCli::DependencyError)
        end
      end

      context "and yarn is not requested" do
        it "returns nil" do
          stub_which(yarn: nil)
          path_set = build_path_set

          yarn = path_set.yarn

          expect(yarn).to be_nil
        end
      end
    end
  end

  describe "#node_modules" do
    it "is a child of #root" do
      app = build_app(name: "foo")

      path_set = build_path_set(app: app)

      expect(path_set.node_modules).to eq rails_root.join("foo", "node_modules")
    end
  end

  describe "#tee" do
    it "can be overridden" do
      fake_tee = create_executable(rails_root.join("tee"))
      app = build_app(options: { tee_path: fake_tee.to_s })
      path_set = build_path_set(app: app)

      tee = path_set.tee

      expect(tee).to eq(fake_tee).and(be_executable)
    end

    it "can be inferred from the $PATH" do
      fake_tee = create_executable(rails_root.join("tee"))
      stub_which(tee: fake_tee.to_s)
      path_set = build_path_set

      tee = path_set.tee

      expect(tee).to eq(fake_tee).and(be_executable)
    end
  end

  describe "#bundler" do
    it "can be overridden" do
      fake_bundler = create_executable(rails_root.join("bundler"))
      app = build_app(options: { bundler_path: fake_bundler.to_s })
      path_set = build_path_set(app: app)

      bundler = path_set.bundler

      expect(bundler).to eq(fake_bundler).and(be_executable)
    end

    it "can be inferred from the $PATH" do
      fake_bundler = create_executable(rails_root.join("bundler"))
      stub_which(bundler: fake_bundler.to_s)
      path_set = build_path_set

      bundler = path_set.bundler

      expect(bundler).to eq(fake_bundler).and(be_executable)
    end
  end

  describe "#cached_directories" do
    it "includes the full path to the application's node_modules" do
      app_name = "foo"
      app = build_app(name: app_name)
      path_set = build_path_set(app: app)

      cached_directories = path_set.cached_directories

      expect(cached_directories).to include(
        rails_root.join(app_name, "node_modules"),
      )
    end

    context "when bower.json exists" do
      it "includes the full path to bower_components" do
        app_name = "foo"
        app = build_app(name: app_name)
        app_root = rails_root.join(app_name)
        path_set = build_path_set(app: app)
        create_file(app_root.join("bower.json"))

        cached_directories = path_set.cached_directories

        expect(cached_directories).to include(
          rails_root.join(app_name, "bower_components"),
        )
      end
    end

    context "when bower.json does not exist" do
      it "does not include the path to bower_components" do
        app_name = "foo"
        app = build_app(name: app_name)
        path_set = build_path_set(app: app)

        cached_directories = path_set.cached_directories

        expect(cached_directories).not_to include(nil)
        expect(cached_directories).not_to include(
          rails_root.join(app_name, "bower_components"),
        )
      end
    end
  end

  def create_file(path)
    path.parent.mkpath
    FileUtils.touch(path)
    path
  end

  def create_executable(path)
    file = File.new(create_file(path))
    file.chmod(0777)
    path
  end

  def build_app(**options)
    double(
      options.reverse_merge(
        name: "foo",
        options: {},
      ),
    )
  end

  def stub_which(program_to_path)
    allow(EmberCli::Helpers).
      to receive(:which).
      with(program_to_path.keys.first.to_s).
      and_return(program_to_path.values.last)
  end

  def build_path_set(**options)
    EmberCli::PathSet.new(
      **options.reverse_merge(
        app: build_app,
        rails_root: rails_root,
        ember_cli_root: ember_cli_root,
        environment: "test",
      ),
    )
  end

  def app_root_for(app)
    rails_root.join(app.name)
  end

  def ember_cli_root
    Rails.root.join("tmp", "ember_cli").tap(&:mkpath)
  end

  def rails_root
    Rails.root.join("tmp", "rails").tap(&:mkpath)
  end

  def remove_temporary_directories
    [rails_root, ember_cli_root].each do |dir|
      if dir.exist?
        FileUtils.rm_rf(dir)
      end
    end
  end

  before do
    remove_temporary_directories
  end
end
