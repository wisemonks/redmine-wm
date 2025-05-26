# Use this file to easily define all of your cron jobs.
#
# It's helpful, but not entirely necessary to understand cron before proceeding.
# http://en.wikipedia.org/wiki/Cron

# Example:
#
# set :output, "./log/cron.log"
set :output, "./log/cron.log"
set :env_path, '"$HOME/.rbenv/shims":"$HOME/.rbenv/bin"'

job_type :rails,  %q{ cd :path && PATH=:env_path:"$PATH" RAILS_ENV=:environment bundle exec rails :task :output }
job_type :runner, %q{ cd :path && PATH=:env_path:"$PATH" bin/rails runner -e :environment ':task' :output }
job_type :script, %q{ cd :path && PATH=:env_path:"$PATH" RAILS_ENV=:environment bundle exec bin/:task :output }

repeat :weekly, 'monday', roles: [:whenever] do
  rails "leaderboards:send_leaderboards"
end