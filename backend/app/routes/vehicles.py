"""
Fleet Management System - Vehicles API Routes
"""

from fastapi import APIRouter, HTTPException, Depends, Request
from typing import List, Optional
import logging

from app.models.schemas import (
    VehicleCreate, VehicleUpdate, Vehicle,
    VehicleResponse, VehicleListResponse, BaseResponse
)
from app.database.hive_manager import HiveManager

router = APIRouter()
logger = logging.getLogger(__name__)

def get_hive_manager(request: Request) -> HiveManager:
    """Dependency to get HiveManager instance"""
    return request.app.state.hive_manager

@router.get("/", response_model=VehicleListResponse)
async def get_vehicles(
    skip: int = 0,
    limit: int = 100,
    status: Optional[str] = None,
    hive: HiveManager = Depends(get_hive_manager)
):
    """Get all vehicles with optional filtering"""
    try:
        # Get all vehicles
        vehicles = await hive.find_all("vehicles")
        
        # Apply filters
        if status:
            vehicles = [v for v in vehicles if v.get("status") == status]
        
        # Apply pagination
        total = len(vehicles)
        vehicles = vehicles[skip:skip + limit]
        
        return VehicleListResponse(
            success=True,
            message=f"Retrieved {len(vehicles)} vehicles",
            data=vehicles
        )
        
    except Exception as e:
        logger.error(f"Error fetching vehicles: {str(e)}")
        raise HTTPException(status_code=500, detail=str(e))

@router.get("/{vehicle_id}", response_model=VehicleResponse)
async def get_vehicle(
    vehicle_id: str,
    hive: HiveManager = Depends(get_hive_manager)
):
    """Get a specific vehicle by ID"""
    try:
        vehicle = await hive.find_by_id("vehicles", vehicle_id)
        
        if not vehicle:
            raise HTTPException(status_code=404, detail="Vehicle not found")
        
        return VehicleResponse(
            success=True,
            message="Vehicle retrieved successfully",
            data=vehicle
        )
        
    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"Error fetching vehicle {vehicle_id}: {str(e)}")
        raise HTTPException(status_code=500, detail=str(e))

@router.post("/", response_model=VehicleResponse)
async def create_vehicle(
    vehicle: VehicleCreate,
    hive: HiveManager = Depends(get_hive_manager)
):
    """Create a new vehicle"""
    try:
        # Check if registration number already exists
        existing_vehicles = await hive.find_where("vehicles", registration_number=vehicle.registration_number)
        if existing_vehicles:
            raise HTTPException(status_code=400, detail="Vehicle with this registration number already exists")
        
        # Create vehicle
        vehicle_data = vehicle.dict()
        vehicle_id = await hive.insert("vehicles", vehicle_data)
        
        # Get the created vehicle
        created_vehicle = await hive.find_by_id("vehicles", vehicle_id)
        
        return VehicleResponse(
            success=True,
            message="Vehicle created successfully",
            data=created_vehicle
        )
        
    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"Error creating vehicle: {str(e)}")
        raise HTTPException(status_code=500, detail=str(e))

@router.put("/{vehicle_id}", response_model=VehicleResponse)
async def update_vehicle(
    vehicle_id: str,
    vehicle_update: VehicleUpdate,
    hive: HiveManager = Depends(get_hive_manager)
):
    """Update an existing vehicle"""
    try:
        # Check if vehicle exists
        existing_vehicle = await hive.find_by_id("vehicles", vehicle_id)
        if not existing_vehicle:
            raise HTTPException(status_code=404, detail="Vehicle not found")
        
        # Check if registration number is being updated and already exists
        if vehicle_update.registration_number:
            existing_with_reg = await hive.find_where("vehicles", registration_number=vehicle_update.registration_number)
            if existing_with_reg and existing_with_reg[0]["id"] != vehicle_id:
                raise HTTPException(status_code=400, detail="Vehicle with this registration number already exists")
        
        # Update vehicle
        update_data = {k: v for k, v in vehicle_update.dict().items() if v is not None}
        success = await hive.update("vehicles", vehicle_id, update_data)
        
        if not success:
            raise HTTPException(status_code=500, detail="Failed to update vehicle")
        
        # Get the updated vehicle
        updated_vehicle = await hive.find_by_id("vehicles", vehicle_id)
        
        return VehicleResponse(
            success=True,
            message="Vehicle updated successfully",
            data=updated_vehicle
        )
        
    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"Error updating vehicle {vehicle_id}: {str(e)}")
        raise HTTPException(status_code=500, detail=str(e))

@router.delete("/{vehicle_id}", response_model=BaseResponse)
async def delete_vehicle(
    vehicle_id: str,
    hive: HiveManager = Depends(get_hive_manager)
):
    """Delete a vehicle"""
    try:
        # Check if vehicle exists
        vehicle = await hive.find_by_id("vehicles", vehicle_id)
        if not vehicle:
            raise HTTPException(status_code=404, detail="Vehicle not found")
        
        # Check if vehicle has associated trips or fuel entries
        trips = await hive.find_where("trips", vehicle_id=vehicle_id)
        fuel_entries = await hive.find_where("fuel_entries", vehicle_id=vehicle_id)
        maintenance_records = await hive.find_where("maintenance", vehicle_id=vehicle_id)
        
        if trips or fuel_entries or maintenance_records:
            # Soft delete - mark as inactive
            await hive.update("vehicles", vehicle_id, {"status": "inactive"})
            return BaseResponse(
                success=True,
                message="Vehicle marked as inactive (has associated records)"
            )
        else:
            # Hard delete
            success = await hive.delete("vehicles", vehicle_id)
            if not success:
                raise HTTPException(status_code=500, detail="Failed to delete vehicle")
            
            return BaseResponse(
                success=True,
                message="Vehicle deleted successfully"
            )
        
    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"Error deleting vehicle {vehicle_id}: {str(e)}")
        raise HTTPException(status_code=500, detail=str(e))

