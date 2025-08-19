class TasksController < ApplicationController
  skip_before_action :verify_authenticity_token
  skip_before_action :check_if_login_required

  # before_action :authorize_token
  before_action :set_channel
  before_action :set_issue, except: [:index]
  before_action :set_user, only: [:spent]

  # accept_api_auth :index, :review, :resolve, :finish, :spent

  def index
    # statuses = IssueStatus.where(name: ['New'])
    # tasks_count = Issue.where(status_id: statuses, project_id: Project.active.pluck(:id)).where.not(project_id: [105]).count
    # @tasks = Issue.where(status_id: statuses, project_id: Project.active.pluck(:id)).where.not(project_id: [105]).order(id: :desc).limit(20)

    # table = "Issues found: #{tasks_count}\n\n"
    # table += "| Project | ID | Subject |\n"
    # table += "|---|---|---|\n"
    # @tasks.each do |task|
    #   table += "| [#{task.project.name}](https://redmine.wisemonks.com/projects/#{task.project.name}) | #{task.id} | [#{task.subject}](https://redmine.wisemonks.com/issues/#{task.id}) |\n"
    # end
    
    # Mattermost::Base.new.post_message(@channel, table)

    # render success: true
    render json: {
      response_type: 'ephemeral',
      text: 'Great',
      username: 'Redmine Bot'
    }
  end

  def review
    statuses = IssueStatus.where(name: ['In Review'])

    if @issue.nil?
      message = "Issue not found"
    else
      @issue.status_id = statuses.first.id # 'In Review'
      @issue.assigned_to_id = 134 # Rytis
      @issue.save

      message = "@all [#{@issue.subject} (#{@issue.id})](https://redmine.wisemonks.com/issues/#{@issue.id}) is available for a review."
    end
    
    Mattermost::Base.new.post_message(@channel, message)

    render success: true
  end

  def resolve
    statuses = IssueStatus.where(name: ['Resolved (Not Published)'])

    if @issue.nil?
      message = "Issue not found"
    else
      @issue.status_id = statuses.first.id # 'Resolved (Not Published)'
      @issue.save

      message = "[#{@issue.subject} (#{@issue.id})](https://redmine.wisemonks.com/issues/#{@issue.id}) is resolved."
    end
    
    Mattermost::Base.new.post_message(@channel, message)

    render success: true
  end

  def finish
    statuses = IssueStatus.where(name: ['Resolved'])

    if @issue.nil?
      message = "Issue not found"
    else
      @issue.status_id = statuses.first.id # 'Resolved'
      @issue.save

      message = "[#{@issue.subject} (#{@issue.id})](https://redmine.wisemonks.com/issues/#{@issue.id}) is finished."
    end
    
    Mattermost::Base.new.post_message(@channel, message)

    render success: true
  end

  def spent
    if @issue.nil? || @user.nil?
      render json: {
        response_type: 'ephemeral',
        text: 'Issue or user not found',
        username: 'Redmine Bot'
      }
    else
      TimeEntry.create(
        project_id: @issue.project_id,
        author_id: 134, # Rytis
        user_id: @user,
        issue_id: @issue.id,
        hours: params[:text].split(' ')[1],
        activity_id: 9, # 'development'
        tyear: Date.today.year,
        tmonth: Date.today.month,
        tweek: Date.today.cweek,
        created_on: Date.today,
        updated_on: Date.today
      )

      message = "Assigned #{params[:text].split(' ')[1]} hours to [#{@issue.subject} (#{@issue.id})](https://redmine.wisemonks.com/issues/#{@issue.id})."
    end
    
    Mattermost::Base.new.post_message(@channel, message)

    render success: true
  end

  private

  def set_channel
    @channel = Mattermost::Base::MATTERMOST_CHANNELS.find { |_, v| v == params[:channel_name] }&.first || 'valandiniai'
  end

  def set_issue
    id = params[:text].split(' ')[0]
    @issue = Issue.find_by_id(id)
  end

  def set_user
    @user = Mattermost::Base::MATTERMOST_CHANNELS.find { |_, v| v == params[:channel_name] }&.first || 134
  end

  def authorize_token
    token = request.headers['Authorization'].split(' ')[1]
    allowed_tokens = Rails.application.credentials.mattermost[:slash].values

    if !allowed_tokens.include?(token)
      render json: {
        response_type: 'ephemeral',
        text: 'Unauthorized',
        username: 'Redmine Bot'
      }
    end
  end
end