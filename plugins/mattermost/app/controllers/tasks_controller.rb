class TasksController < ActionController::Base
  skip_before_action :verify_authenticity_token
  before_action :set_channel, :authorize_token
  before_action :set_project, only: [:index]
  before_action :set_issue, except: [:index, :assigned]
  before_action :set_user, only: [:spent, :start, :assigned, :spent]

  def index
    statuses = IssueStatus.where(name: ['New', 'Estimated'])
    tracker = Tracker.find_by_name('Design')
    tasks_count = Issue.where(status_id: statuses, project_id: @project.pluck(:id)).where.not(project_id: [105], tracker_id: tracker.id).count
    @tasks = Issue.where(status_id: statuses, project_id: @project.pluck(:id)).where.not(project_id: [105], tracker_id: tracker.id).order(id: :desc).limit(20)

    table = "Available issues found: #{tasks_count}\n\n"
    table += "| Project | ID | Subject |\n"
    table += "|---|---|---|\n"
    @tasks.each do |task|
      table += "| [#{task.project.name}](https://redmine.wisemonks.com/projects/#{task.project.name}) | #{task.id} | [#{task.subject}](https://redmine.wisemonks.com/issues/#{task.id}) |\n"
    end

    render json: {
      response_type: params['channel_name'].eql?('valandiniai') ? 'in_channel' : 'ephemeral',
      text: table,
      username: 'Redmine Bot'
    }
  end

  def start
    statuses = IssueStatus.where(name: ['In Progress'])

    if @issue.nil?
      message = "Issue not found"
    else
      @issue.status_id = statuses.first.id # 'In Progress'
      @issue.assigned_to_id = @user.id
      @issue.save

      message = "[#{@issue.id} #{@issue.subject}](https://redmine.wisemonks.com/issues/#{@issue.id}) is started by #{@user.firstname} #{@user.lastname}."
    end
    
    render json: {
      response_type: 'ephemeral',
      text: message,
      username: 'Redmine Bot'
    }
  end

  def assigned
    if @user.nil?
      message = "User not found"
    else
      @assigned_issues_count = Issue.where(assigned_to_id: @user.id).count
      @assigned_issues = Issue.where(assigned_to_id: @user.id).limit(20)
      message = "You have #{@assigned_issues_count} assigned issues.\n\n"
      message += "| Project | ID | Subject |\n"
      message += "|---|---|---|\n"
      @assigned_issues.each do |issue|
        message += "| [#{issue.project.name}](https://redmine.wisemonks.com/projects/#{issue.project.name}) | #{issue.id} | [#{issue.subject}](https://redmine.wisemonks.com/issues/#{issue.id}) |\n"
      end
    end

    render json: {
      response_type: 'ephemeral',
      text: message,
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

      message = "@all [#{@issue.id} #{@issue.subject}](https://redmine.wisemonks.com/issues/#{@issue.id}) is available for a review."
    end
    
    render json: {
      response_type: @issue.nil? ? 'ephemeral' : 'in_channel',
      text: message,
      username: 'Redmine Bot'
    }
  end

  def resolve
    statuses = IssueStatus.where(name: ['Resolved (Not Published)'])

    if @issue.nil?
      message = "Issue not found"
    else
      @issue.status_id = statuses.first.id # 'Resolved (Not Published)'
      @issue.assigned_to_id = 134 # Rytis
      @issue.save

      message = "[#{@issue.id} #{@issue.subject}](https://redmine.wisemonks.com/issues/#{@issue.id}) is resolved."
    end
    
    render json: {
      response_type: @issue.nil? ? 'ephemeral' : 'in_channel',
      text: message,
      username: 'Redmine Bot'
    }
  end

  def finish
    statuses = IssueStatus.where(name: ['Resolved'])

    if @issue.nil?
      message = "Issue not found"
    else
      @issue.status_id = statuses.first.id # 'Resolved'
      @issue.assigned_to_id = 134 # Rytis
      @issue.save

      message = "[#{@issue.id} #{@issue.subject}](https://redmine.wisemonks.com/issues/#{@issue.id}) is finished. Total hours spent: #{@issue.time_entries.sum(:hours).round(2)}"
    end
    
    render json: {
      response_type: @issue.nil? ? 'ephemeral' : 'in_channel',
      text: message,
      username: 'Redmine Bot'
    }
  end

  def spent
    if @issue.nil? || @user.nil?
      render json: {
        response_type: 'ephemeral',
        text: 'Whoopsie! An error occured.',
        username: 'Redmine Bot'
      }
    else
      TimeEntry.create(
        project_id: @issue.project_id,
        author_id: 134, # Rytis
        user_id: @user,
        issue_id: @issue.id,
        hours: params['text'].split(' ')[1].to_f,
        activity_id: 9, # 'development'
        spent_on: Date.today,
        tyear: Date.today.year,
        tmonth: Date.today.month,
        tweek: Date.today.cweek,
        created_on: Date.today,
        updated_on: Date.today
      )

      message = "Assigned #{params['text'].split(' ')[1]} hours for #{@user.firstname} #{@user.lastname} to [#{@issue.id} #{@issue.subject}](https://redmine.wisemonks.com/issues/#{@issue.id})."
    end
    
    render json: {
      response_type: 'ephemeral',
      text: message,
      username: 'Redmine Bot'
    }
  end

  private

  def set_project
    @project = Project.find_by_name(params['text'].split(' ')[0])
    @project = Project.active if @project.nil?
  end

  def set_channel
    @channel = Mattermost::Base::MATTERMOST_CHANNELS.find { |_, v| v == params['channel_name'] }&.first || 'valandiniai'
  end

  def set_issue
    id = params['text'].split(' ')[0]
    @issue = Issue.find_by_id(id)
  end

  def set_user
    @user = User.find_by(mattermost_user_id: params['user_id'])
  end

  def authorize_token
    token = params['token']
    allowed_tokens = Rails.application.credentials[:mattermost][:slash].values

    unless allowed_tokens.include?(token)
      render json: {
        response_type: 'ephemeral',
        text: 'Unauthorized',
        username: 'Redmine Bot'
      } and return
    end
  end
end