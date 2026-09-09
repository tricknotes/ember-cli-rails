module EmberCli
  class HerokuGenerator < Rails::Generators::Base
    source_root File.expand_path("../templates", __FILE__)

    namespace "ember:heroku"

    def copy_package_json_file
      template "package.json.erb", "package.json"
    end

    def identify_as_yarn_project
      if EmberCli.any?(&:yarn?)
        template "yarn.lock.erb", "yarn.lock"
      end
    end

    def identify_as_pnpm_project
      if EmberCli.any?(&:pnpm?)
        template "pnpm-lock.yaml.erb", "pnpm-lock.yaml"
      end
    end

    private

    def node_engine
      unless defined?(@node_engine)
        @node_engine = shared_declaration("engines.node", &:node_engine)
      end

      @node_engine
    end

    def package_manager_spec
      unless defined?(@package_manager_spec)
        @package_manager_spec = shared_declaration("packageManager", &:package_manager_spec)
      end

      @package_manager_spec
    end

    # The value every Ember application declares for a `package.json` field, or nil when they declare different ones:
    # the generated `package.json` can only carry one, and picking either would silently break the other application's build.
    def shared_declaration(field)
      declared = apps.map { |app| yield app }.compact.uniq

      if declared.size > 1
        say_status(
          :conflict,
          "Ember applications declare different `#{field}` (#{declared.join(", ")}); pin one in package.json by hand",
          :red,
        )

        nil
      else
        declared.first
      end
    end

    def cache_directories
      all_cached_directories.map do |cached_directory|
        cached_directory.relative_path_from(Rails.root).to_s
      end
    end

    def all_cached_directories
      app_specific_cached_directories + project_root_cached_directories
    end

    def app_specific_cached_directories
      apps.flat_map(&:cached_directories)
    end

    def project_root_cached_directories
      [Rails.root.join("node_modules")]
    end

    def apps
      EmberCli.apps.values
    end
  end
end
