#!/usr/bin/env python3
"""
Startup script for eMTC FastAPI backend
"""

import uvicorn
import os
from dotenv import load_dotenv

def main():
    """Start the FastAPI server"""
    # Load environment variables
    load_dotenv('config.env')
    
    # Get configuration from environment
    host = os.getenv("API_HOST", "0.0.0.0")
    port = int(os.getenv("API_PORT", "8000"))
    debug = os.getenv("DEBUG", "True").lower() == "true"
    
    print("🚀 Starting eMTC API Server")
    print(f"📍 Host: {host}")
    print(f"🔌 Port: {port}")
    print(f"🐛 Debug: {debug}")
    print("=" * 50)
    
    # Start the server
    uvicorn.run(
        "main:app",
        host=host,
        port=port,
        reload=debug,
        log_level="info"
    )

if __name__ == "__main__":
    main() 