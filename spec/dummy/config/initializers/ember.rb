EmberCli.configure do |c|
  c.app "my-app"

  # The same Ember application, served by Vite's development server.
  #
  # The development server is only selected by default for Vite-based
  # applications in `development`, and the suite runs in `test`, so ask for
  # the strategy explicitly. Booting Vite is slower than opening a socket, so
  # allow more time than the default for it to start listening.
  #
  # The app is a copy (made by `bin/setup_ember`) rather than `my-app`
  # itself: the `ember build` and `ember test` runs against `my-app` would
  # otherwise leak their prebuild and cache output into the running server,
  # which then serves the test-environment config, whose `autoboot: false`
  # leaves the page blank.
  c.app "my-app-dev-server",
    path: "my-app-dev-server",
    deploy: { test: EmberCli::Deploy::DevServer },
    dev_server: { timeout: 120 }
end
