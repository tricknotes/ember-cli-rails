require "nokogiri"

require "ember_cli/errors"
require "ember_cli/embedding/url"

module EmberCli
  class Embedding
    class AssetMap
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
      # `assets` directory itself or the application's `rootURL`, so match on the
      # longest trailing path the two agree on rather than on the file name, which
      # an addon's nested asset can share with another file.
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
end
