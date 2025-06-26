#!/bin/bash
# test-fix.sh - Demonstrate the MCP JSON output fix

echo "🧪 Testing swagger-mcp MCP integration fix..."
echo

echo "📄 Original swagger-mcp output (causes JSON parse errors):"
echo "$ swagger-mcp --specUrl=... | head -3"
timeout 2s swagger-mcp --specUrl=http://morpheus.test:5222/swagger.json --baseUrl=http://morpheus.test:5211 2>/dev/null | head -3 || echo "(timeout expected)"
echo

echo "✅ Fixed swagger-mcp output (JSON-RPC only):"
echo "$ swagger-mcp-fixed --specUrl=... --quiet | head -3" 
timeout 2s ./swagger-mcp-fixed --specUrl=http://morpheus.test:5222/swagger.json --baseUrl=http://morpheus.test:5211 --quiet 2>/dev/null | head -3 || echo "(timeout expected)"
echo

echo "💡 The --quiet flag suppresses endpoint discovery output,"
echo "   ensuring Claude Desktop only receives valid JSON-RPC messages."