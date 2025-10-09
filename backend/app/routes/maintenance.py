"""
Fleet Management System - Maintenance API Routes
"""

from fastapi import APIRouter, HTTPException, Depends, Request
from typing import List, Optional
import logging

from app.models.schemas import (
    MaintenanceCreate, MaintenanceUpdate, Maintenance,
    MaintenanceResponse, MaintenanceListResponse, BaseResponse
)
from app.database.hive_manager import HiveManager

router = APIRouter()
logger = logging.getLogger(__name__)

def get_hive_manager(request: Request) -> HiveManager:
    return request.app.state.hive_manager

@router.get("/", response_model=MaintenanceListResponse)
async def get_maintenance_records(
    skip: int = 0,
    limit: int = 100,
    vehicle_id: Optional[str] = None,
    maintenance_type: Optional[str] = None,
    hive: HiveManager = Depends(get_hive_manager)
):
    """Get all maintenance records with optional filtering"""
    try:
        maintenance_records = await hive.find_all("maintenance")
        
        # Apply filters
        if vehicle_id:
            maintenance_records = [m for m in maintenance_records if m.get("vehicle_id") == vehicle_id]
        if maintenance_type:
            maintenance_records = [m for m in maintenance_records if m.get("type") == maintenance_type]
        
        # Sort by date (most recent first)
        maintenance_records.sort(key=lambda x: x.get("date", ""), reverse=True)
        
        total = len(maintenance_records)
        maintenance_records = maintenance_records[skip:skip + limit]
        
        return MaintenanceListResponse(
            success=True,
            message=f"Retrieved {len(maintenance_records)} maintenance records",
            data=maintenance_records
        )
        
    except Exception as e:
        logger.error(f"Error fetching maintenance records: {str(e)}")
        raise HTTPException(status_code=500, detail=str(e))

@router.post("/", response_model=MaintenanceResponse)
async def create_maintenance_record(
    maintenance: MaintenanceCreate,
    hive: HiveManager = Depends(get_hive_manager)
):
    """Create a new maintenance record"""
    try:
        # Validate vehicle exists
        vehicle = await hive.find_by_id("vehicles", maintenance.vehicle_id)
        if not vehicle:
            raise HTTPException(status_code=404, detail="Vehicle not found")
        
        maintenance_data = maintenance.dict()
        maintenance_id = await hive.insert("maintenance", maintenance_data)
        
        created_maintenance = await hive.find_by_id("maintenance", maintenance_id)
        
        return MaintenanceResponse(
            success=True,
            message="Maintenance record created successfully",
            data=created_maintenance
        )
        
    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"Error creating maintenance record: {str(e)}")
        raise HTTPException(status_code=500, detail=str(e))

@router.delete("/{maintenance_id}", response_model=BaseResponse)
async def delete_maintenance_record(
    maintenance_id: str,
    hive: HiveManager = Depends(get_hive_manager)
):
    """Delete a maintenance record"""
    try:
        maintenance = await hive.find_by_id("maintenance", maintenance_id)
        if not maintenance:
            raise HTTPException(status_code=404, detail="Maintenance record not found")
        
        success = await hive.delete("maintenance", maintenance_id)
        if not success:
            raise HTTPException(status_code=500, detail="Failed to delete maintenance record")
        
        return BaseResponse(
            success=True,
            message="Maintenance record deleted successfully"
        )
        
    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"Error deleting maintenance record {maintenance_id}: {str(e)}")
        raise HTTPException(status_code=500, detail=str(e))