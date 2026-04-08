# Redmine MCP Plugin - Testing Guide

## Quick Start Testing

### 1. Restart Redmine

```bash
# If using Passenger
touch /path/to/redmine/tmp/restart.txt

# If using systemd
sudo systemctl restart redmine

# If using Docker
docker restart redmine-container
```

### 2. Verify Plugin is Loaded

Check in Redmine:
- Go to **Administration → Plugins**
- Look for "Redmine MCP Plugin v1.0.0"

### 3. Get Your API Key

1. Log into Redmine
2. Go to **My Account** (top right)
3. Click on **API access key** section
4. Click **Show** or **Generate** to get your key
5. Copy the key (you'll need it for testing)

### 4. Test Health Endpoint

```bash
# Test the health endpoint (no auth required)
curl http://localhost:3000/mcp/health

# Expected response:
# {
#   "status": "ok",
#   "version": "1.0.0",
#   "protocol_version": "2024-11-05",
#   "server_info": {
#     "name": "redmine-mcp",
#     "vendor": "WiseMonks"
#   }
# }
```

### 5. Test MCP Initialize

```bash
# Replace YOUR_API_KEY with your actual API key
curl -X POST http://localhost:3000/mcp \
  -H "Content-Type: application/json" \
  -H "X-Redmine-API-Key: YOUR_API_KEY" \
  -d '{
    "jsonrpc": "2.0",
    "id": 1,
    "method": "initialize",
    "params": {}
  }'

# Expected response:
# {
#   "jsonrpc": "2.0",
#   "id": 1,
#   "result": {
#     "protocolVersion": "2024-11-05",
#     "capabilities": {
#       "tools": {}
#     },
#     "serverInfo": {
#       "name": "redmine-mcp",
#       "version": "1.0.0"
#     }
#   }
# }
```

### 6. Test Tools List

```bash
curl -X POST http://localhost:3000/mcp \
  -H "Content-Type: application/json" \
  -H "X-Redmine-API-Key: YOUR_API_KEY" \
  -d '{
    "jsonrpc": "2.0",
    "id": 2,
    "method": "tools/list",
    "params": {}
  }'

# Expected: List of 10 tools
```

### 7. Test List Issues

```bash
curl -X POST http://localhost:3000/mcp \
  -H "Content-Type: application/json" \
  -H "X-Redmine-API-Key: YOUR_API_KEY" \
  -d '{
    "jsonrpc": "2.0",
    "id": 3,
    "method": "tools/call",
    "params": {
      "name": "list_issues",
      "arguments": {
        "limit": 5
      }
    }
  }'
```

## Configure in Mattermost

### Step 1: Access MCP Settings

1. Log into Mattermost as System Admin
2. Go to **System Console**
3. Navigate to **Plugins → Agents → MCP Servers**
4. Ensure **Enable MCP** is set to **True**

### Step 2: Add Redmine MCP Server

1. Click **Add MCP Server**
2. Fill in the form:
   - **Server URL**: `http://your-redmine-server:3000/mcp`
   - **Server Name**: `Redmine Production`
   - **Custom Headers**:
     ```json
     {
       "X-Redmine-API-Key": "paste_your_api_key_here"
     }
     ```
3. Click **Save**

### Step 3: Test with AI Agent

1. Open a DM with your AI agent in Mattermost
2. Try these commands:
   - "List my open issues in Redmine"
   - "Show me all projects I have access to"
   - "Create a new issue in project 1 with subject 'Test from AI'"
   - "Show me my user information from Redmine"

## Troubleshooting

### Plugin Not Loading

**Check Redmine logs:**
```bash
tail -f /path/to/redmine/log/production.log | grep -i "mcp\|plugin"
```

**Common issues:**
- Syntax errors in Ruby files
- Missing dependencies
- File permissions

### Routes Not Working

**Test if routes are registered:**
```bash
# In Redmine console
bundle exec rails routes | grep mcp
```

**Expected output:**
```
POST   /mcp          mcp#handle
GET    /mcp/health   mcp#health
```

### Authentication Failing

**Check API key is valid:**
```bash
# Test with Redmine API
curl -H "X-Redmine-API-Key: YOUR_KEY" http://localhost:3000/users/current.json
```

**If this fails, your API key is invalid**

### Tool Execution Errors

**Enable debug logging:**

Edit `config/additional_environment.rb`:
```ruby
config.log_level = :debug
```

**Check logs for detailed errors:**
```bash
tail -f log/production.log
```

## Testing Checklist

- [ ] Plugin appears in Administration → Plugins
- [ ] Health endpoint returns 200 OK
- [ ] Initialize method works with API key
- [ ] Tools list returns 10 tools
- [ ] list_issues tool works
- [ ] get_issue tool works
- [ ] create_issue tool works
- [ ] update_issue tool works
- [ ] list_projects tool works
- [ ] get_project tool works
- [ ] list_users tool works
- [ ] get_current_user tool works
- [ ] list_time_entries tool works
- [ ] create_time_entry tool works
- [ ] Mattermost can connect to MCP server
- [ ] AI agent can execute Redmine commands

## Production Deployment

### 1. Use HTTPS

Update Mattermost MCP server URL to:
```
https://your-redmine.com/mcp
```

### 2. Configure Firewall

Allow Mattermost server IP to access Redmine:
```bash
# Example with ufw
sudo ufw allow from MATTERMOST_IP to any port 443
```

### 3. Monitor Usage

Set up log monitoring:
```bash
# Watch for MCP requests
tail -f /path/to/redmine/log/production.log | grep "MCP"
```

### 4. Security Hardening

- Use strong API keys
- Rotate keys regularly
- Monitor for unusual activity
- Set up rate limiting (if needed)
- Use VPN for internal deployments

## Next Steps

1. **Test all tools** using the curl commands above
2. **Configure in Mattermost** following the steps
3. **Test with AI agent** to verify end-to-end functionality
4. **Monitor logs** for any errors
5. **Deploy to production** with HTTPS

## Support

If you encounter issues:
1. Check Redmine logs
2. Check Mattermost logs
3. Verify network connectivity
4. Test with curl commands
5. Review the README.md for detailed documentation
