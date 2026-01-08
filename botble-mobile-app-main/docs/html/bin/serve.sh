#!/bin/bash

# Simple script to serve the documentation locally
# Usage: ./serve.sh [port]

PORT=${1:-8080}

echo "🚀 Starting documentation server on port $PORT..."
echo "📖 Open http://localhost:$PORT in your browser"
echo "⏹️  Press Ctrl+C to stop the server"
echo ""

# Check if Python 3 is available
if command -v python3 &> /dev/null; then
    python3 -m http.server $PORT
elif command -v python &> /dev/null; then
    python -m http.server $PORT
else
    echo "❌ Error: Python is not installed or not in PATH"
    echo "Please install Python 3 to serve the documentation"
    exit 1
fi
