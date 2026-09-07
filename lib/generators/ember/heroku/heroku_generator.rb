module EmberCli
  class HerokuGenerator < Rails::Generators::Base
    source_root File.expand_path("../templates", __FILE__)

    namespace "ember:heroku"

    def copy_package_json_file
      template "package.json.erb", "package.json"
    end

    def identify_as_yarn_project
      if EmberCli.any?(&:yarn_enabled?)
        template "yarn.lock.erb", "yarn.lock"
      end
    end

    private

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

    def app_paths
      EmberCli.apps.values.map do |app|
        app.root_path.relative_path_from(Rails.root)
      end
    end

    def apps
      EmberCli.apps.values
    end
  end
end
