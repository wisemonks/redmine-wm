class ChangePrivateEstimatedHoursPrecision < ActiveRecord::Migration[6.1]
  def change
    change_column :issues, :private_estimated_hours, :decimal, :precision => 10, :scale => 2
  end
end
