require "ember_cli/dev_server_proxy"
require "ember_cli/errors"

module EmberCli
  module Deploy
    # Serves an Ember application from its Vite development server instead of
    # from the `dist` directory written by `ember build`.
    #
    # The `index.html` served by the development server refers to its assets
    # (`/@vite/client` included) with root-relative URLs. Rails serves the
    # document from its own origin, so those URLs are rewritten to absolute
    # URLs pointing at the development server. Loading them from there means
    # the Vite client opens its HMR WebSocket against the development server
    # directly, without Rails proxying it.
    class DevServer
      ROOT_RELATIVE_URL = %r{(\s)(src|href)=(["'])/(?!/)}i

      def initialize(app)
        @app = app
      end

      def mountable?
        true
      end

      def to_rack
        DevServerProxy.new(app)
      end

      def index_html
        rewrite_root_relative_urls(dev_server.index_html)
      end

      private

      attr_reader :app

      delegate :dev_server, to: :app

      def rewrite_root_relative_urls(html)
        html.gsub(ROOT_RELATIVE_URL) do
          "#{$1}#{$2}=#{$3}#{dev_server.origin}/"
        end
      end
    end
  end
end
