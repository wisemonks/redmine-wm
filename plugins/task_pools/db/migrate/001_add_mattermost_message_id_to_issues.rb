class AddMattermostMessageIdToIssues < ActiveRecord::Migration[6.1]
  def change
    create_table :mattermost_users do |t|
      t.string :mattermost_id
      t.string :mattermost_name
    end

    create_table :mattermost_messages do |t|
      t.references :mattermost_user, null: false, foreign_key: true
      t.string :mattermost_id
    end

    add_column :issues, :task_pool, :boolean, null: false, default: false

    add_reference :users, :mattermost_user, null: true, foreign_key: true
    add_reference :issues, :mattermost_message, null: true, foreign_key: true
  end
end