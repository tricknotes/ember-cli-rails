require "rails"

require "action_controller/railtie"
require "action_view/railtie"

Bundler.require(*Rails.groups)

module Dummy
  class Application < Rails::Application
    CACHE_CONTROL_FIVE_MINUTES = "public, max-age=300".freeze

    config.root = File.expand_path("..", __FILE__).freeze
    config.eager_load = false

    # Show full error reports and disable caching.
    config.consider_all_requests_local       = true
    config.action_controller.perform_caching = false

    # Raise exceptions instead of rendering exception templates.
    config.action_dispatch.show_exceptions = false

    # Randomize the order test cases are executed.
    config.active_support.test_order = :random

    # Print deprecation notices to the stderr.
    config.active_support.deprecation = :stderr

    config.public_file_server.enabled = true
    config.public_file_server.headers = {
      "cache-control" => CACHE_CONTROL_FIVE_MINUTES
    }

    config.secret_token = "SECRET_TOKEN_IS_MIN_30_CHARS_LONG"
    config.secret_key_base = "SECRET_KEY_BASE"

    if Rails.gem_version < Gem::Version.new("8.1")
      config.active_support.to_time_preserves_timezone = :zone
    end

    def require_environment!
      initialize!
    end
  end
end
