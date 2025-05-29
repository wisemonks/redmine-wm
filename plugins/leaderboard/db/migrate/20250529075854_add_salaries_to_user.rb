class AddSalariesToUser < ActiveRecord::Migration[6.1]
  def change
    create_table :salaries do |t|
      t.references :user
      t.float :salary
      t.date :from
      t.date :to
    end
  end
end