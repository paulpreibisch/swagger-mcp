# Swagger-MCP Fixes Applied

## Overview
This document details the exact fixes applied to swagger-mcp to resolve Claude Desktop integration issues and POST request handling problems.

## Problem 1: Claude Desktop JSON Parse Errors

### Issue
Claude Desktop was showing these errors:
```
Unexpected token 'S', 'Starting s'... is not valid JSON
Unexpected token 'E', "Endpoint: "... is not valid JSON
Unexpected token 'M', "Method: GET" is not valid JSON
```

### Root Cause
swagger-mcp was outputting endpoint discovery information before entering JSON-RPC mode, breaking Claude Desktop's JSON parser.

### Fix Applied
**File**: `main.go`
- Added `--quiet` flag to suppress non-JSON output
- Added conditional debug output based on quiet flag

**Changes**:
```go
// Added flag
quiet := flag.Bool("quiet", false, "Suppress endpoint discovery output for MCP integration")

// Added to config struct
Quiet: *quiet,

// Added conditional output
if !*quiet {
    fmt.Printf("Starting server with specUrl: %s...", ...)
}
```

**File**: `app/models/models.go`
- Added `Quiet bool` field to Config struct

**File**: `app/swagger/extracter.go`
- Modified `ExtractSwagger()` to accept quiet parameter
- Added early return when quiet mode is enabled

**Usage**:
```bash
# Normal mode (shows endpoint discovery)
swagger-mcp --specUrl=http://api.test/swagger.json

# Quiet mode (JSON-RPC only, for Claude Desktop)
swagger-mcp --specUrl=http://api.test/swagger.json --quiet
```

## Problem 2: POST Request Body Parameter Handling

### Issue
POST requests were failing with errors like:
```
{"error":"Name is required"}
```
Even when parameters were provided correctly.

### Root Cause
swagger-mcp only supported Swagger 2.0 body parameters but SoraOrc uses OpenAPI 3.0 `requestBody` specifications. The tool was generating individual property parameters instead of handling complete JSON request bodies.

### Fix Applied

**File**: `app/models/models.go`
- Added OpenAPI 3.0 requestBody support structures:

```go
type Endpoint struct {
    // ... existing fields
    RequestBody *RequestBody `json:"requestBody,omitempty"`
}

type RequestBody struct {
    Required bool                      `json:"required,omitempty"`
    Content  map[string]RequestContent `json:"content,omitempty"`
}

type RequestContent struct {
    Schema *SchemaRef `json:"schema,omitempty"`
}
```

**File**: `app/mcp-server/server.go`
- Added OpenAPI 3.0 requestBody detection and handling:

```go
// Handle OpenAPI 3.0 requestBody
if details.RequestBody != nil && details.RequestBody.Content != nil {
    hasRequestBody = true
    // Look for application/json content
    if jsonContent, exists := details.RequestBody.Content["application/json"]; exists && jsonContent.Schema != nil {
        // For OpenAPI 3.0, always use a single body parameter for JSON content
        toolOption = append(toolOption, mcp.WithString(
            "body",
            mcp.Description("JSON request body containing the complete object structure"),
            mcp.Required(),
        ))
        reqBody["body"] = "object"
    }
}
```

- Updated `CreateMCPToolHandler` to accept `hasRequestBody` parameter
- Enhanced body processing logic to handle both individual properties and complete JSON objects:

```go
// Handle OpenAPI 3.0 style single body parameter vs Swagger 2.0 individual properties
if hasRequestBody && len(reqBody) == 1 {
    // Check if we have a single "body" parameter (OpenAPI 3.0 style)
    if bodyType, exists := reqBody["body"]; exists && bodyType == "object" {
        if bodyParam, ok := request.Params.Arguments["body"].(string); ok {
            // Validate JSON and use directly
            var testObj interface{}
            if err := json.Unmarshal([]byte(bodyParam), &testObj); err != nil {
                return mcp.NewToolResultError(fmt.Sprintf("[Error] invalid JSON in body parameter: %v", err)), nil
            }
            reqBodyDataBytes = []byte(bodyParam)
        } else {
            return mcp.NewToolResultError("[Error] missing body parameter"), nil
        }
    }
}
```

## Problem 3: Go Module Path Conflicts

### Issue
Windows installation was failing with:
```
go: github.com/paulpreibisch/swagger-mcp@fix-mcp-json-output: version constraints conflict:
module declares its path as: github.com/danishjsheikh/swagger-mcp
but was required as: github.com/paulpreibisch/swagger-mcp
```

### Fix Applied
**File**: `go.mod`
- Updated module declaration:
```go
// Changed from:
module github.com/danishjsheikh/swagger-mcp

// To:
module github.com/paulpreibisch/swagger-mcp
```

**Files**: All Go source files
- Updated import paths from `github.com/danishjsheikh/swagger-mcp` to `github.com/paulpreibisch/swagger-mcp`

## Testing Results

### Before Fixes
1. **Claude Desktop**: JSON parse errors, no MCP tools available
2. **POST Requests**: 
   ```json
   Input: {"name": "Test Workspace", "description": "..."}
   Output: {"error": "Name is required"}
   ```

### After Fixes
1. **Claude Desktop**: Clean JSON-RPC communication, MCP tools working
2. **POST Requests**:
   ```json
   Input: {"body": "{\"name\":\"Test Workspace\",\"description\":\"...\"}"}
   Output: {"id": 4, "name": "Test Workspace", "created_at": "..."}
   ```

## Installation Instructions

### WSL/Linux
```bash
cd /path/to/swagger-mcp
git checkout fix-mcp-json-output
go install .
```

### Windows
```bash
go clean -modcache
go install github.com/paulpreibisch/swagger-mcp@v1.0.0-fix
```

## Configuration Updates

### Claude Desktop Config
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

### .mcp.json for Claude Code
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

## Verification Commands

### Test Tool Generation
```bash
echo '{"jsonrpc":"2.0","id":1,"method":"tools/list","params":{}}' | swagger-mcp --specUrl=http://morpheus.test:5222/swagger.json --baseUrl=http://morpheus.test:5211 --quiet | jq '.result.tools[] | select(.name == "post_/api/workspaces")'
```

### Test Workspace Creation
```bash
echo '{"jsonrpc":"2.0","id":1,"method":"tools/call","params":{"name":"post_/api/workspaces","arguments":{"body":"{\"name\":\"Test Workspace\",\"description\":\"Test description\"}"}}}' | swagger-mcp --specUrl=http://morpheus.test:5222/swagger.json --baseUrl=http://morpheus.test:5211 --quiet
```

## File Changes Summary

1. **main.go**: Added `--quiet` flag and conditional output
2. **app/models/models.go**: Added OpenAPI 3.0 RequestBody structures and Quiet config field
3. **app/swagger/extracter.go**: Added quiet parameter to ExtractSwagger function
4. **app/mcp-server/server.go**: Added OpenAPI 3.0 requestBody detection and enhanced body processing
5. **go.mod**: Updated module path to match fork

## Still Experiencing Issues?

If you're still getting "string should match error", please provide:
1. The exact error message
2. The MCP configuration you're using  
3. The command or prompt that's failing

The most common remaining issue is configuration - make sure you're using the `--quiet` flag and the updated version with `go install github.com/paulpreibisch/swagger-mcp@v1.0.0-fix`.