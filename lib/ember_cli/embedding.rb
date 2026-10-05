require "ember_cli/embedding/asset_map"
require "ember_cli/embedding/startup_tags"
require "ember_cli/embedding/url"

module EmberCli
  class Embedding
    private_constant :AssetMap, :StartupTags, :Url

    def initialize(app)
      @app = app
    end

    def startup_tags?
      app.dev_server? || app.vite?
    end

    def startup_tags(prepend: "")
      if app.dev_server?
        StartupTags.new(app.dev_server.index_html, prefix: app.dev_server.origin).to_a
      else
        StartupTags.new(index_html.read, prefix: prepend).to_a
      end
    end

    def javascript_assets(prepend: "")
      asset_map.javascripts(prepend: prepend)
    end

    def stylesheet_assets(prepend: "")
      asset_map.stylesheets(prepend: prepend)
    end

    private

    attr_reader :app

    def asset_map
      AssetMap.new(
        name: app.name,
        index_html: index_html,
        assets_path: app.dist_path.join("assets"),
      )
    end

    def index_html
      app.dist_path.join("index.html")
    end
  end
end
