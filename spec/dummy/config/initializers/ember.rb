EmberCli.configure do |c|
  c.app "my-app"

  # The same Ember application, served by Vite's development server.
  #
  # The development server is only selected by default for Vite-based
  # applications in `development`, and the suite runs in `test`, so ask for
  # the strategy explicitly. Booting Vite is slower than opening a socket, so
  # allow more time than the default for it to start listening.
  c.app "my-app-dev-server",
    path: "my-app",
    deploy: { test: EmberCli::Deploy::DevServer },
    dev_server: { timeout: 120 }
end
