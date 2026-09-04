module DevServerHelpers
  # The Vite development server is only available for applications generated
  # with the Vite-based blueprint (`ember-cli >= 6.8`). The dummy application
  # is generated from `EMBER_VERSION`, which also covers older releases.
  def skip_without_vite_blueprint
    unless EmberCli["my-app-dev-server"].paths.vite?
      skip "The development server requires the Vite-based blueprint"
    end
  end

  def dev_server_origin
    EmberCli["my-app-dev-server"].dev_server.origin
  end
end

RSpec.configure do |config|
  config.include DevServerHelpers
end
