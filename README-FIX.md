# Claude Desktop MCP Integration Fix

## 🔧 Problem Solved

**Issue**: Claude Desktop JSON parse errors when using swagger-mcp:
```
Unexpected token 'S', 'Starting s'... is not valid JSON
Unexpected token 'E', "Endpoint: "... is not valid JSON
Unexpected token 'M', "Method: GET" is not valid JSON
```

**Root Cause**: swagger-mcp outputs endpoint discovery information before entering JSON-RPC mode, breaking Claude Desktop's JSON parser.

## ✅ Solution: `--quiet` Flag

Added a `--quiet` flag that suppresses endpoint discovery output for clean MCP integration.

### Changes Made:
1. **main.go**: Added `--quiet` flag parameter
2. **models.go**: Added `Quiet bool` field to Config struct  
3. **extracter.go**: Modified `ExtractSwagger()` to skip output when quiet mode enabled

### Usage:

```bash
# Normal mode (shows endpoint discovery)
swagger-mcp --specUrl=http://api.test/swagger.json --baseUrl=http://api.test

# Quiet mode (JSON-RPC only, perfect for Claude Desktop)
swagger-mcp --specUrl=http://api.test/swagger.json --baseUrl=http://api.test --quiet
```

## 🚀 Installation for Claude Desktop

### Step 1: Build and Install Fixed Version

```bash
# Build the fixed version
go build -o swagger-mcp-fixed

# Install system-wide (optional)
sudo cp swagger-mcp-fixed /usr/local/bin/swagger-mcp-fixed
```

### Step 2: Update Claude Desktop Config

**Windows** (`%APPDATA%\Claude\claude_desktop_config.json`):
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

**WSL/Linux** (via WSL from Windows):
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

### Step 3: Restart Claude Desktop

After updating the config, restart Claude Desktop to apply changes.

## 🧪 Testing the Fix

Use the included test script:
```bash
./test-fix.sh
```

This demonstrates:
- **Original**: Shows endpoint discovery output that breaks JSON parsing
- **Fixed**: Shows only JSON-RPC messages that Claude Desktop expects

## 📊 Before vs After

### Before (Broken):
```
Starting server with specUrl: http://...
Endpoint: GET /api/sentences
Method: GET
Summary: Get sentences list
{"jsonrpc":"2.0","id":1,"result":...}
```
❌ Claude Desktop tries to parse "Starting server..." as JSON → Parse Error

### After (Fixed):
```
{"jsonrpc":"2.0","id":1,"result":...}
```
✅ Claude Desktop receives only valid JSON-RPC → Works perfectly

## 🎯 Benefits

1. **Eliminates JSON parse errors** in Claude Desktop
2. **Maintains backward compatibility** (default behavior unchanged)
3. **Enables seamless MCP integration** for real-time API testing
4. **No wrapper scripts needed** - clean native solution
5. **Works across all platforms** (Windows, Linux, macOS)

## 🔄 Next Steps

1. **Install fixed version** using commands above
2. **Update Claude Desktop config** with `--quiet` flag
3. **Test integration** - should see swagger tools without errors
4. **Submit upstream PR** to help the community

## 💡 For Upstream Contribution

This fix can be contributed back to the original repository to help all MCP users experiencing the same issue. The `--quiet` flag is non-breaking and maintains full backward compatibility.