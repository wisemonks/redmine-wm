class Leaderboard < ActiveRecord::Base
  # This model is used to calculate every user's spent time over the last two months.
  # Then, 'Performance' channel receives a message containing their spent time, comparison with the previous month, and each users' rank.
  MATTERMOST_USERS = {
    'performance': 'soibe9qnefn53y4yu7tu8zg9ce', # Performance channel
  }
  BEARER = ENV['MATTERMOST_BEARER']

  def self.calculate_leaderboard
    mattermost_url = 'https://mattermost.wisemonks.com/api/v4/posts'
    headers = {
      'Authorization' => 'Bearer ' + BEARER
    }
    body = { 'channel_id' => MATTERMOST_USERS[:performance] }
    table_markup = "|Ranking|Monk|This month|Last month|Change|Target|
    |---|---|---|---|---|---|"

    time_entries = TimeEntry.joins(:user).where(user: { admin: true }).where("spent_on >= ?", Date.today.beginning_of_month).group(:user_id).sum(:hours).sort_by { |user_id, spent_hours| spent_hours }.reverse.to_h
    time_entries_32_offset = TimeEntry.joins(:user).where(user: { admin: true }).where("spent_on >= ? AND spent_on <= ?", Date.today.last_month.beginning_of_month, Date.today.last_month.end_of_month).group(:user_id).sum(:hours).sort_by { |user_id, spent_hours| spent_hours }.reverse.to_h

    self.default_entries.merge(time_entries).sort_by { |user_id, spent_hours| spent_hours }.reverse.to_h.each_with_index do |(user_id, spent_hours), index|
      user = User.find(user_id)
      spent_hours_32_offset = time_entries_32_offset[user_id].to_f
      difference = spent_hours - spent_hours_32_offset
      table_markup += "\n|##{index+1}|#{user.name}|#{spent_hours.round(2)}hrs|#{spent_hours_32_offset.round(2)}hrs|#{difference.round(2)}hrs|120hrs|"
    end

    body['message'] = mattermost_greet_message
    response = HTTParty.post(mattermost_url, :headers => headers, :body => body.to_json)

    body['message'] = table_markup
    response = HTTParty.post(mattermost_url, :headers => headers, :body => body.to_json)

    body['message'] = mattermost_bye_message
    response = HTTParty.post(mattermost_url, :headers => headers, :body => body.to_json)
  end

  def self.calculate_project_profitability(from = Date.today.last_month.beginning_of_month, to = Date.today.last_month.end_of_month)
    projects = Project.where.not(client_code: ['', nil], tariff: ['', nil])

    projects.each do |project|
      sales = fetch_project_sales(project.client_code, from, to)
      next if sales.dig('data').nil?

      total_sales = sales['data'].sum{ |a| a['sumWithVatInEuro'] }.to_f
      next if total_sales.zero?
      
      vat_sum = sales['data'].sum{ |a| a['vatInEuro'] }.to_f
      next if vat_sum.zero?

      sold_entry = SoldEntry.find_or_initialize_by(project: project, from: from, to: to)
      sold_entry.amount = total_sales.to_f
      sold_entry.hours = total_sales.to_f / project.tariff.to_f
      sold_entry.vat_amount = vat_sum.to_f
      sold_entry.tariff = project.tariff.to_f
      sold_entry.save
    end
  end

  def self.fetch_project_sales(client_code, from, to)
    params = {
      'rows' => 500,
      'page' => 1,
      'sidx' => 'series',
      'sord' => 'asc',
      'filters' => {
        'groupOp' => 'AND',
        'rules' => [
          {
            'field' => 'series',
            'op' => 'eq',
            'data' => 'WM'
          },
          {
            'field' => 'clientCode',
            'op' => 'eq',
            'data' => client_code
          },
          {
            'field' => 'saleDate',
            'op' => 'ge',
            'data' => from.strftime('%Y-%m-%d')
          },
          {
            'field' => 'saleDate',
            'op' => 'le',
            'data' => to.strftime('%Y-%m-%d')
          }
        ]
      }
    }
    B1::B1.new.request('warehouse/sales/list', params)
  rescue StandardError => e
    Rails.logger.error "Failed to fetch sales from B1: #{e.message}"
  end

  def self.mattermost_greet_message
    "Beep boop! This is your spent time report for the last two months:"
  end

  def self.mattermost_bye_message
    "Keep up the good work! :muscle:"
  end

  def self.default_entries
    {
      1 => 0, # Artūras
      134 => 0, # Rytis
      151 => 0, # Rokas
      152 => 0, # Gabrielius,
      156 => 0, # Raminta
      161 => 0 # Monika
    }
  end
end