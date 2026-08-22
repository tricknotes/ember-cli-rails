# EmberCLI support

`ember-cli >= 6.8` generates applications that are built with [Vite] instead
of the classic Broccoli-based pipeline. `ember-cli-rails` supports both build
systems, and detects the Vite-based build by the presence of a `vite.config.*`
file in the Ember application's root.

When upgrading an Ember application to the Vite-based blueprint, note the
following differences in how `ember-cli-rails` treats it:

* Remove `ember-cli-rails-addon` from the application's `package.json`. The
  addon is incompatible with the Vite-based build (it forces
  `storeConfigInMeta` off and ships an initializer that imports the removed
  `ember` module), and `ember-cli-rails` no longer needs it there.
* Use `include_ember_script_tags` on its own instead of pairing it with
  `include_ember_stylesheet_tags`: for Vite-based applications it emits the
  configuration meta tag, the stylesheet links, and the module script tags
  all together, while `include_ember_stylesheet_tags` supports only classic
  applications. This requires `ember-cli-rails-assets >= 0.8.0`.
* In development, the application is served by Vite's development server —
  the same one the application's `npm start` script runs. `ember-cli-rails`
  starts it on the first request and shuts it down when Rails exits, and
  rewrites the URLs in the `index.html` it serves so that the browser loads
  the application's modules, and Vite's HMR client, from it directly. Changes
  are hot-reloaded without restarting Rails.

  Configure it, or opt out of it, with the `dev_server` option:

  ```rb
  EmberCli.configure do |c|
    # listen on a fixed port instead of an available one
    c.app :frontend, dev_server: { port: 4200 }

    # build once, synchronously, on the first request instead
    c.app :admin, dev_server: false
  end
  ```

* `include_ember_script_tags` reads the output of `ember build`, which the
  development server does not produce. Render Vite-based applications with
  `render_ember_app`, or disable the development server with
  `dev_server: false` to keep using the asset helpers.

[Vite]: https://vitejs.dev

# Ruby support

According to [these release notes][latest-eol], Ruby versions prior to `2.5.x`
has been end-of-lifed.

Additionally, this codebase makes use of [(required) keyword arguments][kwargs].

From `ember-cli-rails@0.4.0` and on, we will no longer support versions of Ruby
prior to `2.1.0`.

`ember-cli-rails@0.8.0` adds support for Rails 5, which depends on `rack@2.0.x`,
which **requires** Ruby `2.2.2` or greater.

From `ember-cli-rails@0.8.0` and on, we will no longer support versions of Ruby
prior to `2.2.2`.

From `ember-cli-rails@0.12.0` and on, we will no longer support versions of Ruby
prior to `2.5.x`.

To use `ember-cli-rails` with older versions of Ruby, try the `0.3.x` series.

[kwargs]: https://robots.thoughtbot.com/ruby-2-keyword-arguments
[latest-eol]: https://www.ruby-lang.org/en/news/2020/04/05/support-of-ruby-2-4-has-ended/

# Rails support

According to the [Rails Maintenance Policy][version-policy], Rails versions
prior to `5.2.x` have been end-of-lifed. Additionally, the `4.0.x` series no
longer receives bug fixes of any sort.

From `ember-cli-rails@0.4.0` and on, we will no longer support versions of Rails
prior to `3.2.0`, nor will we support the `4.0.x` series of releases.

From `ember-cli-rails@0.12.0` and on, we will no longer support versions of
Rails prior to `5.2.0`.

To use `ember-cli-rails` with older versions of Rails, try the `0.3.x` series.

[version-policy]: http://guides.rubyonrails.org/maintenance_policy.html
