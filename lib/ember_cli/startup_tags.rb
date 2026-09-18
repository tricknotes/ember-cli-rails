require "nokogiri"

require "ember_cli/url"

module EmberCli
  class StartupTags
    SELECTOR = [
      %{meta[name$="/config/environment"]},
      %{link[rel="stylesheet"]},
      %{link[rel="modulepreload"]},
      "script",
    ].join(", ").freeze

    URL_ATTRIBUTES = %w(href src).freeze

    def initialize(html, prefix: "")
      @html = html
      @prefix = prefix.to_s.chomp("/")
    end

    def to_a
      Nokogiri::HTML5(html).css(SELECTOR).map { |tag| prefix_urls(tag).to_html }
    end

    private

    attr_reader :html, :prefix

    # Only a root-relative URL points into what this application serves, so a
    # URL that resolves elsewhere is left alone.
    def prefix_urls(tag)
      URL_ATTRIBUTES.each do |attribute|
        value = tag[attribute]

        if value&.start_with?("/") && !Url.remote?(value)
          tag[attribute] = "#{prefix}#{value}"
        end
      end

      tag
    end
  end
end
