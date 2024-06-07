class SoldEntry < ActiveRecord::Base
  belongs_to :project

  # after_create :calculate_sold_hours

  # def calculate_sold_hours
  #   p self
  #   hours = (amount - vat_amount) / tariff
  #   save
  # end
end