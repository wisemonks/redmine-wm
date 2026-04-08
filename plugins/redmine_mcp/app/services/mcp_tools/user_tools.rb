module McpTools
  class UserTools < BaseTool
    def definitions
      [
        {
          name: 'list_users',
          description: 'List active users with pagination',
          inputSchema: {
            type: 'object',
            properties: {
              name: { type: 'string', description: 'Filter by name (partial match)' },
              limit: { type: 'integer', description: 'Number of results (max 100)', default: 25 },
              offset: { type: 'integer', description: 'Offset for pagination', default: 0 }
            }
          }
        },
        {
          name: 'get_current_user',
          description: 'Get information about the currently authenticated user',
          inputSchema: {
            type: 'object',
            properties: {}
          }
        }
      ]
    end

    def execute(tool_name, arguments, user)
      check_permission(user, :view_users)

      case tool_name
      when 'list_users'
        list_users(arguments, user)
      when 'get_current_user'
        get_current_user(user)
      else
        format_error("Unknown tool: #{tool_name}")
      end
    end

    private

    def list_users(arguments, user)
      scope = User.active.visible

      if arguments['name'].present?
        scope = scope.like(arguments['name'])
      end

      scope = scope.order(lastname: :asc, firstname: :asc)
      result = paginate(scope, arguments)

      {
        users: result[:items].map { |u| format_user(u) },
        total_count: result[:total_count],
        limit: result[:limit],
        offset: result[:offset]
      }
    rescue => e
      format_error(e.message)
    end

    def get_current_user(user)
      {
        user: format_user(user, detailed: true)
      }
    rescue => e
      format_error(e.message)
    end

    def format_user(user, detailed: false)
      data = {
        id: user.id,
        login: user.login,
        firstname: user.firstname,
        lastname: user.lastname,
        name: user.name,
        mail: user.mail,
        admin: user.admin?,
        created_on: user.created_on,
        updated_on: user.updated_on,
        last_login_on: user.last_login_on
      }

      if detailed
        data[:api_key] = user.api_key if user.api_key.present?
        data[:status] = user.status
        data[:language] = user.language
        data[:custom_fields] = user.visible_custom_field_values.map do |cfv|
          { name: cfv.custom_field.name, value: cfv.value }
        end
      end

      data
    end
  end
end
