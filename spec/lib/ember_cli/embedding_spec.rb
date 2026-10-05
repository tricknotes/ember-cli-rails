require "fileutils"
require "pathname"
require "tmpdir"
require "ember_cli/embedding"

describe EmberCli::Embedding do
  it "keeps the classes it reads a build with to itself" do
    expect { EmberCli::Embedding::AssetMap }.to raise_error(NameError)
    expect { EmberCli::Embedding::StartupTags }.to raise_error(NameError)
    expect { EmberCli::Embedding::Url }.to raise_error(NameError)
  end

  describe "#startup_tags?" do
    it "is false for a classic build" do
      expect(build_embedding).not_to be_startup_tags
    end

    it "is true for a Vite build" do
      expect(build_embedding(vite?: true)).to be_startup_tags
    end

    it "is true for an application served by Vite's development server" do
      expect(build_embedding(dev_server: dev_server)).to be_startup_tags
    end
  end

  describe "#startup_tags" do
    it "extracts the tags the application boots from" do
      build_index_html(<<~HTML)
        <meta name="my-app/config/environment" content="%7B%7D">
        <link rel="stylesheet" href="/app.css">
        <link rel="modulepreload" href="/vendor.js">
        <link rel="icon" href="/favicon.ico">
        <script type="module" src="/app.js"></script>
      HTML
      embedding = build_embedding(vite?: true)

      tags = embedding.startup_tags

      expect(tags).to match_array([
        %{<meta name="my-app/config/environment" content="%7B%7D">},
        %{<link rel="stylesheet" href="/app.css">},
        %{<link rel="modulepreload" href="/vendor.js">},
        %{<script type="module" src="/app.js"></script>},
      ])
    end

    it "mounts the root-relative URLs onto `prepend`" do
      build_index_html(<<~HTML)
        <link rel="stylesheet" href="/app.css">
        <script type="module" src="/app.js"></script>
      HTML
      embedding = build_embedding(vite?: true)

      tags = embedding.startup_tags(prepend: "/admin/")

      expect(tags).to match_array([
        %{<link rel="stylesheet" href="/admin/app.css">},
        %{<script type="module" src="/admin/app.js"></script>},
      ])
    end

    it "leaves absolute and protocol-relative URLs alone" do
      build_index_html(<<~HTML)
        <script src="https://cdn.example.com/analytics.js"></script>
        <script src="//cdn.example.com/protocol-relative.js"></script>
      HTML
      embedding = build_embedding(vite?: true)

      tags = embedding.startup_tags(prepend: "/admin")

      expect(tags).to match_array([
        %{<script src="https://cdn.example.com/analytics.js"></script>},
        %{<script src="//cdn.example.com/protocol-relative.js"></script>},
      ])
    end

    it "reads the tags from Vite's development server when it serves the application" do
      embedding = build_embedding(
        dev_server: dev_server(<<~HTML),
          <html>
            <head>
              <script type="module" src="/@vite/client"></script>
              <link rel="stylesheet" href="/app.css">
            </head>
          </html>
        HTML
      )

      tags = embedding.startup_tags(prepend: "/admin")

      expect(tags).to match_array([
        %{<script type="module" src="http://127.0.0.1:4200/@vite/client"></script>},
        %{<link rel="stylesheet" href="http://127.0.0.1:4200/app.css">},
      ])
    end
  end

