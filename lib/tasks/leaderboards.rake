namespace :leaderboards do
  desc "Send spent hours to admins and users"
  task :send_leaderboards => :environment do
    Leaderboard.calculate_leaderboard
  end

  desc "Calculate project profitability"
  task :calculate_project_profitability => :environment do
    Leaderboard.calculate_project_profitability(Date.today.last_month.beginning_of_month, Date.today.last_month.end_of_month)
  end
end