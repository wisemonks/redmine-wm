class McpController < ApplicationController
  accept_api_auth :handle, :health
  skip_before_action :verify_authenticity_token

  def handle
    request_data = parse_request_body

    if request_data.nil?
      render json: json_rpc_error(-32700, 'Parse error'), status: :bad_request
      return
    end

    server = McpServer.new(User.current)
    response_data = server.handle_request(request_data)
    
    render json: response_data
  rescue => e
    Rails.logger.error "MCP Error: #{e.message}\n#{e.backtrace.join("\n")}"
    render json: json_rpc_error(-32603, "Internal error: #{e.message}"), status: :internal_server_error
  end

  def health
    render json: { 
      status: 'ok', 
      version: '1.0.0', 
      protocol_version: '2024-11-05',
      server_info: {
        name: 'redmine-mcp',
        vendor: 'WiseMonks'
      }
    }
  end

  private

  def parse_request_body
    JSON.parse(request.body.read)
  rescue JSON::ParserError
    nil
  end

  def json_rpc_error(code, message, data = nil)
    error = {
      jsonrpc: '2.0',
      error: {
        code: code,
        message: message
      }
    }
    error[:error][:data] = data if data
    error
  end
end
