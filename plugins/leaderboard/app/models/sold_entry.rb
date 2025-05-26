class SoldEntry < ActiveRecord::Base
  belongs_to :project

  # Scope to get all of the sold entries for a given year
  scope :for_year, lambda { |year|
    p year, Date.new(year)
    where("sold_entries.from >= ? AND sold_entries.to <= ?", Date.new(year).beginning_of_year, Date.new(year).end_of_year)
  }
end