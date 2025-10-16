#!/usr/bin/env python3
"""
Fleet Management System - FastAPI Backend
Main application entry point
"""

from fastapi import FastAPI, HTTPException
from fastapi.middleware.cors import CORSMiddleware
from contextlib import asynccontextmanager
import uvicorn
import os
from pathlib import Path

# Import route modules
from app.routes import vehicles, drivers, trips, fuel, maintenance, excel_import
from app.routes import reporting
from app.database.hive_manager import HiveManager
from app.core.config import settings

@asynccontextmanager
async def lifespan(app: FastAPI):
    """Application startup and shutdown events"""
    # Startup
    print("🚀 Starting Fleet Management System Backend...")
    
    # Initialize Hive database
    hive_manager = HiveManager()
    await hive_manager.initialize()
    app.state.hive_manager = hive_manager
    
    print(f"✅ Database initialized at: {hive_manager.db_path}")
    print(f"🌐 API running on: http://localhost:{settings.PORT}")
    
    yield
    
    # Shutdown
    print("🛑 Shutting down Fleet Management System Backend...")
    if hasattr(app.state, 'hive_manager'):
        await app.state.hive_manager.close()

# Create FastAPI application
app = FastAPI(
    title="Fleet Management System API",
    description="Python FastAPI backend for fleet management with Excel processing capabilities",
    version="1.0.0",
    lifespan=lifespan
)

# Add CORS middleware for Flutter frontend
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],  # Configure this properly for production
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# Include route modules
app.include_router(vehicles.router, prefix="/api/v1/vehicles", tags=["vehicles"])
app.include_router(drivers.router, prefix="/api/v1/drivers", tags=["drivers"])
app.include_router(trips.router, prefix="/api/v1/trips", tags=["trips"])
app.include_router(fuel.router, prefix="/api/v1/fuel", tags=["fuel"])
app.include_router(maintenance.router, prefix="/api/v1/maintenance", tags=["maintenance"])
app.include_router(excel_import.router, prefix="/api/v1/excel", tags=["excel"])
app.include_router(reporting.router, prefix="/api/v1/reporting", tags=["reporting"])

@app.get("/")
async def root():
    """Root endpoint"""
    return {
        "message": "Fleet Management System API",
        "version": "1.0.0",
        "status": "running",
        "docs": "/docs"
    }

@app.get("/api/health")
async def health_check():
    """Health check endpoint"""
    return {
        "status": "healthy",
        "database": "connected" if hasattr(app.state, 'hive_manager') else "disconnected"
    }

if __name__ == "__main__":
    # Run the application
    uvicorn.run(
        "main:app",
        host="0.0.0.0",
        port=settings.PORT,
        reload=settings.DEBUG,
        log_level="info"
    )