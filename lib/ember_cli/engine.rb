module EmberCli
  class Engine < Rails::Engine
    initializer "ember-cli-rails.setup" do
      require "ember_cli/route_helpers"
    end

    # Rails 7.1 and later manage the deprecators of engines with the
    # application's own, so that `config.active_support.deprecation` applies.
    initializer "ember-cli-rails.deprecator" do |app|
      if app.respond_to?(:deprecators)
        app.deprecators[:ember_cli_rails] = EmberCli.deprecator
      end
    end
  end
end
