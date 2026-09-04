require "fileutils"
require "ember-cli-rails-assets"
require "ember_cli/engine"
require "ember_cli/configuration"
require "ember_cli/helpers"
require "ember_cli/errors"

module EmberCli
  extend self

  def configure
    yield configuration
  end

  def configuration
    Configuration.instance
  end

  def app(name)
    apps.fetch(name) do
      fail KeyError, "#{name.inspect} app is not defined"
    end
  end
  alias_method :[], :app

  def apps
    configuration.apps
  end

  def build(name)
    app(name).build
  end

  def any?(*arguments, &block)
    apps.values.any?(*arguments, &block)
  end

  def skip?
    ENV["SKIP_EMBER"].present?
  end

  def install_dependencies!
    each_app(&:install_dependencies)
  end

  def test!
    each_app do |app|
      unless app.test
        fail TestFailureError, "The Ember test suite failed for #{app.name.inspect}"
      end
    end
  end

  def compile!
    cleanup!
    each_app(&:compile)
  end

  def root
    @root ||= Rails.root.join("tmp", "ember-cli").tap(&:mkpath)
  end

  def env
    @env ||= Helpers.current_environment
  end

  private

  def cleanup!
    root.children.each { |tmp_file| FileUtils.rm_rf(tmp_file) }
  end

  def each_app
    apps.each { |_, app| yield app }
  end
end
