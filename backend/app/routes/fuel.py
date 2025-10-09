"""
Fleet Management System - Fuel Entries API Routes
"""

from fastapi import APIRouter, HTTPException, Depends, Request
from typing import List, Optional
import logging

from app.models.schemas import (
    FuelEntryCreate, FuelEntryUpdate, FuelEntry,
    FuelEntryResponse, FuelEntryListResponse, BaseResponse
)
from app.database.hive_manager import HiveManager

router = APIRouter()
logger = logging.getLogger(__name__)

def get_hive_manager(request: Request) -> HiveManager:
    return request.app.state.hive_manager

@router.get("/", response_model=FuelEntryListResponse)
async def get_fuel_entries(
    skip: int = 0,
    limit: int = 100,
    vehicle_id: Optional[str] = None,
    driver_id: Optional[str] = None,
    hive: HiveManager = Depends(get_hive_manager)
):
    """Get all fuel entries with optional filtering"""
    try:
        fuel_entries = await hive.find_all("fuel_entries")
        
        # Apply filters
        if vehicle_id:
            fuel_entries = [f for f in fuel_entries if f.get("vehicle_id") == vehicle_id]
        if driver_id:
            fuel_entries = [f for f in fuel_entries if f.get("driver_id") == driver_id]
        
        # Sort by date (most recent first)
        fuel_entries.sort(key=lambda x: x.get("date", ""), reverse=True)
        
        total = len(fuel_entries)
        fuel_entries = fuel_entries[skip:skip + limit]
        
        return FuelEntryListResponse(
            success=True,
            message=f"Retrieved {len(fuel_entries)} fuel entries",
            data=fuel_entries
        )
        
    except Exception as e:
        logger.error(f"Error fetching fuel entries: {str(e)}")
        raise HTTPException(status_code=500, detail=str(e))

@router.post("/", response_model=FuelEntryResponse)
async def create_fuel_entry(
    fuel_entry: FuelEntryCreate,
    hive: HiveManager = Depends(get_hive_manager)
):
    """Create a new fuel entry"""
    try:
        # Validate vehicle exists
        vehicle = await hive.find_by_id("vehicles", fuel_entry.vehicle_id)
        if not vehicle:
            raise HTTPException(status_code=404, detail="Vehicle not found")
        
        # Validate driver exists if provided
        if fuel_entry.driver_id:
            driver = await hive.find_by_id("drivers", fuel_entry.driver_id)
            if not driver:
                raise HTTPException(status_code=404, detail="Driver not found")
        
        fuel_data = fuel_entry.dict()
        fuel_id = await hive.insert("fuel_entries", fuel_data)
        
        created_fuel_entry = await hive.find_by_id("fuel_entries", fuel_id)
        
        return FuelEntryResponse(
            success=True,
            message="Fuel entry created successfully",
            data=created_fuel_entry
        )
        
    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"Error creating fuel entry: {str(e)}")
        raise HTTPException(status_code=500, detail=str(e))

@router.delete("/{fuel_entry_id}", response_model=BaseResponse)
async def delete_fuel_entry(
    fuel_entry_id: str,
    hive: HiveManager = Depends(get_hive_manager)
):
    """Delete a fuel entry"""
    try:
        fuel_entry = await hive.find_by_id("fuel_entries", fuel_entry_id)
        if not fuel_entry:
            raise HTTPException(status_code=404, detail="Fuel entry not found")
        
        success = await hive.delete("fuel_entries", fuel_entry_id)
        if not success:
            raise HTTPException(status_code=500, detail="Failed to delete fuel entry")
        
        return BaseResponse(
            success=True,
            message="Fuel entry deleted successfully"
        )
        
    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"Error deleting fuel entry {fuel_entry_id}: {str(e)}")
        raise HTTPException(status_code=500, detail=str(e))