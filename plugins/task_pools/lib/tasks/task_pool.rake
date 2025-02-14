namespace :task_pool do
  desc "Notify about new tasks in Redmine"
  task :notify => :environment do
    mattermost = Mattermost::MattermostSDK.new(BEARER)
    statuses = IssueStatus.where(name: 'Estimated')
    issues = Issue.left_joins(:mattermost_message).where(status_id: statuses.ids).where(mattermost_messages: { id: nil })
    user = User.find_by_mail('rytis@wisemonks.com')

    # Send notification for each issue to the Mattermost channel
    issues.each do |issue|
      message = mattermost.format_issue_message(issue)
      response = mattermost.create_post(MATTERMOST_CHANNELS[:pool], message)
      issue.mattermost_message.create(mattermost_id: response['id'], mattermost_user: user.mattermost_user)
    end
  end

  desc "Check the status of the Mattermost messages"
  task :check_status => :environment do
    issue_statuses = IssueStatus.where(name: ['New', 'In Progress', 'Estimated', 'Feedback', 'In Review', 'Testing', 'Resolved (Not Published)', 'Approved', 'Resolved (Staging)'])
    issues = Issue.joins(:mattermost_message).where(status_id: issue_statuses.ids)

    issues.each do |issue|
      message = mattermost.get_post(issue.mattermost_message.mattermost_id)
      next if message.nil?
      
      # assign_issue(mattermost, message, issue)
      issue.assign_mattermost_user(message)
    end
  end

  desc "Notify the user to fill in spent time"
  task :notify_spent_time => :environment do
    mattermost = Mattermost::MattermostSDK.new(BEARER)
    issue_statuses = IssueStatus.where(name: ['Resolved', 'Closed', 'Rejected', 'Payed', 'Suspended', 'On Hold'])
    issues = Issue.joins('INNER JOIN mattermost_messages ON mattermost_messages.id = issues.mattermost_message_id LEFT JOIN time_entries ON time_entries.issue_id = issues.id')
                  .where('time_entries.id IS NULL')
                  .where(status_id: issue_statuses.ids)

    issues.each do |issue|
      mattermost.get_reactions(message['id'])&.group_by { |r| r['user_id'] }&.each do |user_id, user_reactions|
        user = MattermostUser.find_by(mattermost_id: user_id)&.user
        next if user.nil?
        next unless user_reactions.any? { |r| r['emoji_name'] == 'ship' }
        
        issue_url = "[##{issue.id} [#{issue.tracker.name}] #{issue.subject}](https://redmine.wisemonks.com/issues/#{issue.id})"
        message = "@#{user.mattermost_user.mattermost_name} Please log your SPENT TIME.\n#{issue_url}"
        mattermost.create_post(
          MATTERMOST_CHANNELS[:pool],
          message,
          issue.mattermost_message.mattermost_id
        )
      end
    end
  end
end