describe "#javascript_assets" do
    it "resolves the scripts of `index.html` against the built assets" do
      build_assets_path("bar-abc123.js", "vendor-abc123.js", "not-a-match")
      build_index_html(<<~HTML)
        <script src="bar-abc123.js"></script>
        <script src="vendor-abc123.js"></script>
      HTML
      embedding = build_embedding

      javascripts = embedding.javascript_assets

      expect(javascripts).to match_array([
        "assets/bar-abc123.js",
        "assets/vendor-abc123.js",
      ])
    end

    it "raises a BuildError when the application has not been built" do
      build_assets_path
      embedding = build_embedding

      expect { embedding.javascript_assets }.
        to raise_error(EmberCli::BuildError, /my-app/)
    end

    it "mounts the build's scripts onto `prepend`" do
      build_assets_path("bar-abc123.js")
      build_index_html(%{<script src="bar-abc123.js"></script>})
      embedding = build_embedding

      javascripts = embedding.javascript_assets(prepend: "http://example.com/")

      expect(javascripts).to eq(["http://example.com/assets/bar-abc123.js"])
    end

    it "emits the scripts hosted outside the build as they are" do
      build_assets_path("bar-abc123.js")
      build_index_html(<<~HTML)
        <script src="bar-abc123.js"></script>
        <script src="https://cdn.example.com/analytics.js"></script>
        <script src="//cdn.example.com/protocol-relative.js"></script>
      HTML
      embedding = build_embedding

      javascripts = embedding.javascript_assets(prepend: "http://example.com/")

      expect(javascripts).to match_array([
        "http://example.com/assets/bar-abc123.js",
        "https://cdn.example.com/analytics.js",
        "//cdn.example.com/protocol-relative.js",
      ])
    end

    it "ignores a script that references no asset" do
      build_assets_path("bar-abc123.js")
      build_index_html(<<~HTML)
        <script>window.inline = true</script>
        <script src="bar-abc123.js"></script>
      HTML
      embedding = build_embedding

      javascripts = embedding.javascript_assets

      expect(javascripts).to eq(["assets/bar-abc123.js"])
    end

    it "raises a BuildError when a referenced asset is missing" do
      build_assets_path("vendor-abc123.js")
      build_index_html(%{<script src="bar-abc123.js"></script>})
      embedding = build_embedding

      expect { embedding.javascript_assets }.
        to raise_error(EmberCli::BuildError, /bar-abc123\.js/)
    end

    it "resolves a script nested in the build" do
      build_assets_path("highlight/js/highlight.min.js")
      build_index_html(
        %{<script src="assets/highlight/js/highlight.min.js"></script>},
      )
      embedding = build_embedding

      javascripts = embedding.javascript_assets

      expect(javascripts).to eq(["assets/highlight/js/highlight.min.js"])
    end
  end

  describe "#stylesheet_assets" do
    it "resolves the stylesheets of `index.html` against the built assets" do
      build_assets_path("bar-abc123.css", "vendor-abc123.css")
      build_index_html(<<~HTML)
        <link rel="stylesheet" href="bar-abc123.css">
        <link rel="stylesheet" href="vendor-abc123.css">
      HTML
      embedding = build_embedding

      stylesheets = embedding.stylesheet_assets

      expect(stylesheets).to match_array([
        "assets/bar-abc123.css",
        "assets/vendor-abc123.css",
      ])
    end

    it "resolves the stylesheets nested in the build" do
      build_assets_path(
        "bar-abc123.css",
        "font-awesome/css/font-awesome.min.css",
      )
      build_index_html(<<~HTML)
        <link rel="stylesheet" href="assets/font-awesome/css/font-awesome.min.css">
        <link rel="stylesheet" href="bar-abc123.css">
      HTML
      embedding = build_embedding

      stylesheets = embedding.stylesheet_assets

      expect(stylesheets).to match_array([
        "assets/font-awesome/css/font-awesome.min.css",
        "assets/bar-abc123.css",
      ])
    end

    it "resolves the stylesheets referenced through a `rootURL`" do
      build_assets_path(
        "bar-abc123.css",
        "font-awesome/css/font-awesome.min.css",
      )
      build_index_html(<<~HTML)
        <link rel="stylesheet" href="/my-app/assets/font-awesome/css/font-awesome.min.css">
        <link rel="stylesheet" href="/my-app/assets/bar-abc123.css">
      HTML
      embedding = build_embedding

      stylesheets = embedding.stylesheet_assets

      expect(stylesheets).to match_array([
        "assets/font-awesome/css/font-awesome.min.css",
        "assets/bar-abc123.css",
      ])
    end

    it "prefers the asset whose path matches over one that only shares its basename" do
      build_assets_path("app.css", "font-awesome/css/app.css")
      build_index_html(
        %{<link rel="stylesheet" href="assets/font-awesome/css/app.css">},
      )
      embedding = build_embedding

      stylesheets = embedding.stylesheet_assets

      expect(stylesheets).to eq(["assets/font-awesome/css/app.css"])
    end

    it "emits the stylesheets hosted outside the build as they are" do
      build_assets_path("bar-abc123.css")
      build_index_html(<<~HTML)
        <link rel="stylesheet" href="bar-abc123.css">
        <link rel="stylesheet" href="https://fonts.example.com/css?family=Frontend">
        <link rel="stylesheet" href="//fonts.example.com/protocol-relative.css">
      HTML
      embedding = build_embedding

      stylesheets = embedding.stylesheet_assets(prepend: "http://example.com/")

      expect(stylesheets).to match_array([
        "http://example.com/assets/bar-abc123.css",
        "https://fonts.example.com/css?family=Frontend",
        "//fonts.example.com/protocol-relative.css",
      ])
    end
  end

  def build_embedding(dev_server: nil, **stubs)
    app = instance_double(
      EmberCli::App,
      name: "my-app",
      dist_path: dist,
      dev_server?: !dev_server.nil?,
      dev_server: dev_server,
      vite?: false,
      **stubs,
    )

    EmberCli::Embedding.new(app)
  end

  def build_index_html(head)
    path = dist.join("index.html")

    path.write(<<~HTML)
      <html>
        <head>
          #{head}
        </head>
      </html>
    HTML

    path
  end

  def build_assets_path(*file_names)
    dist.join("assets").tap do |assets|
      assets.mkpath

      file_names.each do |file_name|
        path = assets.join(file_name)

        path.dirname.mkpath
        FileUtils.touch(path)
      end
    end
  end

  def dev_server(index_html = "")
    instance_double(
      EmberCli::DevServer,
      index_html: index_html,
      origin: "http://127.0.0.1:4200",
    )
  end

  def dist
    @dist ||= Pathname.new(Dir.mktmpdir)
  end
end
