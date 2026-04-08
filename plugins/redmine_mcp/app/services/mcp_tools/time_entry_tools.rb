module McpTools
  class TimeEntryTools < BaseTool
    def definitions
      [
        {
          name: 'list_time_entries',
          description: 'List time entries with optional filters and pagination',
          inputSchema: {
            type: 'object',
            properties: {
              project_id: { type: 'string', description: 'Filter by project ID' },
              issue_id: { type: 'string', description: 'Filter by issue ID' },
              user_id: { type: 'string', description: 'Filter by user ID' },
              from: { type: 'string', description: 'Filter entries from date (YYYY-MM-DD)' },
              to: { type: 'string', description: 'Filter entries to date (YYYY-MM-DD)' },
              limit: { type: 'integer', description: 'Number of results (max 100)', default: 25 },
              offset: { type: 'integer', description: 'Offset for pagination', default: 0 }
            }
          }
        },
        {
          name: 'create_time_entry',
          description: 'Log time against an issue or project',
          inputSchema: {
            type: 'object',
            properties: {
              issue_id: { type: 'string', description: 'Issue ID (required if project_id not provided)' },
              project_id: { type: 'string', description: 'Project ID (required if issue_id not provided)' },
              hours: { type: 'number', description: 'Hours spent', required: true },
              activity_id: { type: 'string', description: 'Activity ID' },
              comments: { type: 'string', description: 'Description of work done' },
              spent_on: { type: 'string', description: 'Date (YYYY-MM-DD), defaults to today' }
            },
            required: ['hours']
          }
        }
      ]
    end

    def execute(tool_name, arguments, user)
      check_permission(user, :view_time_entries)

      case tool_name
      when 'list_time_entries'
        list_time_entries(arguments, user)
      when 'create_time_entry'
        create_time_entry(arguments, user)
      else
        format_error("Unknown tool: #{tool_name}")
      end
    end

    private

    def list_time_entries(arguments, user)
      scope = TimeEntry.visible(user)

      scope = scope.where(project_id: arguments['project_id']) if arguments['project_id'].present?
      scope = scope.where(issue_id: arguments['issue_id']) if arguments['issue_id'].present?
      scope = scope.where(user_id: arguments['user_id']) if arguments['user_id'].present?
      
      if arguments['from'].present?
        begin
          from_date = Date.parse(arguments['from'])
          scope = scope.where('spent_on >= ?', from_date)
        rescue ArgumentError
          return format_error("Invalid 'from' date format. Use YYYY-MM-DD")
        end
      end

      if arguments['to'].present?
        begin
          to_date = Date.parse(arguments['to'])
          scope = scope.where('spent_on <= ?', to_date)
        rescue ArgumentError
          return format_error("Invalid 'to' date format. Use YYYY-MM-DD")
        end
      end

      scope = scope.order(spent_on: :desc)
      result = paginate(scope, arguments)

      {
        time_entries: result[:items].map { |entry| format_time_entry(entry) },
        total_count: result[:total_count],
        total_hours: result[:items].sum(&:hours),
        limit: result[:limit],
        offset: result[:offset]
      }
    rescue => e
      format_error(e.message)
    end

    def create_time_entry(arguments, user)
      unless arguments['issue_id'].present? || arguments['project_id'].present?
        return format_error("Either issue_id or project_id must be provided")
      end

      time_entry = TimeEntry.new
      time_entry.user = user
      time_entry.hours = arguments['hours']
      time_entry.comments = arguments['comments'] if arguments['comments'].present?
      time_entry.activity_id = arguments['activity_id'] if arguments['activity_id'].present?
      
      if arguments['spent_on'].present?
        begin
          time_entry.spent_on = Date.parse(arguments['spent_on'])
        rescue ArgumentError
          return format_error("Invalid 'spent_on' date format. Use YYYY-MM-DD")
        end
      else
        time_entry.spent_on = Date.today
      end

      if arguments['issue_id'].present?
        issue = Issue.visible(user).find_by(id: arguments['issue_id'])
        unless issue
          return format_error("Issue not found or not accessible")
        end
        time_entry.issue = issue
        time_entry.project = issue.project
      elsif arguments['project_id'].present?
        project = Project.visible(user).find_by(id: arguments['project_id'])
        unless project
          return format_error("Project not found or not accessible")
        end
        time_entry.project = project
      end

      unless user.allowed_to?(:log_time, time_entry.project)
        return format_error("Permission denied to log time in this project")
      end

      if time_entry.save
        {
          success: true,
          time_entry: format_time_entry(time_entry)
        }
      else
        format_error("Failed to create time entry: #{time_entry.errors.full_messages.join(', ')}")
      end
    rescue => e
      format_error(e.message)
    end

    def format_time_entry(entry)
      data = {
        id: entry.id,
        project: { id: entry.project_id, name: entry.project.name },
        user: { id: entry.user_id, name: entry.user.name },
        activity: { id: entry.activity_id, name: entry.activity.name },
        hours: entry.hours,
        comments: entry.comments,
        spent_on: entry.spent_on,
        created_on: entry.created_on,
        updated_on: entry.updated_on
      }

      if entry.issue
        data[:issue] = { id: entry.issue_id, subject: entry.issue.subject }
      end

      data
    end
  end
end
