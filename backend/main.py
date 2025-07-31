from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from contextlib import asynccontextmanager
import logging
from database import create_tables
from routes import router

# Configure logging
logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s - %(name)s - %(levelname)s - %(message)s'
)
logger = logging.getLogger(__name__)

@asynccontextmanager
async def lifespan(app: FastAPI):
    # Startup
    logger.info("Starting eMTC API server...")
    create_tables()
    logger.info("Database tables created successfully")
    yield
    # Shutdown
    logger.info("Shutting down eMTC API server...")

# Create FastAPI app
app = FastAPI(
    title="eMTC - Electronic Market for Textiles and Clothing (TC, GoI)",
    description="API for eMTC mobile app data collection. eMTC is a digital platform for textile consumption data collection across India, developed under the aegis of the Textiles Committee, Government of India.",
    version="1.0.0",
    docs_url="/docs",
    redoc_url="/redoc",
    lifespan=lifespan
)

# Configure CORS
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],  # In production, specify actual origins
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# Include routes
app.include_router(router, prefix="/api/v1", tags=["eMTC"])

@app.get("/")
async def root():
    """Root endpoint with API information"""
    return {
        "message": "eMTC API - Electronic Market for Textiles and Clothing (TC, GoI)",
        "version": "1.0.0",
        "docs": "/docs",
        "health": "/api/v1/ping"
    }

@app.get("/health")
async def health():
    """Health check endpoint"""
    return {
        "status": "healthy",
        "service": "eMTC API - Electronic Market for Textiles and Clothing (TC, GoI)",
        "version": "1.0.0"
    }

if __name__ == "__main__":
    import uvicorn
    import os
    
    # Get port from environment (for Render deployment)
    port = int(os.getenv("PORT", "8000"))
    
    uvicorn.run(
        "main:app",
        host="0.0.0.0",
        port=port,
        reload=False,  # Disable reload in production
        log_level="info"
    ) 