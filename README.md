# Ember CLI Rails

Unify your EmberCLI and Rails Workflows!

EmberCLI-Rails is designed to give you the best of both worlds:

* Stay up to date with the latest JavaScript technology and EmberCLI addons
* Develop your Rails API and Ember front-ends from within a single process
* Inject Rails-generated content into your EmberCLI application
* Avoid Cross-Origin Resource Sharing gotchas by serving your EmberCLI
  applications and your API from a single domain
* Write truly end-to-end integration tests, exercising your application's entire
  stack through JavaScript-enabled Capybara tests
* Deploy your entire suite of applications to Heroku with a single `git push`

If you're having trouble, checkout the [example project]!

**EmberCLI-Rails Supports EmberCLI 1.13.13 and later.**

[example project]: https://github.com/seanpdoyle/ember-cli-rails-heroku-example

## Install

Add the following to your `Gemfile`:

```ruby
gem "ember-cli-rails"
```

Then run `bundle install`:

```bash
$ bundle install
```

If you haven't created an Ember application yet, generate a new one:

```bash
$ ember new frontend --skip-git
```

## Setup

First, generate the gem's initializer:

```bash
$ rails generate ember:init
```

This will create the following initializer:

```ruby
# config/initializers/ember.rb

EmberCli.configure do |c|
  c.app :frontend
end
```

This initializer assumes that your Ember application exists in
`Rails.root.join("frontend")`.

If this is not the case, you could

* move your existing Ember application into `Rails.root.join("frontend")`
* configure `frontend` to reference the Ember application in its current
  directory:

```rb
c.app :frontend, path: "~/projects/my-ember-app"
```

**Initializer options**

- `name` - this represents the name of the Ember CLI application.

- `path` - the path where your Ember CLI application is located. The default
  value is the name of your app in the Rails root.

- `silent` - this provides `--silent` option for Ember CLI commands to control verbosity of their output.

