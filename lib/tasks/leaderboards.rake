namespace :leaderboards do
  desc "Send reminders to fill in the spent time for current day"
  task :send_reminders => :environment do
    Leaderboard.send_reminders
  end

  desc "Send spent hours to admins and users"
  task :send_leaderboards => :environment do
    Leaderboard.calculate_leaderboard
  end

  desc "Calculate project profitability"
  task :calculate_project_profitability => :environment do
    Leaderboard.calculate_project_profitability(Date.today.last_month.beginning_of_month, Date.today.last_month.end_of_month)
  end
end