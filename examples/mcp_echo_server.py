#!/usr/bin/env python3
"""
Simple MCP Echo Server for testing Ruby MCP client.

This server provides basic echo tools for testing the MCP functionality
when other servers (like filesystem) are not available.

To use this server:
1. Install the Python MCP SDK: pip install mcp
2. Run this script via the Ruby MCP client

This is a minimal implementation for testing purposes only.
"""

import json
import sys
import asyncio
from typing import Any, Dict, List

try:
    from mcp.server import Server
    from mcp.server.stdio import stdio_server
    from mcp import types
except ImportError:
    print(json.dumps({
        "jsonrpc": "2.0",
        "error": {
            "code": -1,
            "message": "MCP Python SDK not installed. Please run: pip install mcp"
        }
    }))
    sys.exit(1)

# Create server instance
server = Server("echo-server")

@server.list_tools()
async def list_tools() -> List[types.Tool]:
    """List available tools."""
    return [
        types.Tool(
            name="echo",
            description="Echo back the provided message",
            inputSchema={
                "type": "object",
                "properties": {
                    "message": {
                        "type": "string",
                        "description": "Message to echo back"
                    }
                },
                "required": ["message"]
            }
        ),
        types.Tool(
            name="uppercase",
            description="Convert text to uppercase",
            inputSchema={
                "type": "object", 
                "properties": {
                    "text": {
                        "type": "string",
                        "description": "Text to convert to uppercase"
                    }
                },
                "required": ["text"]
            }
        ),
        types.Tool(
            name="count_words",
            description="Count words in the provided text",
            inputSchema={
                "type": "object",
                "properties": {
                    "text": {
                        "type": "string",
                        "description": "Text to count words in"
                    }
                },
                "required": ["text"]
            }
        )
    ]

@server.call_tool()
async def call_tool(name: str, arguments: Dict[str, Any]) -> List[types.TextContent]:
    """Handle tool calls."""
    if name == "echo":
        message = arguments.get("message", "")
        return [types.TextContent(
            type="text",
            text=f"Echo: {message}"
        )]
    
    elif name == "uppercase":
        text = arguments.get("text", "")
        return [types.TextContent(
            type="text",
            text=text.upper()
        )]
    
    elif name == "count_words":
        text = arguments.get("text", "")
        word_count = len(text.split())
        return [types.TextContent(
            type="text",
            text=f"Word count: {word_count}"
        )]
    
    else:
        raise ValueError(f"Unknown tool: {name}")

@server.list_prompts()
async def list_prompts() -> List[types.Prompt]:
    """List available prompts."""
    return [
        types.Prompt(
            name="greeting",
            description="A simple greeting prompt",
            arguments=[
                types.PromptArgument(
                    name="name",
                    description="Name to greet",
                    required=True
                )
            ]
        )
    ]

@server.get_prompt()
async def get_prompt(name: str, arguments: Dict[str, Any]) -> types.GetPromptResult:
    """Handle prompt requests."""
    if name == "greeting":
        name_arg = arguments.get("name", "World")
        return types.GetPromptResult(
            description="A greeting prompt",
            messages=[
                types.PromptMessage(
                    role="user", 
                    content=types.TextContent(
                        type="text",
                        text=f"Hello, {name_arg}! How are you today?"
                    )
                )
            ]
        )
    else:
        raise ValueError(f"Unknown prompt: {name}")

async def main():
    """Run the server."""
    try:
        async with stdio_server() as (read_stream, write_stream):
            await server.run(
                read_stream,
                write_stream,
                server.create_initialization_options()
            )
    except Exception as e:
        print(json.dumps({
            "jsonrpc": "2.0",
            "error": {
                "code": -2,
                "message": f"Server error: {str(e)}"
            }
        }), file=sys.stderr)
        sys.exit(1)

if __name__ == "__main__":
    asyncio.run(main()) 