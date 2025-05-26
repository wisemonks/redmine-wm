namespace :task_pool do
  desc "Notify about new tasks in Redmine"
  task :notify => :environment do
    mattermost = Mattermost::MattermostSdk.new(Rails.application.credentials[:mattermost][:user_token])
    estimated_status = IssueStatus.find_by_name('Estimated')
    issues = Issue.where(task_pool: true, status: estimated_status)
    user = User.find_by_mail('rytis@wisemonks.com')

    # Send notification for each issue to the Mattermost channel
    issues.each do |issue|
      message = mattermost.format_issue_message(issue)
      response = mattermost.create_post(mattermost.channels[:pool], message)
      mattermost.pin_post(response['id'])
      mattermost_message = MattermostMessage.find_or_create_by(mattermost_id: response['id'], mattermost_user: user.mattermost_user)
      issue.update(mattermost_message: mattermost_message)
    end
  end

  desc "Check the status of the Mattermost messages"
  task :check_status => :environment do
    mattermost = Mattermost::MattermostSdk.new(Rails.application.credentials[:mattermost][:user_token])
    issues = Issue.where(task_pool: true).where.not(mattermost_message: nil)

    issues.each do |issue|
      message = mattermost.get_post(issue.mattermost_message.mattermost_id)
      next if message&.body&.nil?

      issue.assign_mattermost_user(mattermost, message)
    end
  end

  desc "Notify the user to fill in spent time"
  task :notify_spent_time => :environment do
    mattermost = Mattermost::MattermostSDK.new(Rails.application.credentials[:mattermost][:user_token])
    issues = Issue.where(task_pool: true).where.not(mattermost_message: nil)

    issues.each do |issue|
      mattermost.get_reactions(issue.mattermost_message.mattermost_id)&.group_by { |r| r['user_id'] }&.each do |user_id, user_reactions|
        next unless user_reactions.any? { |r| r['emoji_name'] == '+1' }

        user = MattermostUser.find_by(mattermost_id: user_id)&.user
        next if user.nil?

        issue_url = "[##{issue.id} [#{issue.tracker.name}] #{issue.subject}](https://redmine.wisemonks.com/issues/#{issue.id})"
        message = "@#{user.mattermost_user.mattermost_name} **Please log your SPENT TIME.**\n\n#{issue_url}"
        mattermost.create_post(
          mattermost.channels[:pool],
          message,
          issue.mattermost_message.mattermost_id
        )
      end
    end
  end
end