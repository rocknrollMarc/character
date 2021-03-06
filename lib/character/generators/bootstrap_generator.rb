require 'rails/generators'

module Character
  module Generators
    class BootstrapGenerator < ::Rails::Generators::Base
      desc "Setup posts, pages and admin."
      source_root File.expand_path("../../templates", __FILE__)

      def override_layout
        copy_file 'application.html.erb', 'app/views/layouts/application.html.erb'
      end

      def copy_initializer_file
        copy_file "initializer.rb", "config/initializers/character.rb"
      end

      def copy_settings_file
        copy_file "settings.yml", "config/settings.yml"
      end

      def setup_assets
        copy_file "admin.coffee", "app/assets/javascripts/admin.coffee"
        copy_file "admin.scss", "app/assets/stylesheets/admin.scss"
        copy_file "assets.rb", "config/initializers/assets.rb"
        copy_file "application.scss", "app/assets/stylesheets/application.scss"

        # TODO: remove application.css file
        # TODO: create application folder

        copy_file "typography.scss", "app/assets/stylesheets/application/typography.scss"
        copy_file "settings.scss", "app/assets/stylesheets/application/settings.scss"
      end

      def add_routes
        inject_into_file "config/routes.rb", before: "  # The priority is based upon order of creation: first created -> highest priority.\n" do <<-'RUBY'
mount_character_instance 'admin'
mount_posts_at '/'
mount_pages_at '/'
RUBY
        end
      end

      def remove_assets_require_tree
        gsub_file 'app/assets/javascripts/application.js', "//= require_tree .\n", ''

        # TODO: this file should be removed
        # gsub_file 'app/assets/stylesheets/application.css', " *= require_tree .\n", ''
      end
    end
  end
end