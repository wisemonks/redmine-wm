module McpTools
  class IssueTools < BaseTool
    def definitions
      [
        {
          name: 'list_issues',
          description: 'List issues with optional filters and pagination',
          inputSchema: {
            type: 'object',
            properties: {
              project_id: { type: 'string', description: 'Filter by project ID' },
              status_id: { type: 'string', description: 'Filter by status ID (open, closed, or specific ID)' },
              assigned_to_id: { type: 'string', description: 'Filter by assigned user ID' },
              tracker_id: { type: 'string', description: 'Filter by tracker ID' },
              limit: { type: 'integer', description: 'Number of results (max 100)', default: 25 },
              offset: { type: 'integer', description: 'Offset for pagination', default: 0 }
            }
          }
        },
        {
          name: 'get_issue',
          description: 'Get detailed information about a specific issue including journals/comments',
          inputSchema: {
            type: 'object',
            properties: {
              issue_id: { type: 'string', description: 'Issue ID' }
            },
            required: ['issue_id']
          }
        },
        {
          name: 'create_issue',
          description: 'Create a new issue',
          inputSchema: {
            type: 'object',
            properties: {
              project_id: { type: 'string', description: 'Project ID' },
              subject: { type: 'string', description: 'Issue subject' },
              description: { type: 'string', description: 'Issue description' },
              tracker_id: { type: 'string', description: 'Tracker ID' },
              status_id: { type: 'string', description: 'Status ID' },
              priority_id: { type: 'string', description: 'Priority ID' },
              assigned_to_id: { type: 'string', description: 'Assigned user ID' }
            },
            required: ['project_id', 'subject']
          }
        },
        {
          name: 'update_issue',
          description: 'Update an existing issue',
          inputSchema: {
            type: 'object',
            properties: {
              issue_id: { type: 'string', description: 'Issue ID' },
              subject: { type: 'string', description: 'New subject' },
              description: { type: 'string', description: 'New description' },
              status_id: { type: 'string', description: 'New status ID' },
              priority_id: { type: 'string', description: 'New priority ID' },
              assigned_to_id: { type: 'string', description: 'New assigned user ID' },
              notes: { type: 'string', description: 'Add a comment/note' }
            },
            required: ['issue_id']
          }
        }
      ]
    end

    def execute(tool_name, arguments, user)
      check_permission(user, :view_issues)

      case tool_name
      when 'list_issues'
        list_issues(arguments, user)
      when 'get_issue'
        get_issue(arguments, user)
      when 'create_issue'
        create_issue(arguments, user)
      when 'update_issue'
        update_issue(arguments, user)
      else
        format_error("Unknown tool: #{tool_name}")
      end
    end

    private

    def list_issues(arguments, user)
      scope = Issue.visible(user)

      scope = scope.where(project_id: arguments['project_id']) if arguments['project_id'].present?
      scope = scope.where(tracker_id: arguments['tracker_id']) if arguments['tracker_id'].present?
      scope = scope.where(assigned_to_id: arguments['assigned_to_id']) if arguments['assigned_to_id'].present?
      
      if arguments['status_id'].present?
        case arguments['status_id']
        when 'open'
          scope = scope.open
        when 'closed'
          scope = scope.where(status: IssueStatus.where(is_closed: true))
        else
          scope = scope.where(status_id: arguments['status_id'])
        end
      end

      result = paginate(scope.order(updated_on: :desc), arguments)

      {
        issues: result[:items].map { |issue| format_issue(issue) },
        total_count: result[:total_count],
        limit: result[:limit],
        offset: result[:offset]
      }
    rescue => e
      format_error(e.message)
    end

    def get_issue(arguments, user)
      issue = Issue.visible(user).find_by(id: arguments['issue_id'])
      
      unless issue
        return format_error("Issue not found or not accessible")
      end

      {
        issue: format_issue(issue, include_journals: true)
      }
    rescue => e
      format_error(e.message)
    end

    def create_issue(arguments, user)
      project = Project.visible(user).find_by(id: arguments['project_id'])
      
      unless project
        return format_error("Project not found or not accessible")
      end

      unless user.allowed_to?(:add_issues, project)
        return format_error("Permission denied to create issues in this project")
      end

      issue = Issue.new
      issue.project = project
      issue.author = user
      issue.subject = arguments['subject']
      issue.description = arguments['description'] if arguments['description'].present?
      issue.tracker_id = arguments['tracker_id'] if arguments['tracker_id'].present?
      issue.status_id = arguments['status_id'] if arguments['status_id'].present?
      issue.priority_id = arguments['priority_id'] if arguments['priority_id'].present?
      issue.assigned_to_id = arguments['assigned_to_id'] if arguments['assigned_to_id'].present?

      if issue.save
        {
          success: true,
          issue: format_issue(issue)
        }
      else
        format_error("Failed to create issue: #{issue.errors.full_messages.join(', ')}")
      end
    rescue => e
      format_error(e.message)
    end

    def update_issue(arguments, user)
      issue = Issue.visible(user).find_by(id: arguments['issue_id'])
      
      unless issue
        return format_error("Issue not found or not accessible")
      end

      unless user.allowed_to?(:edit_issues, issue.project)
        return format_error("Permission denied to edit this issue")
      end

      issue.subject = arguments['subject'] if arguments['subject'].present?
      issue.description = arguments['description'] if arguments['description'].present?
      issue.status_id = arguments['status_id'] if arguments['status_id'].present?
      issue.priority_id = arguments['priority_id'] if arguments['priority_id'].present?
      issue.assigned_to_id = arguments['assigned_to_id'] if arguments['assigned_to_id'].present?
      issue.notes = arguments['notes'] if arguments['notes'].present?

      if issue.save
        {
          success: true,
          issue: format_issue(issue)
        }
      else
        format_error("Failed to update issue: #{issue.errors.full_messages.join(', ')}")
      end
    rescue => e
      format_error(e.message)
    end

    def format_issue(issue, include_journals: false)
      data = {
        id: issue.id,
        project: { id: issue.project_id, name: issue.project.name },
        tracker: { id: issue.tracker_id, name: issue.tracker.name },
        status: { id: issue.status_id, name: issue.status.name },
        priority: { id: issue.priority_id, name: issue.priority.name },
        author: { id: issue.author_id, name: issue.author.name },
        subject: issue.subject,
        description: issue.description,
        created_on: issue.created_on,
        updated_on: issue.updated_on,
        closed_on: issue.closed_on
      }

      data[:assigned_to] = { id: issue.assigned_to_id, name: issue.assigned_to.name } if issue.assigned_to
      data[:due_date] = issue.due_date if issue.due_date
      data[:done_ratio] = issue.done_ratio if issue.done_ratio

      if include_journals
        data[:journals] = issue.journals.visible.order(created_on: :asc).map do |journal|
          {
            id: journal.id,
            user: { id: journal.user_id, name: journal.user.name },
            notes: journal.notes,
            created_on: journal.created_on
          }
        end
      end

      data
    end
  end
end
