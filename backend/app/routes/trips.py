"""
Fleet Management System - Trips API Routes
"""

from fastapi import APIRouter, HTTPException, Depends, Request
from typing import List, Optional
import logging

from app.models.schemas import (
    TripCreate, TripUpdate, Trip,
    TripResponse, TripListResponse, BaseResponse
)
from app.database.hive_manager import HiveManager

router = APIRouter()
logger = logging.getLogger(__name__)

def get_hive_manager(request: Request) -> HiveManager:
    return request.app.state.hive_manager

@router.get("/", response_model=TripListResponse)
async def get_trips(
    skip: int = 0,
    limit: int = 100,
    vehicle_id: Optional[str] = None,
    driver_id: Optional[str] = None,
    status: Optional[str] = None,
    hive: HiveManager = Depends(get_hive_manager)
):
    """Get all trips with optional filtering"""
    try:
        trips = await hive.find_all("trips")
        
        # Apply filters
        if vehicle_id:
            trips = [t for t in trips if t.get("vehicle_id") == vehicle_id]
        if driver_id:
            trips = [t for t in trips if t.get("driver_id") == driver_id]
        if status:
            trips = [t for t in trips if t.get("status") == status]
        
        # Sort by start_time (most recent first)
        trips.sort(key=lambda x: x.get("start_time", ""), reverse=True)
        
        total = len(trips)
        trips = trips[skip:skip + limit]
        
        return TripListResponse(
            success=True,
            message=f"Retrieved {len(trips)} trips",
            data=trips
        )
        
    except Exception as e:
        logger.error(f"Error fetching trips: {str(e)}")
        raise HTTPException(status_code=500, detail=str(e))

@router.get("/{trip_id}", response_model=TripResponse)
async def get_trip(
    trip_id: str,
    hive: HiveManager = Depends(get_hive_manager)
):
    """Get a specific trip by ID"""
    try:
        trip = await hive.find_by_id("trips", trip_id)
        
        if not trip:
            raise HTTPException(status_code=404, detail="Trip not found")
        
        return TripResponse(
            success=True,
            message="Trip retrieved successfully",
            data=trip
        )
        
    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"Error fetching trip {trip_id}: {str(e)}")
        raise HTTPException(status_code=500, detail=str(e))

@router.post("/", response_model=TripResponse)
async def create_trip(
    trip: TripCreate,
    hive: HiveManager = Depends(get_hive_manager)
):
    """Create a new trip"""
    try:
        # Validate vehicle exists
        vehicle = await hive.find_by_id("vehicles", trip.vehicle_id)
        if not vehicle:
            raise HTTPException(status_code=404, detail="Vehicle not found")
        
        # Validate driver exists if provided
        if trip.driver_id:
            driver = await hive.find_by_id("drivers", trip.driver_id)
            if not driver:
                raise HTTPException(status_code=404, detail="Driver not found")
        
        trip_data = trip.dict()
        trip_id = await hive.insert("trips", trip_data)
        
        created_trip = await hive.find_by_id("trips", trip_id)
        
        return TripResponse(
            success=True,
            message="Trip created successfully",
            data=created_trip
        )
        
    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"Error creating trip: {str(e)}")
        raise HTTPException(status_code=500, detail=str(e))

@router.put("/{trip_id}", response_model=TripResponse)
async def update_trip(
    trip_id: str,
    trip_update: TripUpdate,
    hive: HiveManager = Depends(get_hive_manager)
):
    """Update an existing trip"""
    try:
        existing_trip = await hive.find_by_id("trips", trip_id)
        if not existing_trip:
            raise HTTPException(status_code=404, detail="Trip not found")
        
        # Validate vehicle exists if being updated
        if trip_update.vehicle_id:
            vehicle = await hive.find_by_id("vehicles", trip_update.vehicle_id)
            if not vehicle:
                raise HTTPException(status_code=404, detail="Vehicle not found")
        
        # Validate driver exists if being updated
        if trip_update.driver_id:
            driver = await hive.find_by_id("drivers", trip_update.driver_id)
            if not driver:
                raise HTTPException(status_code=404, detail="Driver not found")
        
        update_data = {k: v for k, v in trip_update.dict().items() if v is not None}
        
        # Calculate distance if both start_km and end_km are available
        if "end_km" in update_data or "start_km" in update_data:
            start_km = update_data.get("start_km", existing_trip.get("start_km", 0))
            end_km = update_data.get("end_km", existing_trip.get("end_km"))
            
            if end_km is not None and start_km is not None:
                update_data["distance"] = max(0, end_km - start_km)
        
        success = await hive.update("trips", trip_id, update_data)
        
        if not success:
            raise HTTPException(status_code=500, detail="Failed to update trip")
        
        updated_trip = await hive.find_by_id("trips", trip_id)
        
        return TripResponse(
            success=True,
            message="Trip updated successfully",
            data=updated_trip
        )
        
    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"Error updating trip {trip_id}: {str(e)}")
        raise HTTPException(status_code=500, detail=str(e))

@router.delete("/{trip_id}", response_model=BaseResponse)
async def delete_trip(
    trip_id: str,
    hive: HiveManager = Depends(get_hive_manager)
):
    """Delete a trip"""
    try:
        trip = await hive.find_by_id("trips", trip_id)
        if not trip:
            raise HTTPException(status_code=404, detail="Trip not found")
        
        success = await hive.delete("trips", trip_id)
        if not success:
            raise HTTPException(status_code=500, detail="Failed to delete trip")
        
        return BaseResponse(
            success=True,
            message="Trip deleted successfully"
        )
        
    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"Error deleting trip {trip_id}: {str(e)}")
        raise HTTPException(status_code=500, detail=str(e))