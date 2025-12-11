# MCP Server Development

This lode documents building MCP (Model Context Protocol) servers for Claude Code integration, specifically discoveries made while building the Fizzy MCP.

## Single-File C# MCP Server

### File Structure

```csharp
#:package Microsoft.Extensions.Hosting@9.0.8
#:package ModelContextProtocol@0.5.0-preview.1
#:package RestSharp@112.1.0
#:property PublishAot=false
using Microsoft.Extensions.DependencyInjection;
using Microsoft.Extensions.Hosting;
using Microsoft.Extensions.Logging;
using ModelContextProtocol.Server;
using RestSharp;
using System.ComponentModel;

// ... server setup and tools
```

The `#:package` and `#:property` directives are for .NET 9's single-file C# program feature.

---

## Critical: stdout Must Be Clean

**The MCP protocol uses stdin/stdout for JSON-RPC communication. Any non-JSON output to stdout breaks the connection.**

### Problem

`dotnet run` outputs build information to stdout before the application starts:

```
C:\Program Files\dotnet\...
```

This causes Claude Desktop to fail with:
```
Unexpected token 'C', "C:\Program"... is not valid JSON
```

### Solution 1: Wrapper Script (Recommended)

Create a `.cmd` wrapper that runs the script from its directory:

```batch
@echo off
dotnet run "%~dp0fizzy-mcp.cs"
```

The `%~dp0` resolves to the script's directory, ensuring proper path resolution.

### Solution 2: Clear All Logging

Remove all console logging providers to prevent accidental stdout writes:

```csharp
var builder = Host.CreateApplicationBuilder(args);
builder.Logging.ClearProviders();  // Critical!
```

---

## Logging to stderr

All MCP logging must go to stderr, not stdout:

```csharp
static void Log(string message) => Console.Error.WriteLine($"[mcp-name] {DateTime.Now:HH:mm:ss} {message}");
```

### Error Handling with Logging

```csharp
try
{
    Log("MCP Starting...");

    var builder = Host.CreateApplicationBuilder(args);
    builder.Logging.ClearProviders();

    builder.Services
        .AddMcpServer()
        .WithStdioServerTransport()
        .WithToolsFromAssembly();

    await builder.Build().RunAsync();
}
catch (Exception ex)
{
    Log($"Fatal error: {ex}");
    throw;
}
```

stderr output appears in Claude Desktop's MCP logs panel.

---

## Claude Desktop Configuration

### Config Location

Windows: `%APPDATA%\Claude\claude_desktop_config.json`

### MCP Server Entry

```json
{
  "mcpServers": {
    "fizzy": {
      "command": "C:\\Users\\username\\path\\run-fizzy-mcp.cmd",
      "env": {
        "FIZZY_BASE_URL": "http://localhost:9461",
        "FIZZY_ACCESS_TOKEN": "your-token-here"
      }
    }
  }
}
```

### Key Points

- Use the wrapper script as `command`, not `dotnet` directly
- Environment variables are passed to the process
- Backslashes in paths must be escaped (`\\`)

---

## Tool Definition Pattern

### Basic Tool

```csharp
[McpServerToolType]
public static class MyTools
{
    [McpServerTool, Description("Description shown to Claude")]
    public static async Task<string> ToolName(
        [Description("Parameter description")] string param1,
        [Description("Optional param")] string? param2 = null)
    {
        // Implementation
        return "result string";
    }
}
```

### Return Strings for Simplicity

Returning strings (JSON) is the simplest approach - Claude can parse the JSON directly:

```csharp
public static async Task<string> GetData()
{
    var response = await client.ExecuteAsync(request);
    return response.Content ?? $"Status: {response.StatusCode}";
}
```

---

## REST API Client Pattern

### Centralized Client

```csharp
public static class ApiClient
{
    private static readonly string BaseUrl = Environment.GetEnvironmentVariable("API_BASE_URL") ?? "https://default.url";
    private static readonly string Token = Environment.GetEnvironmentVariable("API_TOKEN") ?? "";

    private static void Log(string message) => Console.Error.WriteLine($"[mcp] {DateTime.Now:HH:mm:ss} {message}");

    public static RestClient Create()
    {
        var client = new RestClient(new RestClientOptions(BaseUrl));
        client.AddDefaultHeader("Authorization", $"Bearer {Token}");
        client.AddDefaultHeader("Accept", "application/json");
        client.AddDefaultHeader("Content-Type", "application/json");
        return client;
    }

    public static async Task<string> ExecuteAsync(RestRequest request)
    {
        Log($"Request: {request.Method} {BaseUrl}{request.Resource}");
        using var client = Create();
        var response = await client.ExecuteAsync(request);
        Log($"Response: {response.StatusCode}");
        return response.Content ?? $"Status: {response.StatusCode}";
    }
}
```

### URL Modifications

Some APIs require specific URL formats. Modify in `ExecuteAsync`:

```csharp
// Example: Add .json suffix for Rails APIs
if (!request.Resource.EndsWith(".json"))
    request.Resource += ".json";
```

---

## Debugging MCP Servers

### View Logs in Claude Desktop

MCP stderr output appears in Claude Desktop logs:
1. Open Claude Desktop
2. View MCP server status/logs
3. Look for `[mcp-name]` prefixed messages

### Test Manually

Run the server directly to see if it starts:

```bash
dotnet run path/to/mcp.cs
```

If it outputs `[mcp-name] HH:mm:ss MCP Starting...` and waits, the server is working.

### Test API Separately

Use curl to verify API connectivity before troubleshooting MCP:

```bash
curl -H "Authorization: Bearer TOKEN" -H "Accept: application/json" http://localhost:9461/endpoint.json
```

---

## Common Issues

### "Unexpected token" JSON Error

**Cause**: Non-JSON output to stdout (usually from dotnet build)
**Fix**: Use wrapper script + clear logging providers

### 302 Redirect Instead of JSON

**Cause**: API requires specific URL format
**Fix**: Modify URL in ExecuteAsync (e.g., add `.json` suffix)

### 406 Not Acceptable

**Cause**: Content-Type or Accept header mismatch
**Fix**: Ensure headers are set correctly:
```csharp
client.AddDefaultHeader("Accept", "application/json");
client.AddDefaultHeader("Content-Type", "application/json");
```

### MCP Not Appearing in Claude

**Cause**: Config syntax error or wrong path
**Fix**:
- Validate JSON syntax
- Use double backslashes in Windows paths
- Ensure wrapper script exists and is executable

### Environment Variables Not Working

**Cause**: Variables not reaching the process
**Fix**: Define in MCP config `env` block, not system environment

---

## File Locations

| File | Purpose |
|------|---------|
| `fizzy-mcp.cs` | Main MCP server code |
| `run-fizzy-mcp.cmd` | Wrapper script for clean stdout |
| `claude_desktop_config.json` | Claude Desktop MCP configuration |
