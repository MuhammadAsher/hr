#!/usr/bin/env python3
"""
Simple HTTP server for API documentation
Run this script to view the full Swagger UI documentation
"""

import http.server
import socketserver
import webbrowser
import os
import sys
from pathlib import Path

# Configuration
PORT = 8000
DIRECTORY = Path(__file__).parent

class CustomHTTPRequestHandler(http.server.SimpleHTTPRequestHandler):
    """Custom handler to serve files from the api directory"""
    
    def __init__(self, *args, **kwargs):
        super().__init__(*args, directory=str(DIRECTORY), **kwargs)
    
    def end_headers(self):
        # Add CORS headers
        self.send_header('Access-Control-Allow-Origin', '*')
        self.send_header('Access-Control-Allow-Methods', 'GET, POST, OPTIONS')
        self.send_header('Access-Control-Allow-Headers', 'Content-Type')
        super().end_headers()
    
    def log_message(self, format, *args):
        # Custom log format
        print(f"[{self.log_date_time_string()}] {format % args}")

def main():
    """Start the HTTP server"""
    
    print("=" * 60)
    print("🚀 HR Management SaaS Platform - API Documentation Server")
    print("=" * 60)
    print()
    
    # Change to the api directory
    os.chdir(DIRECTORY)
    
    # Create server
    with socketserver.TCPServer(("", PORT), CustomHTTPRequestHandler) as httpd:
        url = f"http://localhost:{PORT}"
        
        print(f"✅ Server started successfully!")
        print()
        print(f"📖 Documentation URL: {url}")
        print(f"📋 OpenAPI Spec:      {url}/openapi.yaml")
        print(f"📮 Postman Collection: {url}/postman_collection.json")
        print()
        print("=" * 60)
        print()
        print("🌐 Opening browser...")
        print()
        
        # Open browser
        try:
            webbrowser.open(url)
            print("✅ Browser opened!")
        except Exception as e:
            print(f"⚠️  Could not open browser automatically: {e}")
            print(f"   Please open {url} manually")
        
        print()
        print("=" * 60)
        print("Press Ctrl+C to stop the server")
        print("=" * 60)
        print()
        
        try:
            httpd.serve_forever()
        except KeyboardInterrupt:
            print()
            print()
            print("=" * 60)
            print("🛑 Server stopped")
            print("=" * 60)
            sys.exit(0)

if __name__ == "__main__":
    main()

