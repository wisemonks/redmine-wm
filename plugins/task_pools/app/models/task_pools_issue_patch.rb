# frozen_string_literal: true

# Redmine - project management software
# Copyright (C) 2006-2023  Jean-Philippe Lang
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License
# as published by the Free Software Foundation; either version 2
# of the License, or (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program; if not, write to the Free Software
# Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301, USA.

# Simple class to compute the start and end dates of a calendar
module TaskPoolsIssuePatch
  def self.included(base)
    base.class_eval do
      belongs_to :mattermost_message, class_name: 'MattermostMessage', optional: true

      def assign_mattermost_user(mattermost, message)
        issue_url = "[##{id} [#{tracker.name}] #{subject}](https://redmine.wisemonks.com/issues/#{id})"
        reactions = mattermost.get_reactions(message['id'])
        reactions_by_user = reactions.group_by { |r| r['user_id'] }
        manager_user = User.find_by_mail('rytis@wisemonks.com')
        resolved_not_published_status = IssueStatus.find_by_name('Resolved (Not Published)')
        in_progress_status = IssueStatus.find_by_name('In Progress')

        reactions_by_user.each do |user_id, user_reactions|
          user = MattermostUser.find_by(mattermost_id: user_id)&.user
          next if user.nil?

          if user_reactions.any? { |r| r['emoji_name'] == 'ship' }
            current_status = IssueStatus.find_by_id(status_id)

            self.init_journal(user, '')
            self.update(status_id: resolved_not_published_status.id, assigned_to_id: manager_user.id)

            message = "#{issue_url}\n\nThis issue has been shipped.\n\n** @#{user.mattermost_user.mattermost_name} Please log your SPENT TIME.**"
            mattermost.create_post(
              mattermost.channels[:pool],
              message,
              mattermost_message.mattermost_id
            )
            next
          elsif user_reactions.any? { |r| r['emoji_name'] == '+1' }
            Watcher.find_or_create_by(watchable: self, user: user)
            Watcher.find_or_create_by(watchable: self, user_id: manager_user.id) unless manager_user == user

            self.init_journal(user, '')
            self.update(status_id: in_progress_status.id, assigned_to_id: user.id)

            message = "#{issue_url}\n\nThis issue has been reassigned to @#{user.mattermost_user.mattermost_name}"
            mattermost.create_post(
              mattermost.channels[:pool],
              message,
              mattermost_message.mattermost_id
            )
            next
          end
        end
      end
    end
  end
end
