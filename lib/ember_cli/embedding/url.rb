module EmberCli
  class Embedding
    module Url
      # A scheme (`https://example.com/app.css`, `data:…`), or a protocol-relative
      # URL (`//example.com/app.css`).
      REMOTE = %r{\A(?:[a-zA-Z][a-zA-Z0-9+.\-]*:|//)}

      def self.remote?(url)
        REMOTE.match?(url.to_s)
      end
    end
  end
end
