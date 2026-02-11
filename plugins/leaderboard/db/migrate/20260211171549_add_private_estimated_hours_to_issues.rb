class AddPrivateEstimatedHoursToIssues < ActiveRecord::Migration[6.1]
  def change
    add_column :issues, :private_estimated_hours, :decimal
  end
end
