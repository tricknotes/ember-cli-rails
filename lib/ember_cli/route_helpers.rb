require "ember_cli/ember_constraint"
require "ember_cli/trailing_slash_constraint"

module ActionDispatch
  module Routing
    class Mapper
      def mount_ember_app(app_name, to:, **options)
        routing_options = options.deep_merge(
          defaults: { ember_app: app_name, ember_mount_point: to },
        )

        routing_options.reverse_merge!(
          controller: "ember_cli/ember",
          action: "index",
          format: :html,
        )

        scope constraints: ::EmberCli::EmberConstraint.new do
          redirect_if_missing_trailing_slash = {
            constraints: EmberCli::TrailingSlashConstraint.new,
            to: redirect(-> (_, request) {
              File.join(request.path, "/?#{request.query_parameters.to_query}")
            }),
          }

          get(to, **redirect_if_missing_trailing_slash)
          get(File.join(to, "(*rest)"), **routing_options)
        end

        mount_ember_assets(app_name, to: to)
      end

      def mount_ember_assets(app_name, to: "/")
        app = ::EmberCli[app_name]

        if app.mountable?
          mount app.to_rack, at: to
        end
      end
    end
  end
end
