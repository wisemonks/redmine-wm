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
    
    # Yearly profitability bar chart
    # Each year is a separate bar
    current_year = Time.zone.now.year
    @prev_year_profitability = SoldEntry.for_year(current_year - 1).sum(:amount).round(2)
    @current_year_profitability = SoldEntry.for_year(current_year).sum(:amount).round(2)



    # Users's spent time vs sold time line chart:
    # Line 1: total sold hours for a given month
    # Line 2: total spent hours for a given month
    sold_entries_by_month = SoldEntry.where('YEAR(`from`) = ?', current_year)
                                     .group('MONTH(`from`)')
                                     .sum(:hours)
    # TimeEntry: sum of hours per month, then multiply each by 30
    spent_time_by_month = TimeEntry.where('YEAR(spent_on) = ?', current_year)
                                   .group('MONTH(spent_on)')
                                   .sum(:hours)
    # spent_time_by_month = spent_time_by_month.transform_values { |hours| hours * 30 }

    # Normalize keys to integer months
    sold_entries_by_month = sold_entries_by_month.transform_keys { |k| k.to_i }
    spent_time_by_month = spent_time_by_month.transform_keys { |k| k.to_i }

    months = (1..12).to_a
    sold_entries_data = months.map { |m| sold_entries_by_month[m]&.round(2) || 0 }
    spent_time_data = months.map { |m| spent_time_by_month[m]&.round(2) || 0 }

    @months = Date::MONTHNAMES.compact
    @sold_entries_data = sold_entries_data
    @spent_time_data = spent_time_data




    # User's profitability line chart:
    # Line 1: User's salaries for a year month over month
    # Line 2: Sold Entries for a given month on the projects', where user has spent time
    user_salaries = Salary.where('YEAR(`from`) = ?', current_year)
                          .group('MONTH(`from`)')
                          .sum(:salary)
    user_salaries_by_month = user_salaries.transform_keys { |k| k.to_i }
    user_salaries_data = user_salaries_by_month.transform_values { |s| s.round(2) }
    @user_salaries_data = months.map { |m| user_salaries_data[m] || 0 }

    user_sold_entries_by_month = SoldEntry.where('YEAR(`from`) = ?', current_year)
                                          .group('MONTH(`from`)')
                                          .sum(:amount)
    user_sold_entries_by_month = user_sold_entries_by_month.transform_keys { |k| k.to_i }
    user_sold_entries_data = user_sold_entries_by_month.transform_values { |s| s.round(2) }
    @user_sold_entries_data = months.map { |m| user_sold_entries_data[m] || 0 }
  end

  def robots
    @projects = Project.visible(User.anonymous) unless Setting.login_required?
    render :layout => false, :content_type => 'text/plain'
  end
end
