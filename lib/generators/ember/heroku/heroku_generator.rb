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

    def inject_12factor_gem
      gem "rails_12factor", group: [:staging, :production]
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

    def apps
      EmberCli.apps.values
    end
  end
end