- `yarn` - enables the [yarn](https://github.com/yarnpkg/yarn) package manager when installing dependencies

- `dev_server` - configures [Vite's development server](#vite-based-applications)
  for Vite-based applications in `development`. Pass `false` to opt out of it,
  or a Hash of `host`, `port`, and `timeout` settings.

```ruby
EmberCli.configure do |c|
  c.app :adminpanel # path defaults to `Rails.root.join("adminpanel")`
  c.app :frontend,
    path: "/path/to/your/ember-cli-app/on/disk"
  c.app :payments, silent: true # by default it's false
end
```

Next, if your Ember application uses the classic (Broccoli-based) build
(generated with `ember-cli < 6.8`), install the [ember-cli-rails-addon][addon]:

```bash
$ cd path/to/frontend
$ ember install ember-cli-rails-addon
```

Be sure that the addon's [`MAJOR` and `MINOR` version][semver] matches the gem's
`MAJOR` and `MINOR` versions.

For instance, if you're using the `0.6.x` version of the gem, specify
`~> 0.6.0` in your Ember app's `package.json`:

```json
{
  "devDependencies": {
    "ember-cli-rails-addon": "~> 0.6.0"
  }
}
```

If your Ember application uses the Vite-based build (generated with
`ember-cli >= 6.8`), do **not** install the addon: it is incompatible with the
Vite-based build, and `ember-cli-rails` does not require it there.

[addon]: https://github.com/rondale-sc/ember-cli-rails-addon/
[semver]: http://semver.org/

## Mount

Configure Rails to route requests to the `frontend` Ember application:

```rb
# config/routes.rb

Rails.application.routes.draw do
  mount_ember_app :frontend, to: "/"
end
```

**Routing options**

* `to` - The path to handle as an Ember application. This will only apply to
  `format: :html` requests. Additionally, this will handle child routes as well.
  For instance, mounting `mount_ember_app :frontend, to: "/frontend"` will handle a
  `format: :html` request to `/frontend/posts`.
  *Note:* If you specify a custom path, you must also update the `rootURL` in `frontend/config/environment.js`. See [Mounting multiple Ember applications](#mounting-multiple-ember-applications) for more information.
* `controller` - Defaults to `"ember_cli/ember"`
* `action` - Defaults to `"index"`

Finally, install your Ember application's dependencies:

```bash
$ rake ember:install
```

Boot your Rails application, navigate to `"/"`, and view your EmberCLI
application!

## Develop

EmberCLI Rails exposes several useful rake tasks.

**`ember:install`**

Install the Ember applications' dependencies.

**`ember:compile`**

Compile the Ember applications.

**`ember:test`**

Execute Ember's test suite.

If you're using Rake to run the test suite, make sure to configure your test
task to depend on `ember:test`.

For example, to configure a bare `rake` command to run both RSpec and Ember test
suites, configure the `default` task to depend on both `spec` and `ember:test`.

```rb
task default: [:spec, "ember:test"]
```

### Vite-based applications

When Rails is running in development mode, classic (Broccoli-based) Ember
applications are built with `ember build --watch`, so changes to the Ember
application are picked up automatically.

Vite-based Ember applications (generated with `ember-cli >= 6.8`) are served by
Vite's own development server instead — the same one the application's
`npm start` script runs. `ember-cli-rails` starts it on the first request,
waits for it to accept connections, and shuts it down when Rails exits.

Rails still renders the application's `index.html`, but reads it from the
development server rather than from disk. The root-relative URLs in that
document are rewritten to point at the development server, so the browser
loads the application's modules — and Vite's HMR client — from it directly.
Changes to the Ember application are hot-reloaded without reloading the page,
and without restarting Rails.

Assets that the Ember application references relatively (an `<img>` in a
template, for instance) are still requested from Rails, which proxies them to
the development server.

**Configuring the development server**

By default the development server listens on an available port on `127.0.0.1`,
and `ember-cli-rails` waits up to 30 seconds for it to start:

```rb
EmberCli.configure do |c|
  c.app :frontend, dev_server: { host: "127.0.0.1", port: 4200, timeout: 60 }
end
```

If something is already listening on the configured `host` and `port`,
`ember-cli-rails` uses it instead of starting a second server. That makes it
possible to run `npm start` yourself, on a port the initializer names, and have
Rails serve the application from it.

`host` is both the address the development server binds to and — together with
`port` — the origin the browser loads the application's modules from. When the
two differ, configure the browser-facing origin separately with `origin`. The
typical case is Rails running in a container: the development server must bind
to `0.0.0.0` to be reachable through the container's published port, but
browsers refuse to connect to `http://0.0.0.0`:

```rb
EmberCli.configure do |c|
  c.app :frontend, dev_server: {
    host: "0.0.0.0",
    port: 4200,
    origin: "http://localhost:4200",
  }
end
```

With `host: "0.0.0.0"`, Rails itself reaches the development server through the
loopback interface.

The development server's output is written to
`log/ember-<app>.<environment>.log`.

**Opting out**

To build the application once, synchronously, on the first request instead of
running a development server, disable it:

```rb
EmberCli.configure do |c|
  c.app :frontend, dev_server: false
end
```

Changes to the Ember application are then only picked up by restarting the
Rails server.

The development server is only used in `development`. `test` and `production`
are served from the output of `ember build`, as they always have been.

## Deploy

When Rails is running in production mode, EmberCLI-Rails stops doing runtime
compilation. Instead, configured apps are built during `rake assets:precompile`.
This keeps things quick for end users, and extends the normal Rails asset
building process.

Configuration information, including instructions for Heroku and Capistrano,
can be found below.

### CDN

In production environments, assets should be served over a
Content Delivery Network.

Configuring an `ember-cli-rails` application to serve Ember's assets over a CDN
is very similar to [configuring an EmberCLI application to serve assets over a
CDN][ember-cli-cdn]:

[ember-cli-cdn]: http://ember-cli.com/user-guide/#fingerprinting-and-cdn-urls

```js
var app = new EmberApp({
  fingerprint: {
    prepend: 'https://cdn.example.com/'
  }
});
```

If you're serving the Ember application from a path other than `"/"`, the
`prepend` URL must end with the mounted path:

```js
var app = new EmberApp({
  fingerprint: {
    // for an Ember application mounted to `/admin_panel/`
    prepend: 'https://cdn.example.com/admin_panel/',
  }
});
```

As long as your [CDN is configured to pull from your Rails application][dns-cdn]
, your assets will be served over the CDN.

[dns-cdn]: https://robots.thoughtbot.com/dns-cdn-origin

### Deployment Strategies

By default, EmberCLI-Rails uses a file-based deployment strategy that depends on
the output of `ember build`.

Using this deployment strategy, Rails will serve the `index.html` file and other
assets that `ember build` produces.

These EmberCLI-generated assets are served with the same `Cache-Control` headers
as Rails' other static files:

```rb
# config/environments/production.rb
Rails.application.configure do
  # serve static files with cache headers set to expire in 1 year
  config.static_cache_control = "public, max-age=31622400"
end
```

If you need to override this behavior (for instance, if you're using
[`ember-cli-deploy`'s "Lightning Fast Deployment"][lightning] strategy in
`production`), you can specify the strategy's class in the initializer:

```rb
EmberCli.configure do |config|
  config.app :frontend, deploy: { production: EmberCli::Deploy::Redis }
end
```

This example configures the `frontend` Ember application to retrieve the
index's HTML from an [`ember-cli-deploy-redis`][ember-cli-deploy-redis]
-populated Redis entry using the
[`ember-cli-rails-deploy-redis`][ember-cli-rails-deploy-redis] gem.

If you're deploying HTML with a custom strategy in `development` or `test`,
disable EmberCLI-Rails' build step by setting `ENV["SKIP_EMBER"] = true`.

**NOTE:**

Specifying a deployment strategy is only supported for applications that use the
`mount_ember_app` and `render_ember_app` helpers.

[ember-cli-deploy-redis]: https://github.com/ember-cli-deploy/ember-cli-deploy-redis
[ember-cli-rails-deploy-redis]: https://github.com/seanpdoyle/ember-cli-rails-deploy-redis
[lightning]: https://github.com/ember-cli-deploy/ember-cli-deploy-lightning-pack

### Heroku

To configure your EmberCLI-Rails applications for Heroku:

1. Execute `rails generate ember:heroku`.
1. Commit the newly generated files.
1. [Add the NodeJS buildpack][buildpack] and configure NPM to include the
   `bower` dependency's executable file (if your build process requires
   `bower`).

```sh
$ heroku buildpacks:clear
$ heroku buildpacks:add --index 1 heroku/nodejs
$ heroku buildpacks:add --index 2 heroku/ruby
$ heroku config:unset SKIP_EMBER
```

You are ready to deploy:

```bash
$ git push heroku master
```

EmberCLI compilation happens at deploy-time, triggered by the `asset:precompile` rake task.

**NOTE** Run the generator each time you introduce additional EmberCLI
applications into the project.

[buildpack]: https://devcenter.heroku.com/articles/using-multiple-buildpacks-for-an-app#adding-a-buildpack

#### Slug size

[Heroku slug size is limited](https://devcenter.heroku.com/articles/slug-compiler#slug-size). The build process creates artifacts that are not necessary for the server to run, but are included in the deployed Heroku slug.

Omitting these build assets can dramatically reduce slug size.

A build-pack solution for this is discussed in [Issue #491][#491].

[#491]: https://github.com/tricknotes/ember-cli-rails/issues/491

### Capistrano

EmberCLI-Rails executes both `npm install` and `bower install` during EmberCLI's
compilation, triggered by the  `asset:precompile` rake task.

The `npm` and `bower` executables are required to be defined in the deployment
SSH session's `$PATH`. It is not sufficient to modify the session's `$PATH` in
a `.bash_profile`.

To resolve this issue, prepend the Node installation's `bin` directory to the
target system's `$PATH`:

```ruby
#config/deploy/production.rb

set :default_env, {
  "PATH" => "/home/deploy/.nvm/versions/node/v4.2.1/bin:$PATH"
}
```

The system in this example is using `nvm` to configure the node version. If
you're not using `nvm`, make sure the string you prepend to the `$PATH` variable
contains the directory or directories that contain the `bower` and `npm`
executables.

#### For faster deployments

Place the following in your `deploy/<environment>.rb`

```ruby
set :linked_dirs, %w{<ember-app-name>/node_modules <ember-app-name>/bower_components}
```

to avoid rebuilding all the node modules and bower components with every deploy.
Replace `<ember-app-name>` with the name of your ember app (default is
`frontend`).

## Override

By default, routes defined by `ember_app` will be rendered with the internal
`EmberCli::EmberController`.

### Overriding the view

The `EmberCli::EmberController` renders the Ember application's `index.html` and
injects the Rails-generated CSRF tags into the `<head>`.

To customize the view, create `app/views/ember_cli/ember/index.html.erb`:

```erb
<%= render_ember_app ember_app do |head| %>
  <% head.append do %>
    <%= csrf_meta_tags %>
  <% end %>
<% end %>
```

The `ember_app` helper is available within the `EmberCli::EmberController`'s
view, and refers to the name of the current EmberCLI application.

To inject the EmberCLI generated `index.html`, use the `render_ember_app`
helper in your view:

```erb
<!-- app/views/application/index.html.erb -->
<%= render_ember_app :frontend do |head, body| %>
  <% head.append do %>
    <%= csrf_meta_tags %>
  <% end %>

  <% body.append do %>
    <%= render partial: "my-analytics" %>
  <% end %>
<% end %>
```

The `body` block argument and the corresponding call to `body.append` in the
example are both optional, and can be omitted.

### Serving Rails-generated CSS

For more information on how to work with EmberCLI-generated stylesheets, refer
to the [Stylesheets section][ember-cli-css]. EmberCLI-generated CSS  will be
embedded in the response's HTML document by default.

To serve assets generated and served by Rails, inject them into the document's
`<head>`:

```erb
<%= render_ember_app :frontend do |head| %>
  <% head.append do %>
    <%= stylesheet_link_tag "application" %>
    <%= csrf_meta_tags %>
  <% end %>
<% end %>
```

There are no technical limitations to sharing assets between the Ember client
and the Rails server, but picking one or the other might simplify the project's
organization.

Sharing code during asset compilation is __not__ possible.

For example, Ember's SCSS files __cannot__ use `@import` directives referencing
Rails' SCSS modules.

[ember-cli-css]: http://ember-cli.com/user-guide/#stylesheets

### Overriding the controller

To override this behavior, you can specify [any of Rails' routing options]
[route-options].

[route-options]: http://api.rubyonrails.org/classes/ActionDispatch/Routing/Mapper/Base.html#method-i-match

For the sake of this example, override the `controller` and `action` options:

```rb
# config/routes.rb

Rails.application.routes.draw do
  mount_ember_app :frontend, to: "/", controller: "application", action: "index"
end
```

When serving the EmberCLI generated `index.html` with the `render_ember_app`
helper, make sure the controller's `layout` is disabled, as EmberCLI generates a
fully-formed HTML document:

```rb
# app/controllers/application.rb
class ApplicationController < ActionController::Base
  def index
    render layout: false
  end
end
```

### Rendering the EmberCLI generated JS and CSS

Rendering EmberCLI applications with `render_ember_app` is the recommended,
actively supported method of serving EmberCLI applications.

However, for the sake of backwards compatibility, `ember-cli-rails` supports
injecting the EmberCLI-generated assets into an existing Rails layout.

**Note:** for Vite-based applications (generated with `ember-cli >= 6.8`),
use `include_ember_script_tags` on its own. It emits everything the
application needs to boot — the configuration `<meta>` tag, the stylesheet
and `modulepreload` links, and the ES module script tags — extracted from
the generated `index.html`. `include_ember_stylesheet_tags` only supports
classic (Broccoli-based) applications.

When the application is served by [Vite's development
server](#vite-based-applications), `include_ember_script_tags` (from
[ember-cli-rails-assets]) reads `index.html` from the server and emits the
startup tags with absolute URLs pointing at it — nothing is built, and changes
to the application are picked up by reloading the page.

With the development server disabled (`dev_server: false`), the helpers read
the output of `ember build` instead: the application is built once,
synchronously, on the first request, and changes to it are only picked up by
restarting the Rails server.

Following the example above, configure the mounted EmberCLI application to be
served by a custom controller (`ApplicationController`, in this case).

In the corresponding view, use the asset helpers:

```erb
<%= include_ember_script_tags :frontend %>
<%= include_ember_stylesheet_tags :frontend %>
```

### Mounting multiple Ember applications

Rendering Ember applications to paths other than `/` requires additional
configuration.

Consider a scenario where you had Ember applications named `frontend` and
`admin_panel`, served from `/` and `/admin_panel` respectively.

First, specify the Ember applications in the initializer:

```ruby
EmberCli.configure do |c|
  c.app :frontend
  c.app :admin_panel, path: "path/to/admin_ember_app"
end
```

Next, mount the applications alongside the rest of Rails' routes. Note that `admin_panel` route is added before the `frontend` route because it's more specific:

```rb
# /config/routes.rb
Rails.application.routes.draw do
  mount_ember_app :admin_panel, to: "/admin_panel"
  mount_ember_app :frontend, to: "/"
end
```

Then set each Ember application's `rootURL` to the mount point:

```javascript
// frontend/config/environment.js

module.exports = function(environment) {
  var ENV = {
    modulePrefix: 'frontend',
    environment: environment,
    rootURL: '/',
    // ...
  }
};

// path/to/admin_ember_app/config/environment.js

module.exports = function(environment) {
  var ENV = {
    modulePrefix: 'admin_panel',
    environment: environment,
    rootURL: '/admin_panel',  // originally '/'
    // ...
  }
};
```

Finally, configure EmberCLI's fingerprinting to prepend the mount point to the
application's assets:

```js
// frontend/ember-cli-build.js

module.exports = function(defaults) {
  var app = new EmberApp(defaults, {
    fingerprint: {
      // matches the `/` mount point
      prepend: 'https://cdn.example.com/',
    }
  });
};


// path/to/admin_ember_app/ember-cli-build.js

module.exports = function(defaults) {
  var app = new EmberApp(defaults, {
    fingerprint: {
      // matches the `/admin_panel` mount point
      prepend: 'https://cdn.example.com/admin_panel/',
    }
  });
};
```

When injecting the EmberCLI-generated assets with the `include_ember_script_tags`
and `include_ember_stylesheet_tags` helpers to a path other than `"/"`, a
`<base>` tag must also be injected with a corresponding `href` value:

```erb
<base href="/">
<%= include_ember_script_tags :frontend %>
<%= include_ember_stylesheet_tags :frontend %>

<base href="/admin_panel/">
<%= include_ember_script_tags :admin_panel %>
<%= include_ember_stylesheet_tags :admin_panel %>
```

If you're using the `include_ember` style helpers with a single-page Ember
application that defers routing to the Rails application, insert a call to
`mount_ember_assets` at the bottom of your routes file to serve the
EmberCLI-generated assets:

```rb
# config/routes.rb
Rails.application.routes.draw do
  mount_ember_assets :frontend, to: "/"
end
```

## CSRF Tokens

Your Rails controllers, by default, expect a valid authenticity token to
be submitted along with non-`GET` requests.

Without the authenticity token, requests will respond with
`422 Unprocessable Entity` errors (specifically
`ActionController::InvalidAuthenticityToken`).

To add the necessary tokens to requests, inject the `csrf_meta_tags` into
the template:

```erb
<!-- app/views/application/index.html.erb -->
<%= render_ember_app :frontend do |head| %>
  <% head.append do %>
    <%= csrf_meta_tags %>
  <% end %>
<% end %>
```

The default `EmberCli::EmberController` and the default view handle behave like
this by default.

If an Ember application is mounted with another controller, it should append
the CSRF tags to its view's `<head>`.

[ember-cli-rails-addon][addon] configures your Ember application to make HTTP
requests with the injected CSRF tokens in the `X-CSRF-TOKEN` header.

## Serving from multi-process servers in development

If you're using a multi-process server ([Puma], [Unicorn], etc.) in development,
make sure it's configured to run a single worker process.

Without restricting the server to a single process, [it is possible for multiple
EmberCLI runners to clobber each others' work][#94].

This does not apply to Vite-based applications served by [Vite's development
server](#vite-based-applications): nothing is written to a shared build
directory. Give the application a fixed `port` so that the workers share a
single development server rather than starting one each.

[Puma]: https://github.com/puma/puma
[Unicorn]: https://rubygems.org/gems/unicorn
[#94]: https://github.com/tricknotes/ember-cli-rails/issues/94#issuecomment-77627453

## `SKIP_EMBER`

If set on the environment, `SKIP_EMBER` will configure `ember-cli-rails` to skip
the build step entirely. This is useful if you're using an alternative
deployment strategy in the `test` or `development` environment. By default,
`ember-cli-rails` will skip the build step in `production`-like environments.

## `EMBER_ENV`

If set on the environment, the value of `EMBER_ENV` will be passed to the
`ember` process as the value of the `--environment` flag.

If `EMBER_ENV` is unspecified, the current Rails environment will be passed to
the `ember` process, with the exception of non-standard Rails environments,
which will be replaced with `production`.

## `RAILS_ENV`

While being managed by EmberCLI Rails, EmberCLI process will have
access to the `RAILS_ENV` environment variable. This can be helpful to detect
the Rails environment from within the EmberCLI process.

This can be useful to determine whether or not EmberCLI is running in its own
standalone process or being managed by Rails.

For example, to enable [ember-cli-mirage][ember-cli-mirage] API responses in
`development` while being run outside of Rails (while run by `ember serve`),
check for the absence of the `RAILS_ENV` environment variable:

```js
// config/environment.js
if (environment === 'development') {
  ENV['ember-cli-mirage'] = {
    enabled: typeof process.env.RAILS_ENV === 'undefined',
  }
}
```

`RAILS_ENV` will be absent in production builds.

[ember-cli-mirage]: http://ember-cli-mirage.com/docs/latest/

## EmberCLI support

This project supports:

* EmberCLI versions `>= 1.13.13` using the classic (Broccoli-based) build,
  together with [ember-cli-rails-addon][addon]
* EmberCLI versions `>= 6.8` using the Vite-based build, without the addon

The test suite currently exercises the `5.12.x` and `6.7.x` (classic) and
`7.0.x` (Vite) series.

Note the following limitations for Vite-based applications:

* `include_ember_script_tags` emits the full set of tags the application
  needs to boot, stylesheets included; `include_ember_stylesheet_tags` is
  classic-only and must not be called for Vite-based applications
* in development, the application is served by [Vite's development
  server](#vite-based-applications) rather than out of a build directory. The
  asset helpers serve their tags from the development server too; with
  `dev_server: false` they read the build output, which is built once,
  synchronously, on the first request

## Ruby and Rails support

This project supports:

* Ruby versions `>= 2.5.0`
* Rails versions `>=5.2.x`.

To learn more about supported versions and upgrades, read the [upgrading guide].

[upgrading guide]: /UPGRADING.md

## Contributing

See the [CONTRIBUTING] document.
Thank you, [contributors]!

  [CONTRIBUTING]: CONTRIBUTING.md
  [contributors]: https://github.com/tricknotes/ember-cli-rails/graphs/contributors

## License

Open source templates are Copyright (c) 2015 thoughtbot, inc.
It contains free software that may be redistributed
under the terms specified in the [LICENSE] file.

[LICENSE]: /LICENSE.txt

## About

ember-cli-rails was originally created by
[Pavel Pravosud][rwz] and
[Jonathan Jackson][rondale-sc].

ember-cli-rails is maintained by [Sean Doyle][seanpdoyle], [Jonathan
Jackson][rondale-sc] and [Ryunosuke Sato][tricknotes].

[rwz]: https://github.com/rwz
[rondale-sc]: https://github.com/rondale-sc
[seanpdoyle]: https://github.com/seanpdoyle
[tricknotes]: https://github.com/tricknotes
