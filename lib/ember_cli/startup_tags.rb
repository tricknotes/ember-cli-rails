require "nokogiri"

module EmberCli
  # The tags a Vite-based application (`ember-cli >= 6.8`) needs to boot.
  #
  # Vite builds declare their entry points in `index.html` — the configuration
  # `<meta>` tag, the stylesheet and `modulepreload` links, and the ES module
  # scripts — so extract them from the document, with `prefix` joined onto
  # every root-relative URL.
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

    # Protocol-relative URLs (`//`) address another origin, so leave them alone.
    def prefix_urls(tag)
      URL_ATTRIBUTES.each do |attribute|
        value = tag[attribute]

        if value&.start_with?("/") && !value.start_with?("//")
          tag[attribute] = "#{prefix}#{value}"
        end
      end

      tag
    end
  end
end
