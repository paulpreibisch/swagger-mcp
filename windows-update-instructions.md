# Update Windows swagger-mcp Installation

## 🪟 Windows Commands (Run in Command Prompt or PowerShell)

### Step 1: Remove Old Installation
```cmd
# Check current installation
where swagger-mcp

# Remove old version (if needed)
go clean -modcache
```

### Step 2: Install Fixed Version from Your Fork
```cmd
# Install from your fork with the fix
go install github.com/paulpreibisch/swagger-mcp@fix-mcp-json-output
```

### Step 3: Verify Installation
```cmd
# Check the --quiet flag is available
swagger-mcp --help | findstr quiet
```

Should show:
```
-quiet
    Suppress endpoint discovery output for MCP integration
```

### Step 4: Update Claude Desktop Config

Edit `%APPDATA%\Claude\claude_desktop_config.json`:

```json
{
  "mcpServers": {
    "soraorc_swagger": {
      "command": "swagger-mcp",
      "args": [
        "--specUrl=http://morpheus.test:5222/swagger.json",
        "--baseUrl=http://morpheus.test:5211",
        "--quiet"
      ]
    }
  }
}
```

### Step 5: Restart Claude Desktop

Close and reopen Claude Desktop to apply the changes.

## 🧪 Testing

1. Check MCP tools list in Claude Desktop - should see swagger tools
2. Check logs at `%APPDATA%\Claude\logs\mcp-server-soraorc_swagger.log`
3. Should see NO more "Unexpected token" errors!

## 🔄 Alternative: Use WSL Version

If Windows installation has issues, you can use the WSL version via your existing config:

```json
{
  "mcpServers": {
    "soraorc_swagger": {
      "command": "wsl",
      "args": [
        "-e", "bash", "-c",
        "export PATH=$PATH:/home/fire/go/bin && swagger-mcp --specUrl=http://morpheus.test:5222/swagger.json --baseUrl=http://morpheus.test:5211 --quiet"
      ]
    }
  }
}
```