class MattermostMessage < ActiveRecord::Base
  belongs_to :mattermost_user
end