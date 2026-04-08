# Redmine MCP Plugin

Model Context Protocol (MCP) server for Redmine, enabling AI agents to interact with Redmine via a standardized protocol.

## Overview

This plugin exposes Redmine's core functionality through an MCP-compliant HTTP endpoint, allowing AI agents like Mattermost Agents, Claude, or custom agents to perform common Redmine operations.

## Features

- **MCP Protocol Support**: Implements MCP 2024-11-05 specification
- **API Key Authentication**: Uses Redmine's existing API key system
- **Permission-Aware**: Respects all Redmine permissions and visibility rules
- **10 Core Tools**: Issues, Projects, Users, and Time Entries operations

## Requirements

- Redmine 4.0 or later
- Ruby 2.5 or later
- Mattermost Server 11.2+ (for Mattermost Agents integration)
- Mattermost Agents Plugin 1.4.0+ (for MCP custom headers support)

## Installation

1. Copy the plugin to your Redmine plugins directory:
   ```bash
   cd /path/to/redmine/plugins
   git clone https://github.com/wisemonks/redmine-mcp.git redmine_mcp
   ```

2. Restart Redmine:
   ```bash
   sudo systemctl restart redmine
   # or
   touch /path/to/redmine/tmp/restart.txt
   ```

3. Verify the plugin is installed:
   - Go to Administration → Plugins
   - Look for "Redmine MCP Plugin"

## Configuration

### For Redmine Users

1. **Generate API Key**:
   - Log into Redmine
   - Go to "My Account" → "API access key"
   - Click "Show" or "Generate" to get your API key
   - Save this key securely

### For Mattermost Administrators

1. **Add MCP Server in Mattermost**:
   - Go to System Console → Plugins → Agents → MCP Servers
   - Click "Add MCP Server"
   - Configure:
     - **Server URL**: `https://your-redmine.com/mcp`
     - **Server Name**: `Redmine Production`
     - **Custom Headers**:
       ```json
       {
         "X-Redmine-API-Key": "paste_your_api_key_here"
       }
       ```
   - Click "Save"

2. **Test Connection**:
   - Open a DM with your AI agent in Mattermost
   - Try: "List my open issues in Redmine"
   - The agent should connect and return your issues

## Available Tools

### Issues (4 tools)

#### list_issues
List issues with optional filters and pagination.

**Parameters**:
- `project_id` (string, optional): Filter by project ID
- `status_id` (string, optional): Filter by status (open, closed, or specific ID)
- `assigned_to_id` (string, optional): Filter by assigned user ID
- `tracker_id` (string, optional): Filter by tracker ID
- `limit` (integer, optional): Number of results (max 100, default 25)
- `offset` (integer, optional): Offset for pagination (default 0)

**Example**:
```
"List all open issues assigned to me in project 5"
```

#### get_issue
Get detailed information about a specific issue including journals/comments.

**Parameters**:
- `issue_id` (string, required): Issue ID

**Example**:
```
"Show me details of issue #123"
```

#### create_issue
Create a new issue.

**Parameters**:
- `project_id` (string, required): Project ID
- `subject` (string, required): Issue subject
- `description` (string, optional): Issue description
- `tracker_id` (string, optional): Tracker ID
- `status_id` (string, optional): Status ID
- `priority_id` (string, optional): Priority ID
- `assigned_to_id` (string, optional): Assigned user ID

**Example**:
```
"Create a bug in project 5 with subject 'Login page not working'"
```

#### update_issue
Update an existing issue.

**Parameters**:
- `issue_id` (string, required): Issue ID
- `subject` (string, optional): New subject
- `description` (string, optional): New description
- `status_id` (string, optional): New status ID
- `priority_id` (string, optional): New priority ID
- `assigned_to_id` (string, optional): New assigned user ID
- `notes` (string, optional): Add a comment/note

**Example**:
```
"Update issue #123 status to closed and add note 'Fixed in version 2.0'"
```

### Projects (2 tools)

#### list_projects
List all visible projects with pagination.

**Parameters**:
- `limit` (integer, optional): Number of results (max 100, default 25)
- `offset` (integer, optional): Offset for pagination (default 0)

**Example**:
```
"List all projects I have access to"
```

#### get_project
Get detailed information about a specific project.

**Parameters**:
- `project_id` (string, required): Project ID or identifier

**Example**:
```
"Show me details of project 'website-redesign'"
```

### Users (2 tools)

#### list_users
List active users with pagination.

**Parameters**:
- `name` (string, optional): Filter by name (partial match)
- `limit` (integer, optional): Number of results (max 100, default 25)
- `offset` (integer, optional): Offset for pagination (default 0)

**Example**:
```
"List all users with name containing 'John'"
```

#### get_current_user
Get information about the currently authenticated user.

**Example**:
```
"Show me my user information"
```

### Time Entries (2 tools)

#### list_time_entries
List time entries with optional filters and pagination.

