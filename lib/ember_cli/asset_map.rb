require "nokogiri"

require "ember_cli/errors"
require "ember_cli/url"

module EmberCli
  # The assets a classic (Broccoli-based) build boots from.
  #
  # The generated `index.html` refers to the assets it produced by their path
  # within the build, so resolve every such reference against the files
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
        [prepend, asset_matching(url)].join
      end
    end

    # A reference carries directories the build output does not, such as the
    # `assets` directory itself or the application's `rootURL`, so resolve it by
    # the longest trailing path the document and the build output agree on.
    # Matching on the file name alone would resolve an asset an addon ships in a
    # subdirectory to whichever file happens to share its basename.
    def asset_matching(url)
      asset = path_suffixes(url).find { |suffix| file_paths.include?(suffix) }

      unless asset
        fail BuildError, "Failed to find a built asset matching `#{url}`"
      end

      PREPEND + asset
    end

    def path_suffixes(url)
      segments = url.split("/").reject(&:empty?)

      segments.each_index.map { |index| segments[index..].join("/") }
    end

    # Every file in the `assets` directory, by its path within it, so that the
    # assets nested in it are represented too.
    def file_paths
      @file_paths ||= if assets_path.directory?
                        assets_path.glob("**/*", File::FNM_DOTMATCH).
                          select(&:file?).
                          map { |path| path.relative_path_from(assets_path).to_s }
                      else
                        []
                      end
    end

    def assert_built!
      if file_paths.empty?
        fail BuildError, <<~MSG
          Missing built assets for #{name.inspect} in `#{assets_path}`.

          Build the application before rendering its assets.
        MSG
      end
    end
  end
end
