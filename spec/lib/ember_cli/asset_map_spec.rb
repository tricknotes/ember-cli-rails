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

    it "raises a BuildError when a referenced asset is missing" do
      assets_path = build_assets_path("vendor-abc123.js")
      index_html = build_index_html(%{<script src="bar-abc123.js"></script>})
      asset_map = build_asset_map(index_html: index_html, assets_path: assets_path)

      expect { asset_map.javascripts }.
        to raise_error(EmberCli::BuildError, /bar-abc123\.js/)
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

      file_names.each { |file_name| FileUtils.touch(assets.join(file_name)) }
    end
  end

  def dist
    @dist ||= Pathname.new(Dir.mktmpdir)
  end
end