@router.get("/{vehicle_id}/trips")
async def get_vehicle_trips(
    vehicle_id: str,
    hive: HiveManager = Depends(get_hive_manager)
):
    """Get all trips for a specific vehicle"""
    try:
        # Check if vehicle exists
        vehicle = await hive.find_by_id("vehicles", vehicle_id)
        if not vehicle:
            raise HTTPException(status_code=404, detail="Vehicle not found")
        
        # Get trips
        trips = await hive.find_where("trips", vehicle_id=vehicle_id)
        
        return {
            "success": True,
            "message": f"Retrieved {len(trips)} trips for vehicle {vehicle['registration_number']}",
            "data": trips
        }
        
    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"Error fetching trips for vehicle {vehicle_id}: {str(e)}")
        raise HTTPException(status_code=500, detail=str(e))

@router.get("/{vehicle_id}/fuel")
async def get_vehicle_fuel_entries(
    vehicle_id: str,
    hive: HiveManager = Depends(get_hive_manager)
):
    """Get all fuel entries for a specific vehicle"""
    try:
        # Check if vehicle exists
        vehicle = await hive.find_by_id("vehicles", vehicle_id)
        if not vehicle:
            raise HTTPException(status_code=404, detail="Vehicle not found")
        
        # Get fuel entries
        fuel_entries = await hive.find_where("fuel_entries", vehicle_id=vehicle_id)
        
        return {
            "success": True,
            "message": f"Retrieved {len(fuel_entries)} fuel entries for vehicle {vehicle['registration_number']}",
            "data": fuel_entries
        }
        
    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"Error fetching fuel entries for vehicle {vehicle_id}: {str(e)}")
        raise HTTPException(status_code=500, detail=str(e))

@router.get("/{vehicle_id}/maintenance")
async def get_vehicle_maintenance(
    vehicle_id: str,
    hive: HiveManager = Depends(get_hive_manager)
):
    """Get all maintenance records for a specific vehicle"""
    try:
        # Check if vehicle exists
        vehicle = await hive.find_by_id("vehicles", vehicle_id)
        if not vehicle:
            raise HTTPException(status_code=404, detail="Vehicle not found")
        
        # Get maintenance records
        maintenance_records = await hive.find_where("maintenance", vehicle_id=vehicle_id)
        
        return {
            "success": True,
            "message": f"Retrieved {len(maintenance_records)} maintenance records for vehicle {vehicle['registration_number']}",
            "data": maintenance_records
        }
        
    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"Error fetching maintenance records for vehicle {vehicle_id}: {str(e)}")
        raise HTTPException(status_code=500, detail=str(e))

@router.get("/{vehicle_id}/stats")
async def get_vehicle_stats(
    vehicle_id: str,
    hive: HiveManager = Depends(get_hive_manager)
):
    """Get statistics for a specific vehicle"""
    try:
        # Check if vehicle exists
        vehicle = await hive.find_by_id("vehicles", vehicle_id)
        if not vehicle:
            raise HTTPException(status_code=404, detail="Vehicle not found")
        
        # Get all related data
        trips = await hive.find_where("trips", vehicle_id=vehicle_id)
        fuel_entries = await hive.find_where("fuel_entries", vehicle_id=vehicle_id)
        maintenance_records = await hive.find_where("maintenance", vehicle_id=vehicle_id)
        
        # Calculate statistics
        total_distance = sum(trip.get("distance", 0) for trip in trips)
        total_fuel_cost = sum(fuel.get("cost", 0) for fuel in fuel_entries)
        total_maintenance_cost = sum(maintenance.get("cost", 0) for maintenance in maintenance_records)
        total_fuel_liters = sum(fuel.get("liters", 0) for fuel in fuel_entries)
        
        # Calculate fuel efficiency (km per liter)
        fuel_efficiency = total_distance / total_fuel_liters if total_fuel_liters > 0 else 0
        
        stats = {
            "vehicle_info": {
                "id": vehicle["id"],
                "registration_number": vehicle["registration_number"],
                "make_type": vehicle.get("make_type"),
                "current_odometer": vehicle.get("current_odometer", 0)
            },
            "trip_stats": {
                "total_trips": len(trips),
                "total_distance": total_distance,
                "average_distance_per_trip": total_distance / len(trips) if trips else 0
            },
            "fuel_stats": {
                "total_fuel_entries": len(fuel_entries),
                "total_fuel_liters": total_fuel_liters,
                "total_fuel_cost": total_fuel_cost,
                "average_cost_per_liter": total_fuel_cost / total_fuel_liters if total_fuel_liters > 0 else 0,
                "fuel_efficiency_kmpl": fuel_efficiency
            },
            "maintenance_stats": {
                "total_maintenance_records": len(maintenance_records),
                "total_maintenance_cost": total_maintenance_cost,
                "average_cost_per_service": total_maintenance_cost / len(maintenance_records) if maintenance_records else 0
            },
            "total_operating_cost": total_fuel_cost + total_maintenance_cost
        }
        
        return {
            "success": True,
            "message": f"Statistics for vehicle {vehicle['registration_number']}",
            "data": stats
        }
        
    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"Error calculating stats for vehicle {vehicle_id}: {str(e)}")
        raise HTTPException(status_code=500, detail=str(e))