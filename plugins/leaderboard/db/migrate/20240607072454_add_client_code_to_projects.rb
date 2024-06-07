class AddClientCodeToProjects < ActiveRecord::Migration[6.1]
  def change
    add_column :projects, :client_code, :string
    add_column :projects, :tariff, :float

    create_table :sold_entries do |t|
      t.references :project
      t.date :from
      t.date :to
      t.float :hours
      t.float :amount
      t.float :vat_amount
      t.float :tariff
    end
  end
end