class CreateBudgetsForProject < ActiveRecord::Migration[6.1]
  def change
    create_table :budgets do |t|
      t.references :project
      t.float :budget
      t.timestamps
    end
  end
end