**Parameters**:
- `project_id` (string, optional): Filter by project ID
- `issue_id` (string, optional): Filter by issue ID
- `user_id` (string, optional): Filter by user ID
- `from` (string, optional): Filter entries from date (YYYY-MM-DD)
- `to` (string, optional): Filter entries to date (YYYY-MM-DD)
- `limit` (integer, optional): Number of results (max 100, default 25)
- `offset` (integer, optional): Offset for pagination (default 0)

**Example**:
```
"Show me time entries for project 5 from last week"
```

#### create_time_entry
Log time against an issue or project.

**Parameters**:
- `issue_id` (string, optional): Issue ID (required if project_id not provided)
- `project_id` (string, optional): Project ID (required if issue_id not provided)
- `hours` (number, required): Hours spent
- `activity_id` (string, optional): Activity ID
- `comments` (string, optional): Description of work done
- `spent_on` (string, optional): Date (YYYY-MM-DD), defaults to today

**Example**:
```
"Log 2.5 hours on issue #123 for development work"
```

## API Endpoint

### POST /mcp
Main MCP endpoint for JSON-RPC requests.

**Authentication**: X-Redmine-API-Key header

**Request Format**:
```json
{
  "jsonrpc": "2.0",
  "id": 1,
  "method": "tools/call",
  "params": {
    "name": "list_issues",
    "arguments": {
      "project_id": "5",
      "status_id": "open",
      "limit": 10
    }
  }
}
```

**Response Format**:
```json
{
  "jsonrpc": "2.0",
  "id": 1,
  "result": {
    "content": [
      {
        "type": "text",
        "text": "{\"issues\": [...], \"total_count\": 42}"
      }
    ]
  }
}
```

### GET /mcp/health
Health check endpoint.

**Response**:
```json
{
  "status": "ok",
  "version": "1.0.0",
  "protocol_version": "2024-11-05",
  "server_info": {
    "name": "redmine-mcp",
    "vendor": "WiseMonks"
  }
}
```

## Security

### Authentication
- Uses Redmine's existing API key authentication
- Each request must include `X-Redmine-API-Key` header
- API keys are managed through Redmine's user settings

### Permissions
- All operations respect Redmine's permission system
- Users can only access resources they have permission to view
- Tool execution checks user permissions before performing actions

### Best Practices
1. **Use HTTPS**: Always use HTTPS in production
2. **Rotate API Keys**: Periodically rotate API keys
3. **Revoke Compromised Keys**: Immediately revoke compromised keys
4. **Monitor Usage**: Monitor API key usage in Redmine logs
5. **Network Security**: Use firewall rules and VPN for sensitive deployments

## Troubleshooting

### Connection Issues

**Problem**: Mattermost can't connect to Redmine MCP server

**Solutions**:
1. Check Redmine is accessible from Mattermost server
2. Verify the URL is correct: `https://your-redmine.com/mcp`
3. Check firewall rules allow traffic
4. Test with curl:
   ```bash
   curl -X POST https://your-redmine.com/mcp \
     -H "Content-Type: application/json" \
     -H "X-Redmine-API-Key: your_key" \
     -d '{"jsonrpc":"2.0","id":1,"method":"initialize","params":{}}'
   ```

### Authentication Issues

**Problem**: "Authentication required" error

**Solutions**:
1. Verify API key is correct
2. Check API key is active in Redmine (My Account → API access key)
3. Ensure custom header is configured correctly in Mattermost
4. Check Redmine logs for authentication errors:
   ```bash
   tail -f /path/to/redmine/log/production.log
   ```

### Permission Issues

**Problem**: "Permission denied" errors

**Solutions**:
1. Verify user has required permissions in Redmine
2. Check project membership and roles
3. Ensure user has API access enabled
4. Review Redmine permission settings for the project

### Tool Execution Issues

**Problem**: Tools return errors or unexpected results

**Solutions**:
1. Check Redmine logs for detailed error messages
2. Verify tool parameters are correct
3. Test the equivalent operation in Redmine UI
4. Check for plugin conflicts

## Development

### Running Tests
```bash
cd /path/to/redmine
bundle exec rake redmine:plugins:test NAME=redmine_mcp
```

### Checking Logs
```bash
# Redmine logs
tail -f log/production.log

# Filter for MCP-related entries
tail -f log/production.log | grep -i mcp
```

### Debugging
Enable debug logging in Redmine's `config/additional_environment.rb`:
```ruby
config.log_level = :debug
```

## Support

- **Issues**: https://github.com/wisemonks/redmine-mcp/issues
- **Documentation**: https://github.com/wisemonks/redmine-mcp/wiki
- **Email**: support@wisemonks.com

## License

This plugin is licensed under the MIT License.

## Credits

Developed by WiseMonks for the Redmine and Mattermost communities.

## Changelog

### Version 1.0.0 (2026-04-08)
- Initial release
- MCP protocol support (2024-11-05)
- 10 core tools: Issues, Projects, Users, Time Entries
- API key authentication via custom headers
- Permission-aware operations
