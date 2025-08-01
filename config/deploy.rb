# config valid for current version and patch releases of Capistrano
lock "~> 3.17.0"

set :application, "redmine-wisemonks"
set :repo_url, "git@github.com:wisemonks/redmine-wm.git"

# Default branch is :master
# ask :branch, `git rev-parse --abbrev-ref HEAD`.chomp

# Default deploy_to directory is /var/www/my_app_name
set :deploy_to, '/home/redmine'

# Default value for :format is :airbrussh.
# set :format, :airbrussh

# You can configure the Airbrussh format using :format_options.
# These are the defaults.
# set :format_options, command_output: true, log_file: "log/capistrano.log", color: :auto, truncate: :auto

# Default value for :pty is false
# set :pty, true

# Default value for :linked_files is []
# append :linked_files, "config/database.yml", "config/credentials.yml.enc", "config/master.key"
append :linked_files, "config/database.yml", "config/configuration.yml", "config/credentials.yml.enc", "config/master.key"

# Default value for linked_dirs is []
append :linked_dirs, "log", "files", "tmp/pids", "tmp/cache", "tmp/sockets", "tmp/webpacker", "public/system", "vendor"

# Default value for default_env is {}
# set :default_env, { path: "/opt/ruby/bin:$PATH" }

# Default value for local_user is ENV['USER']
# set :local_user, -> { `git config user.name`.chomp }

# Default value for keep_releases is 5
# set :keep_releases, 5

# Uncomment the following to require manually verifying the host key before first deploy.
# set :ssh_options, verify_host_key: :secure
set :whenever_roles, "whenever"

Rake::Task["deploy:assets:precompile"].clear_actions
Rake::Task["deploy:assets:backup_manifest"].clear_actions

namespace :deploy do
  # Declares a task to be executed once the new code is on the server.
  after :updated, :plugin_assets do
    on roles(:app) do
      within release_path do
        with rails_env: fetch(:rails_env) do
          # Copy over plugin assets
          execute :rake, 'redmine:plugins:assets'
          # Run plugin migrations
          execute :rake, 'redmine:plugins:migrate'
        end
      end
    end
  end

  # cleans up old versions on the server (keeping the number of releases
  # configured above)
  after :finished, 'deploy:cleanup'
end