# MCP Transport Configuration Examples

This document provides configuration examples for the new MCP HTTP+SSE transport implementation in the Redmine AI Helper plugin.

## Auto-Detection

Transport type is automatically detected based on configuration:
- **STDIO**: When `command` or `args` is present
- **HTTP**: When `url` is present

No explicit `transport` field is required.

## STDIO Transport Examples

### Basic Command Configuration
```json
{
  "mcpServers": {
    "filesystem": {
      "command": "npx",
      "args": ["-y", "@modelcontextprotocol/server-filesystem", "/tmp"]
    }
  }
}
```

### With Environment Variables
```json
{
  "mcpServers": {
    "slack": {
      "command": "npx",
      "args": ["-y", "@modelcontextprotocol/server-slack"],
      "env": {
        "SLACK_BOT_TOKEN": "xoxb-your-bot-token",
        "SLACK_TEAM_ID": "T01234567"
      }
    }
  }
}
```

### Args Only Configuration
```json
{
  "mcpServers": {
    "custom_server": {
      "args": ["node", "/path/to/custom-server.js", "--debug"]
    }
  }
}
```

## HTTP Transport Examples

### Basic HTTP Configuration
```json
{
  "mcpServers": {
    "remote_api": {
      "url": "http://localhost:3000"
    }
  }
}
```

### HTTPS with Authentication
```json
{
  "mcpServers": {
    "secure_api": {
      "url": "https://api.example.com",
      "headers": {
        "Authorization": "Bearer your-api-token",
        "X-API-Key": "your-api-key"
      },
      "timeout": 60
    }
  }
}
```

### HTTP with Custom Settings
```json
{
  "mcpServers": {
    "production_api": {
      "url": "https://mcp.production.com",
      "timeout": 45,
      "reconnect": true,
      "max_retries": 5,
      "headers": {
        "User-Agent": "Redmine-AI-Helper/1.0"
      }
    }
  }
}
```

## Mixed Transport Configuration

You can use both STDIO and HTTP transports in the same configuration:

```json
{
  "mcpServers": {
    "local_filesystem": {
      "command": "npx",
      "args": ["-y", "@modelcontextprotocol/server-filesystem", "/home/user/projects"]
    },
    "remote_database": {
      "url": "https://db-api.example.com",
      "headers": {
        "Authorization": "Bearer db-access-token"
      }
    },
    "local_git": {
      "command": "python",
      "args": ["/usr/local/bin/git-mcp-server.py"],
      "env": {
        "GIT_REPO_PATH": "/home/user/repos"
      }
    },
    "cloud_storage": {
      "url": "https://storage-api.cloud.com",
      "timeout": 120,
      "headers": {
        "X-Storage-Key": "storage-key"
      }
    }
  }
}
```

## Configuration File Location

Place your configuration file at:
```
/path/to/redmine/config/ai_helper/config.json
```

## HTTP Transport Features

### Supported Features
- ✅ Server-Sent Events (SSE) for real-time communication
- ✅ Custom headers for authentication
- ✅ Configurable timeouts
- ✅ Automatic reconnection
- ✅ Exponential backoff retry logic
- ✅ HTTPS/TLS support
- ✅ Session management

### Configuration Options

| Option | Type | Default | Description |
|--------|------|---------|-------------|
| `url` | string | required | MCP server base URL |
| `headers` | object | `{}` | Custom HTTP headers |
| `timeout` | number | `30` | Request timeout in seconds |
| `reconnect` | boolean | `false` | Enable automatic reconnection |
| `max_retries` | number | `3` | Maximum retry attempts |

## Error Handling

The HTTP transport includes comprehensive error handling:

- **Connection errors**: Automatic retry with exponential backoff
- **Timeout errors**: Configurable timeout with clear error messages
- **HTTP errors**: Proper status code handling (4xx, 5xx)
- **JSON parsing errors**: Graceful handling of malformed responses
- **SSE connection issues**: Automatic reconnection when enabled

## Migration from Old Configuration

The system automatically handles legacy configurations. No manual migration is required:

**Old format** (still supported):
```json
{
  "mcpServers": {
    "server": {
      "command": "npx",
      "args": ["-y", "server"]
    }
  }
}
```

**New format** (equivalent):
```json
{
  "mcpServers": {
    "server": {
      "command": "npx",
      "args": ["-y", "server"]
    }
  }
}
```

No changes needed - the system automatically detects the transport type!

## Testing Your Configuration

You can test your MCP transport configuration:

1. **Check logs**: Look for MCP connection messages in Redmine logs
2. **Use Rails console**: Test transport creation manually
3. **Monitor network**: For HTTP transports, monitor network requests

### Rails Console Testing

```ruby
# Test STDIO transport
config = { 'command' => 'echo', 'args' => ['test'] }
transport = RedmineAiHelper::Transport::TransportFactory.create(config)
puts transport.class.name # => RedmineAiHelper::Transport::StdioTransport

# Test HTTP transport  
config = { 'url' => 'http://localhost:3000' }
transport = RedmineAiHelper::Transport::TransportFactory.create(config)
puts transport.class.name # => RedmineAiHelper::Transport::HttpSseTransport
```

## Troubleshooting

### Common Issues

1. **"Cannot determine transport type"**
   - Ensure your configuration has either `command`/`args` OR `url`
   - Check JSON syntax validity

2. **HTTP connection failures**
   - Verify the URL is accessible
   - Check firewall settings
   - Ensure the MCP server supports SSE

3. **STDIO command not found**
   - Verify the command exists in PATH
   - Check file permissions
   - Ensure all required dependencies are installed

### Debug Mode

Enable debug logging to troubleshoot issues:

```ruby
# In Rails console
Rails.logger.level = :debug
```

This will show detailed transport initialization and communication logs.