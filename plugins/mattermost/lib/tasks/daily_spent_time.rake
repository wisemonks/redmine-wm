namespace :mattermost do
  desc "Send daily spent time report to #general channel"
  task :yesterday_spent_time => :environment do
    yesterday = Date.yesterday
    target_hours = 8.0
    report_data = []

    [:rokasabrutis, :raminta, :edvinas, :adomas, :vilimaite].each do |user|
      mattermost_user = Mattermost::Base::MATTERMOST_CHANNELS[user]
      next if mattermost_user.nil?

      redmine_user = User.find_by_mattermost_user_id(mattermost_user)
      time_entries = TimeEntry.where(user_id: redmine_user.id, spent_on: yesterday).includes(:issue)
      total_hours = time_entries.sum(:hours).to_f.round(2)
      percentage = ((total_hours / target_hours) * 100).round(1)
      
      task_links = time_entries.group_by(&:issue_id).map do |issue_id, entries|
        issue = entries.first.issue
        hours = entries.sum(&:hours).round(2)
        "[##{issue_id}](https://redmine.wisemonks.com/issues/#{issue_id}) (#{hours}h)"
      end.join(', ')
      
      report_data << {
        username: user,
        total_hours: total_hours,
        percentage: percentage,
        tasks: task_links
      }
    end

    report_data.sort_by! { |data| -data[:total_hours] }
    
    message = "## Daily Spent Time Report for #{yesterday.strftime('%Y-%m-%d')}\n\n"
    message += "| User | Hours | Target Hit | Tasks |\n"
    message += "|---|---|---|---|\n"
    
    report_data.each do |data|
      tasks_display = data[:tasks].present? ? data[:tasks] : '-'
      message += "| @#{data[:username]} | #{data[:total_hours]} | #{data[:percentage]}% | #{tasks_display} |\n"
    end
    
    message += "\n*Target: #{target_hours} hours per day*"
    
    mattermost = Mattermost::Base.new
    mattermost.post_message(:general, message)
    
    puts "Daily spent time report sent to #general channel"
  end

  task :today_spent_time => :environment do
    today = Date.today
    target_hours = 8.0
    report_data = []

    [:rokasabrutis, :raminta, :edvinas, :adomas, :vilimaite].each do |user|
      mattermost_user = Mattermost::Base::MATTERMOST_CHANNELS[user]
      next if mattermost_user.nil?

      redmine_user = User.find_by_mattermost_user_id(mattermost_user)
      time_entries = TimeEntry.where(user_id: redmine_user.id, spent_on: today).includes(:issue)
      total_hours = time_entries.sum(:hours).to_f.round(2)
      percentage = ((total_hours / target_hours) * 100).round(1)
      
      task_links = time_entries.group_by(&:issue_id).map do |issue_id, entries|
        issue = entries.first.issue
        hours = entries.sum(&:hours).round(2)
        "[##{issue_id}](https://redmine.wisemonks.com/issues/#{issue_id}) (#{hours}h)"
      end.join(', ')
      
      report_data << {
        username: user,
        total_hours: total_hours,
        percentage: percentage,
        tasks: task_links
      }
    end

    report_data.sort_by! { |data| -data[:total_hours] }
    
    message = "## Daily Spent Time Report for #{today.strftime('%Y-%m-%d')}\n\n"
    message += "| User | Hours | Target Hit | Tasks |\n"
    message += "|---|---|---|---|\n"
    
    report_data.each do |data|
      tasks_display = data[:tasks].present? ? data[:tasks] : '-'
      message += "| @#{data[:username]} | #{data[:total_hours]} | #{data[:percentage]}% | #{tasks_display} |\n"
    end
    
    message += "\n*Target: #{target_hours} hours per day*"
    
    mattermost = Mattermost::Base.new
    mattermost.post_message(:general, message)
    
    puts "Daily spent time report sent to #general channel"
  end
end
