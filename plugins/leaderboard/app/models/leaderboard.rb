class Leaderboard < ActiveRecord::Base
  # This model is used to calculate every user's spent time over the last 32 days.
  # Then, each user receives a message containing their spent time, comparison with the previous 64 days, and their rank.
  MATTERMOST_USERS = {
    '1': '8bobf9fiqbryfrkr6ciz3rm5ww', # Arturas
    '134': '4qa8z84metdo5gozjwbjr5geho', # Rytis
    '151': 'dcm5ywcw5jbkmxece4dnngex1r', # Rokas
  }
  BEARER = ENV['MATTERMOST_BEARER']

  def self.calculate_leaderboard_for_admins
    mattermost_url = 'https://mattermost.wisemonks.com/api/v4/posts'
    headers = {
      'Authorization' => 'Bearer ' + BEARER
    }
    time_entries = TimeEntry.joins(:user).where(user: { admin: true }).where("spent_on >= ?", Date.today.beginning_of_month).group(:user_id).sum(:hours).sort_by { |user_id, spent_hours| spent_hours }.reverse
    time_entries_32_offset = TimeEntry.joins(:user).where(user: { admin: true }).where("spent_on >= ? AND spent_on < ?", Date.today.last_month.beginning_of_month, Date.today.last_month.end_of_month).group(:user_id).sum(:hours).sort_by { |user_id, spent_hours| spent_hours }.reverse.to_h

    table_markup = "|Ranking|Monk|This month|Last month|Change|
    |---|---|---|---|---|"
    time_entries.each_with_index do |(user_id, spent_hours), index|
      user = User.find(user_id)
      spent_hours_32_offset = time_entries_32_offset[user_id].to_f
      difference = spent_hours - spent_hours_32_offset
      table_markup += "\n|##{index+1}|#{user.name}|#{spent_hours.round(2)}hrs|#{spent_hours_32_offset.round(2)}hrs|#{difference.round(2)}hrs|"
    end

    MATTERMOST_USERS.to_a[0..1].each do |_user_id, mattermost_id|
      body = {
        'channel_id' => mattermost_id,
        'message' => table_markup
      }
      response = HTTParty.post(mattermost_url, :headers => headers, :body => body.to_json)
    end
  end

  # This method is used to calculate the spent time of each user over the last 32 days.
  def self.calculate_leaderboard_for_each_user
    mattermost_url = 'https://mattermost.wisemonks.com/api/v4/posts'
    headers = {
      'Authorization' => 'Bearer ' + BEARER
    }
    time_entries = TimeEntry.joins(:user).where(user: { admin: true }).where("spent_on >= ?", Date.today.beginning_of_month).group(:user_id).sum(:hours).sort_by { |user_id, spent_hours| spent_hours }.reverse
    time_entries_32_offset = TimeEntry.joins(:user).where(user: { admin: true }).where("spent_on >= ? AND spent_on < ?", Date.today.last_month.beginning_of_month, Date.today.last_month.end_of_month).group(:user_id).sum(:hours).sort_by { |user_id, spent_hours| spent_hours }.reverse.to_h

    time_entries.each_with_index do |(user_id, spent_hours), index|
      spent_hours_32_offset = time_entries_32_offset[user_id].to_f
      difference = spent_hours - spent_hours_32_offset
      mattermost_id = MATTERMOST_USERS[user_id.to_s.to_sym]
      body = {
        'channel_id' => mattermost_id,
        'message' => mattermost_greet_message
      }
      response = HTTParty.post(mattermost_url, :headers => headers, :body => body.to_json)
      
      body['message'] = mattermost_leaderboard(spent_hours, spent_hours_32_offset, difference, index+1)
      response = HTTParty.post(mattermost_url, :headers => headers, :body => body.to_json)
      
      body['message'] = mattermost_bye_message
      response = HTTParty.post(mattermost_url, :headers => headers, :body => body.to_json)
    end
  end

  def self.mattermost_greet_message
    "Beep boop! This is your daily spent time report for the last two months:"
  end

  def self.mattermost_bye_message
    "Keep up the good work! :muscle:"
  end

  def self.mattermost_leaderboard(spent_hours, spent_hours_32_offset, difference, rank)
    " |Ranking|This month|Last month|Change|
      |---|---|---|---|
      |##{rank}|#{spent_hours.round(2)}hrs|#{spent_hours_32_offset.round(2)}hrs|#{difference.round(2)}hrs|
    "
  end
end