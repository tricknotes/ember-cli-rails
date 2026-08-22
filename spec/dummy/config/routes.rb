Rails.application.routes.draw do
  with_options controller: "high_voltage/pages", action: "show" do |app|
    app.mount_ember_app(
      "my-app",
      to: "/no-block",
      id: "include_index",
      as: "include_index",
    )

    app.mount_ember_app(
      "my-app",
      to: "/empty-block",
      id: "include_index_empty_block",
      as: "include_index_empty_block",
    )

    app.mount_ember_app(
      "my-app",
      to: "/head-and-body-block",
      id: "include_index_head_and_body",
      as: "include_index_head_and_body",
    )

    app.mount_ember_app(
      "my-app",
      to: "/asset-helpers",
      id: "embedded",
      as: "embedded",
    )
  end

  mount_ember_app(
    "my-app-dev-server",
    to: "/dev-server",
    # `get "/dev-server"` already claims the `dev_server` route name.
    as: "dev_server_app",
  )

  mount_ember_app(
    "my-app",
    to: "/",
    as: "default",
  )
end
