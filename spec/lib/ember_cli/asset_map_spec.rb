require "fileutils"
require "pathname"
require "tmpdir"
require "ember_cli/asset_map"

describe EmberCli::AssetMap do
  describe "#javascripts" do
    it "resolves the scripts of `index.html` against the built assets" do
      assets_path = build_assets_path("bar-abc123.js", "vendor-abc123.js", "not-a-match")
      index_html = build_index_html(<<~HTML)
        <script src="bar-abc123.js"></script>
        <script src="vendor-abc123.js"></script>
      HTML
      asset_map = build_asset_map(index_html: index_html, assets_path: assets_path)

      javascripts = asset_map.javascripts

      expect(javascripts).to match_array([
        "assets/bar-abc123.js",
        "assets/vendor-abc123.js",
      ])
    end

    it "raises a BuildError when the application has not been built" do
      asset_map = build_asset_map(assets_path: build_assets_path)

      expect { asset_map.javascripts }.
        to raise_error(EmberCli::BuildError, /my-app/)
    end

    it "mounts the build's scripts onto `prepend`" do
      assets_path = build_assets_path("bar-abc123.js")
      index_html = build_index_html(%{<script src="bar-abc123.js"></script>})
      asset_map = build_asset_map(index_html: index_html, assets_path: assets_path)

      javascripts = asset_map.javascripts(prepend: "http://example.com/")

      expect(javascripts).to eq(["http://example.com/assets/bar-abc123.js"])
    end

    it "emits the scripts hosted outside the build as they are" do
      assets_path = build_assets_path("bar-abc123.js")
      index_html = build_index_html(<<~HTML)
        <script src="bar-abc123.js"></script>
        <script src="https://cdn.example.com/analytics.js"></script>
        <script src="//cdn.example.com/protocol-relative.js"></script>
      HTML
      asset_map = build_asset_map(index_html: index_html, assets_path: assets_path)

      javascripts = asset_map.javascripts(prepend: "http://example.com/")

      expect(javascripts).to match_array([
        "http://example.com/assets/bar-abc123.js",
        "https://cdn.example.com/analytics.js",
        "//cdn.example.com/protocol-relative.js",
      ])
    end

    it "ignores a script that references no asset" do
      assets_path = build_assets_path("bar-abc123.js")
      index_html = build_index_html(<<~HTML)
        <script>window.inline = true</script>
        <script src="bar-abc123.js"></script>
      HTML
      asset_map = build_asset_map(index_html: index_html, assets_path: assets_path)

      javascripts = asset_map.javascripts

      expect(javascripts).to eq(["assets/bar-abc123.js"])
    end

    it "raises a BuildError when a referenced asset is missing" do
      assets_path = build_assets_path("vendor-abc123.js")
      index_html = build_index_html(%{<script src="bar-abc123.js"></script>})
      asset_map = build_asset_map(index_html: index_html, assets_path: assets_path)

      expect { asset_map.javascripts }.
        to raise_error(EmberCli::BuildError, /bar-abc123\.js/)
    end

    it "resolves a script nested in the build" do
      assets_path = build_assets_path("highlight/js/highlight.min.js")
      index_html = build_index_html(
        %{<script src="assets/highlight/js/highlight.min.js"></script>},
      )
      asset_map = build_asset_map(index_html: index_html, assets_path: assets_path)

      javascripts = asset_map.javascripts

      expect(javascripts).to eq(["assets/highlight/js/highlight.min.js"])
    end
  end

  describe "#stylesheets" do
    it "resolves the stylesheets of `index.html` against the built assets" do
      assets_path = build_assets_path("bar-abc123.css", "vendor-abc123.css")
      index_html = build_index_html(<<~HTML)
        <link rel="stylesheet" href="bar-abc123.css">
        <link rel="stylesheet" href="vendor-abc123.css">
      HTML
      asset_map = build_asset_map(index_html: index_html, assets_path: assets_path)

      stylesheets = asset_map.stylesheets

      expect(stylesheets).to match_array([
        "assets/bar-abc123.css",
        "assets/vendor-abc123.css",
      ])
    end

    it "resolves the stylesheets nested in the build" do
      assets_path = build_assets_path(
        "bar-abc123.css",
        "font-awesome/css/font-awesome.min.css",
      )
      index_html = build_index_html(<<~HTML)
        <link rel="stylesheet" href="assets/font-awesome/css/font-awesome.min.css">
        <link rel="stylesheet" href="bar-abc123.css">
      HTML
      asset_map = build_asset_map(index_html: index_html, assets_path: assets_path)

      stylesheets = asset_map.stylesheets

      expect(stylesheets).to match_array([
        "assets/font-awesome/css/font-awesome.min.css",
        "assets/bar-abc123.css",
      ])
    end

    it "resolves the stylesheets referenced through a `rootURL`" do
      assets_path = build_assets_path(
        "bar-abc123.css",
        "font-awesome/css/font-awesome.min.css",
      )
      index_html = build_index_html(<<~HTML)
        <link rel="stylesheet" href="/my-app/assets/font-awesome/css/font-awesome.min.css">
        <link rel="stylesheet" href="/my-app/assets/bar-abc123.css">
      HTML
      asset_map = build_asset_map(index_html: index_html, assets_path: assets_path)

      stylesheets = asset_map.stylesheets

      expect(stylesheets).to match_array([
        "assets/font-awesome/css/font-awesome.min.css",
        "assets/bar-abc123.css",
      ])
    end

    it "prefers the asset whose path matches over one that only shares its basename" do
      assets_path = build_assets_path("app.css", "font-awesome/css/app.css")
      index_html = build_index_html(
        %{<link rel="stylesheet" href="assets/font-awesome/css/app.css">},
      )
      asset_map = build_asset_map(index_html: index_html, assets_path: assets_path)

      stylesheets = asset_map.stylesheets

      expect(stylesheets).to eq(["assets/font-awesome/css/app.css"])
    end

    it "emits the stylesheets hosted outside the build as they are" do
      assets_path = build_assets_path("bar-abc123.css")
      index_html = build_index_html(<<~HTML)
        <link rel="stylesheet" href="bar-abc123.css">
        <link rel="stylesheet" href="https://fonts.example.com/css?family=Frontend">
        <link rel="stylesheet" href="//fonts.example.com/protocol-relative.css">
      HTML
      asset_map = build_asset_map(index_html: index_html, assets_path: assets_path)

      stylesheets = asset_map.stylesheets(prepend: "http://example.com/")

      expect(stylesheets).to match_array([
        "http://example.com/assets/bar-abc123.css",
        "https://fonts.example.com/css?family=Frontend",
        "//fonts.example.com/protocol-relative.css",
      ])
    end
  end

  def build_asset_map(index_html: build_index_html(""), assets_path:)
    EmberCli::AssetMap.new(
      name: "my-app",
      index_html: index_html,
      assets_path: assets_path,
    )
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

  def dist
    @dist ||= Pathname.new(Dir.mktmpdir)
  end
end
