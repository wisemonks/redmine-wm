class AddMatermostFields < ActiveRecord::Migration[6.1]
  def change
    add_column :users, :mattermost_user_id, :string

    User.find(134).update(mattermost_user_id: 'sckbn6jws3dx9bxfz4dizfwgbo')
    User.find(151).update(mattermost_user_id: 'dcm5ywcw5jbkmxece4dnngex1r')
    User.find(156).update(mattermost_user_id: 'store77e87g7zjuxi3ieg31roy')
    User.find(161).update(mattermost_user_id: 'pabetp7expfrdniyy66a654c1e')
    User.find(172).update(mattermost_user_id: 'mfh6rnigmiy7zrptoeioytfc8c')
    User.find(1).update(mattermost_user_id: '8bobf9fiqbryfrkr6ciz3rm5ww')
    User.find(169).update(mattermost_user_id: 'jxddbgtw6tntfcoah84uiap5ne')
    User.find(178).update(mattermost_user_id: 'bh8ojm7jmffomxrm84gbphruah')
  end
end
