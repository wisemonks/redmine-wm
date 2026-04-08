class McpServer
  PROTOCOL_VERSION = '2024-11-05'
  
  def initialize(user)
    @user = user
    @tools = load_tools
  end

  def handle_request(request)
    method = request['method']
    id = request['id']
    params = request['params'] || {}

    case method
    when 'initialize'
      handle_initialize(id, params)
    when 'tools/list'
      handle_tools_list(id, params)
    when 'tools/call'
      handle_tool_call(id, params)
    else
      json_rpc_error(id, -32601, 'Method not found')
    end
  rescue => e
    Rails.logger.error "MCP Server Error: #{e.message}\n#{e.backtrace.join("\n")}"
    json_rpc_error(id, -32603, "Internal error: #{e.message}")
  end

  private

  def handle_initialize(id, params)
    {
      jsonrpc: '2.0',
      id: id,
      result: {
        protocolVersion: PROTOCOL_VERSION,
        capabilities: {
          tools: {}
        },
        serverInfo: {
          name: 'redmine-mcp',
          version: '1.0.0'
        }
      }
    }
  end

  def handle_tools_list(id, params)
    tool_definitions = @tools.flat_map(&:definitions)
    
    {
      jsonrpc: '2.0',
      id: id,
      result: {
        tools: tool_definitions
      }
    }
  end

  def handle_tool_call(id, params)
    tool_name = params['name']
    arguments = params['arguments'] || {}

    tool = @tools.find { |t| t.has_tool?(tool_name) }
    
    unless tool
      return json_rpc_error(id, -32602, "Tool not found: #{tool_name}")
    end

    result = tool.execute(tool_name, arguments, @user)
    
    {
      jsonrpc: '2.0',
      id: id,
      result: {
        content: [
          {
            type: 'text',
            text: result.to_json
          }
        ]
      }
    }
  rescue => e
    Rails.logger.error "Tool execution error: #{e.message}\n#{e.backtrace.join("\n")}"
    json_rpc_error(id, -32603, "Tool execution failed: #{e.message}")
  end

  def load_tools
    [
      McpTools::IssueTools.new,
      McpTools::ProjectTools.new,
      McpTools::UserTools.new,
      McpTools::TimeEntryTools.new
    ]
  end

  def json_rpc_error(id, code, message, data = nil)
    error = {
      jsonrpc: '2.0',
      id: id,
      error: {
        code: code,
        message: message
      }
    }
    error[:error][:data] = data if data
    error
  end
end
