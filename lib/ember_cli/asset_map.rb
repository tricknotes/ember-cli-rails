require "nokogiri"

require "ember_cli/errors"

module EmberCli
  # The assets a classic (Broccoli-based) build boots from.
  #
  # The generated `index.html` refers to its assets by their fingerprinted file
  # names, so resolve every reference against the files `ember build` wrote to
  # the `assets` directory.
  class AssetMap
    # `broccoli-asset-rev` fingerprints the assets into a directory of their
    # own, which is served alongside `index.html`.
    PREPEND = "assets/".freeze

    def initialize(name:, index_html:, assets_path:)
      @name = name
      @index_html = index_html
      @assets_path = assets_path
    end

    def javascripts
      assets_referenced_by("script", "src")
    end

    def stylesheets
      assets_referenced_by(%{link[rel="stylesheet"]}, "href")
    end

    private

    attr_reader :name, :index_html, :assets_path

    def assets_referenced_by(selector, attribute)
      assert_built!

      document.css(selector).map do |tag|
        asset_matching(File.basename(tag[attribute].to_s))
      end
    end

    def document
      Nokogiri::HTML(index_html.read)
    end

    def asset_matching(file_name)
      pattern = /#{Regexp.escape(file_name)}\z/
      asset = file_names.detect { |candidate| candidate =~ pattern }

      if asset.nil?
        fail BuildError, "Failed to find a built asset matching `#{file_name}`"
      end

      PREPEND + asset
    end

    def file_names
      @file_names ||= if assets_path.directory?
                        assets_path.children.map { |path| path.basename.to_s }
                      else
                        []
                      end
    end

    def assert_built!
      if file_names.empty?
        fail BuildError, <<~MSG
          Missing built assets for #{name.inspect} in `#{assets_path}`.

          Build the application before rendering its assets.
        MSG
      end
    end
  end
end
