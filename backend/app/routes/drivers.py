"""
Fleet Management System - Drivers API Routes
"""

from fastapi import APIRouter, HTTPException, Depends, Request
from typing import List, Optional
import logging

from app.models.schemas import (
    DriverCreate, DriverUpdate, Driver,
    DriverResponse, DriverListResponse, BaseResponse
)
from app.database.hive_manager import HiveManager

router = APIRouter()
logger = logging.getLogger(__name__)

def get_hive_manager(request: Request) -> HiveManager:
    return request.app.state.hive_manager

@router.get("/", response_model=DriverListResponse)
async def get_drivers(
    skip: int = 0,
    limit: int = 100,
    status: Optional[str] = None,
    hive: HiveManager = Depends(get_hive_manager)
):
    """Get all drivers with optional filtering"""
    try:
        drivers = await hive.find_all("drivers")
        
        if status:
            drivers = [d for d in drivers if d.get("status") == status]
        
        total = len(drivers)
        drivers = drivers[skip:skip + limit]
        
        return DriverListResponse(
            success=True,
            message=f"Retrieved {len(drivers)} drivers",
            data=drivers
        )
        
    except Exception as e:
        logger.error(f"Error fetching drivers: {str(e)}")
        raise HTTPException(status_code=500, detail=str(e))

@router.get("/{driver_id}", response_model=DriverResponse)
async def get_driver(
    driver_id: str,
    hive: HiveManager = Depends(get_hive_manager)
):
    """Get a specific driver by ID"""
    try:
        driver = await hive.find_by_id("drivers", driver_id)
        
        if not driver:
            raise HTTPException(status_code=404, detail="Driver not found")
        
        return DriverResponse(
            success=True,
            message="Driver retrieved successfully",
            data=driver
        )
        
    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"Error fetching driver {driver_id}: {str(e)}")
        raise HTTPException(status_code=500, detail=str(e))

@router.post("/", response_model=DriverResponse)
async def create_driver(
    driver: DriverCreate,
    hive: HiveManager = Depends(get_hive_manager)
):
    """Create a new driver"""
    try:
        # Check if license number already exists
        existing_drivers = await hive.find_where("drivers", license_number=driver.license_number)
        if existing_drivers:
            raise HTTPException(status_code=400, detail="Driver with this license number already exists")
        
        driver_data = driver.dict()
        driver_id = await hive.insert("drivers", driver_data)
        
        created_driver = await hive.find_by_id("drivers", driver_id)
        
        return DriverResponse(
            success=True,
            message="Driver created successfully",
            data=created_driver
        )
        
    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"Error creating driver: {str(e)}")
        raise HTTPException(status_code=500, detail=str(e))

@router.put("/{driver_id}", response_model=DriverResponse)
async def update_driver(
    driver_id: str,
    driver_update: DriverUpdate,
    hive: HiveManager = Depends(get_hive_manager)
):
    """Update an existing driver"""
    try:
        existing_driver = await hive.find_by_id("drivers", driver_id)
        if not existing_driver:
            raise HTTPException(status_code=404, detail="Driver not found")
        
        # Check license number uniqueness
        if driver_update.license_number:
            existing_with_license = await hive.find_where("drivers", license_number=driver_update.license_number)
            if existing_with_license and existing_with_license[0]["id"] != driver_id:
                raise HTTPException(status_code=400, detail="Driver with this license number already exists")
        
        update_data = {k: v for k, v in driver_update.dict().items() if v is not None}
        success = await hive.update("drivers", driver_id, update_data)
        
        if not success:
            raise HTTPException(status_code=500, detail="Failed to update driver")
        
        updated_driver = await hive.find_by_id("drivers", driver_id)
        
        return DriverResponse(
            success=True,
            message="Driver updated successfully",
            data=updated_driver
        )
        
    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"Error updating driver {driver_id}: {str(e)}")
        raise HTTPException(status_code=500, detail=str(e))

@router.delete("/{driver_id}", response_model=BaseResponse)
async def delete_driver(
    driver_id: str,
    hive: HiveManager = Depends(get_hive_manager)
):
    """Delete a driver"""
    try:
        driver = await hive.find_by_id("drivers", driver_id)
        if not driver:
            raise HTTPException(status_code=404, detail="Driver not found")
        
        # Check if driver has associated trips
        trips = await hive.find_where("trips", driver_id=driver_id)
        fuel_entries = await hive.find_where("fuel_entries", driver_id=driver_id)
        
        if trips or fuel_entries:
            await hive.update("drivers", driver_id, {"status": "inactive"})
            return BaseResponse(
                success=True,
                message="Driver marked as inactive (has associated records)"
            )
        else:
            success = await hive.delete("drivers", driver_id)
            if not success:
                raise HTTPException(status_code=500, detail="Failed to delete driver")
            
            return BaseResponse(
                success=True,
                message="Driver deleted successfully"
            )
        
    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"Error deleting driver {driver_id}: {str(e)}")
        raise HTTPException(status_code=500, detail=str(e))