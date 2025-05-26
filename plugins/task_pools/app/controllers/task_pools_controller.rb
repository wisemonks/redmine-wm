class TaskPoolsController < ApplicationController
  skip_before_action :check_if_login_required, :verify_authenticity_token
  before_action :authorize_command

  def spent
    # 1. Get the user in redmine using user_id
    mattermost_user = MattermostUser.find_by(mattermost_id: params[:user_id])
    if mattermost_user.nil? || mattermost_user.user.nil?
      render json: { response_type: 'comment', text: 'User not found in Redmine system' }
      return
    end
    
    user = mattermost_user.user
    # 2. Get the mattermost post using post_id
    post_id = params[:post_id]
    mattermost = Mattermost::MattermostSdk.new(Rails.application.credentials[:mattermost][:user_token])
    post = JSON.load(mattermost.get_post(post_id).body)
    if post.nil?
      render json: { response_type: 'comment', text: 'Could not retrieve the Mattermost post' }
      return
    end
    
    # 3. Find the issue related to this post or its parent posts
    issue = nil
    current_post_id = post_id
    5.times do
      # Try to find an issue with this mattermost_id
      mattermost_message = MattermostMessage.find_by(mattermost_id: current_post_id)
      if mattermost_message
        issue = Issue.find_by(mattermost_message_id: mattermost_message.id)
        break if issue
      end
      
      # If not found, try to get the parent post
      current_post = JSON.load(mattermost.get_post(current_post_id).body)
      break if current_post.nil?
      
      # Check if this post has a parent
      root_id = current_post['root_id']
      break if root_id.blank? || root_id == current_post_id
      
      # Move to the parent post
      current_post_id = root_id
    end
    
    if issue.nil?
      render json: { response_type: 'comment', text: 'Could not find an issue related to this conversation' }
      return
    end
    
    # 4. Parse the command text for hours
    text_parts = params[:text].to_s.strip.split(/\s+/)
    
    # Remove the trigger word if it's the first part
    text_parts.shift if text_parts.first&.downcase == 'spent'
    
    if text_parts.empty?
      render json: { 
        response_type: 'comment', 
        text: "Please specify the hours to log. Example: `spent 2.5` or `spent 3`" 
      }
      return
    end
    
    # Get hours from the first part
    hours_str = text_parts.shift
    hours = hours_str.to_f
    
    # Round to nearest quarter (0.25)
    hours = (hours * 4).round / 4.0
    
    if hours <= 0
      render json: { 
        response_type: 'comment', 
        text: "Invalid hours value. Please specify a positive number." 
      }
      return
    end
    
    # Any remaining text is the comment
    comments = text_parts.join(' ')
    
    # Create the time entry
    time_entry = TimeEntry.new(
      project: issue.project,
      issue: issue,
      user: user,
      hours: hours,
      comments: comments,
      activity_id: TimeEntryActivity.find_by(name: 'Development')&.id,
      spent_on: Date.today
    )
    
    if time_entry.save
      # 5. Notify the user that the command was successful
      issue_url = "https://redmine.wisemonks.com/issues/#{issue.id}"
      message = "Time entry added: #{hours} hours on issue [##{issue.id}](#{issue_url}) by @#{params[:user_name]}"
      
      if comments.present?
        message += " with comment: #{comments}"
      end
      
      render json: { 
        response_type: 'comment', 
        text: message
      }
    else
      render json: { 
        response_type: 'comment', 
        text: "Failed to log time: #{time_entry.errors.full_messages.join(', ')}" 
      }
    end
  end

  private

  def authorize_command
    auth_token = Rails.application.credentials[:mattermost][:outgoing_webhook_token]
    header_token = params[:token]

    render json: { response_type: 'comment', text: 'Unauthorized' }, status: :unauthorized unless auth_token == header_token
  end
end