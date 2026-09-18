require "nokogiri"

require "ember_cli/errors"
require "ember_cli/url"

module EmberCli
  # The assets a classic (Broccoli-based) build boots from.
  #
  # The generated `index.html` refers to the assets it produced by their
  # fingerprinted file names, so resolve every such reference against the files
  # `ember build` wrote to the `assets` directory, and mount it onto `prepend`.
  # It may also point at assets the build does not produce, which are emitted
  # as they are.
  class AssetMap
    # `broccoli-asset-rev` fingerprints the assets into a directory of their
    # own, which is served alongside `index.html`.
    PREPEND = "assets/".freeze

    def initialize(name:, index_html:, assets_path:)
      @name = name
      @index_html = index_html
      @assets_path = assets_path
    end

    def javascripts(prepend: "")
      assets_referenced_by("script", "src", prepend)
    end

    def stylesheets(prepend: "")
      assets_referenced_by(%{link[rel="stylesheet"]}, "href", prepend)
    end

    private

    attr_reader :name, :index_html, :assets_path

    def assets_referenced_by(selector, attribute, prepend)
      assert_built!

      document.css(selector).filter_map do |tag|
        asset_for(tag[attribute], prepend)
      end
    end

    def document
      @document ||= Nokogiri::HTML(index_html.read)
    end

    # An asset hosted outside the build (a CDN, a font service) has no file to
    # resolve against, and `prepend` mounts the build output, so its URL is
    # emitted untouched.
    # A tag carrying no URL at all (an inline `<script>`) references no asset.
    def asset_for(url, prepend)
      if url.to_s.empty?
        nil
      elsif Url.remote?(url)
        url
      else
        [prepend, asset_matching(File.basename(url))].join
      end
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
