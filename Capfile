# Load DSL and set up stages
require 'capistrano/setup'
require 'capistrano/deploy'
require "capistrano/scm/git"
install_plugin(Capistrano::SCM::Git)

require 'capistrano/rbenv'
require 'capistrano/bundler'
require 'capistrano/rails'
require 'capistrano/rails/migrations'

require 'capistrano/puma'
# install_plugin Capistrano::Puma  # Default puma tasks
# install_plugin Capistrano::Puma::Systemd  # if you use SystemD
# install_plugin Capistrano::Puma::Nginx

require "whenever/capistrano"

# Load custom tasks from `lib/capistrano/tasks` if you have any defined
Dir.glob('lib/capistrano/tasks/*.rake').each { |r| import r }