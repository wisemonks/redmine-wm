class AddMatermostFields < ActiveRecord::Migration[6.1]
  def change
    add_column :users, :mattermost_user_id, :string

    User.find(134).update(mattermost_user_id: 'sckbn6jws3dx9bxfz4dizfwgbo')
    User.find(151).update(mattermost_user_id: 's1btbbe6fbg3xf7p8daay46osh') 
    User.find(156).update(mattermost_user_id: 'o7ix8s8egirepm5kcm7umsm96e')
    User.find(161).update(mattermost_user_id: 'gd4xp7mb83yzfgs9niyyxk3tey')
    User.find(172).update(mattermost_user_id: '5rsb63p1pidxfe8dffi8n3etay')
    User.find(1).update(mattermost_user_id: 'u5xkkzeuh7dn7gzztugi5b5u7e')
    User.find(169).update(mattermost_user_id: 'emr15brb1trsp8xbaioijwgt3r')
    User.find(178).update(mattermost_user_id: 'ixmmjqhn73duzmna5jmtfhwhdh')
  end
end
