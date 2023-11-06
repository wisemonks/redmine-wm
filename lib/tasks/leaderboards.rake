namespace :leaderboards do
  desc "Send spent hours to admins and users"
  task :send_leaderboards => :environment do
    Leaderboard.calculate_leaderboard_for_admins
    Leaderboard.calculate_leaderboard_for_each_user
  end
end