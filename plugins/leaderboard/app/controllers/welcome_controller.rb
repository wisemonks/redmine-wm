# frozen_string_literal: true

# Redmine - project management software
# Copyright (C) 2006-2023  Jean-Philippe Lang
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License
# as published by the Free Software Foundation; either version 2
# of the License, or (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program; if not, write to the Free Software
# Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301, USA.

class WelcomeController < ApplicationController
  self.main_menu = false

  skip_before_action :check_if_login_required, only: [:robots]

  def index
    @news = News.latest User.current

    
    current_year = Time.zone.now.year
    @prev_year_profitability = SoldEntry.for_year(current_year - 1).sum(:amount).round(2)
    @current_year_profitability = SoldEntry.for_year(current_year).sum(:amount).round(2)

    # SoldEntry: sum of amounts per month
    sold_entries_by_month = SoldEntry.where('YEAR(`from`) = ?', current_year)
                                     .group('MONTH(`from`)')
                                     .sum(:amount)
    # TimeEntry: sum of hours per month, then multiply each by 30
    spent_time_by_month = TimeEntry.where('YEAR(spent_on) = ?', current_year)
                                   .group('MONTH(spent_on)')
                                   .sum(:hours)
    spent_time_by_month = spent_time_by_month.transform_values { |hours| hours * 30 }

    # Normalize keys to integer months
    sold_entries_by_month = sold_entries_by_month.transform_keys { |k| k.to_i }
    spent_time_by_month = spent_time_by_month.transform_keys { |k| k.to_i }

    months = (1..12).to_a
    sold_entries_data = months.map { |m| sold_entries_by_month[m] || 0 }
    spent_time_data = months.map { |m| spent_time_by_month[m] || 0 }

    @months = Date::MONTHNAMES.compact
    @sold_entries_data = sold_entries_data
    @spent_time_data = spent_time_data
  end

  def robots
    @projects = Project.visible(User.anonymous) unless Setting.login_required?
    render :layout => false, :content_type => 'text/plain'
  end
end
