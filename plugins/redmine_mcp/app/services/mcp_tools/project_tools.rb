module McpTools
  class ProjectTools < BaseTool
    def definitions
      [
        {
          name: 'list_projects',
          description: 'List all visible projects with pagination',
          inputSchema: {
            type: 'object',
            properties: {
              limit: { type: 'integer', description: 'Number of results (max 100)', default: 25 },
              offset: { type: 'integer', description: 'Offset for pagination', default: 0 }
            }
          }
        },
        {
          name: 'get_project',
          description: 'Get detailed information about a specific project',
          inputSchema: {
            type: 'object',
            properties: {
              project_id: { type: 'string', description: 'Project ID or identifier', required: true }
            },
            required: ['project_id']
          }
        }
      ]
    end

    def execute(tool_name, arguments, user)
      check_permission(user, :view_projects)

      case tool_name
      when 'list_projects'
        list_projects(arguments, user)
      when 'get_project'
        get_project(arguments, user)
      else
        format_error("Unknown tool: #{tool_name}")
      end
    end

    private

    def list_projects(arguments, user)
      scope = Project.visible(user).active.order(name: :asc)
      result = paginate(scope, arguments)

      {
        projects: result[:items].map { |project| format_project(project) },
        total_count: result[:total_count],
        limit: result[:limit],
        offset: result[:offset]
      }
    rescue => e
      format_error(e.message)
    end

    def get_project(arguments, user)
      project = Project.visible(user).find_by(id: arguments['project_id']) ||
                Project.visible(user).find_by(identifier: arguments['project_id'])
      
      unless project
        return format_error("Project not found or not accessible")
      end

      {
        project: format_project(project, detailed: true)
      }
    rescue => e
      format_error(e.message)
    end

    def format_project(project, detailed: false)
      data = {
        id: project.id,
        identifier: project.identifier,
        name: project.name,
        description: project.description,
        status: project.status,
        is_public: project.is_public,
        created_on: project.created_on,
        updated_on: project.updated_on
      }

      if detailed
        data[:trackers] = project.trackers.map { |t| { id: t.id, name: t.name } }
        data[:issue_categories] = project.issue_categories.map { |c| { id: c.id, name: c.name } }
        data[:enabled_modules] = project.enabled_modules.map(&:name)
        data[:parent] = { id: project.parent_id, name: project.parent.name } if project.parent
      end

      data
    end
  end
end
