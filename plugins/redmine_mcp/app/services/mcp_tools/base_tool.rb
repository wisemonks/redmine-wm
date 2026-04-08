module McpTools
  class BaseTool
    def definitions
      raise NotImplementedError, "Subclasses must implement #definitions"
    end

    def has_tool?(tool_name)
      definitions.any? { |d| d[:name] == tool_name }
    end

    def execute(tool_name, arguments, user)
      raise NotImplementedError, "Subclasses must implement #execute"
    end

    protected

    def check_permission(user, action, object = nil)
      unless user && user.logged?
        raise "Authentication required"
      end

      if object && !object.visible?(user)
        raise "Permission denied"
      end

      true
    end

    def paginate(collection, arguments)
      limit = [arguments['limit'].to_i, 100].min
      limit = 25 if limit <= 0
      offset = [arguments['offset'].to_i, 0].max

      {
        items: collection.limit(limit).offset(offset),
        total_count: collection.count,
        limit: limit,
        offset: offset
      }
    end

    def format_error(message)
      { error: message }
    end
  end
end
