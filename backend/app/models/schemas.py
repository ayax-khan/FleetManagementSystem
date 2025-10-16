"""
Fleet Management System - Pydantic Models
Data validation and serialization models
"""

from datetime import datetime
from typing import Optional, List
from pydantic import BaseModel, Field, validator

# Base Models
class BaseResponse(BaseModel):
    """Base response model"""
    success: bool
    message: str
    
class PaginatedResponse(BaseResponse):
    """Paginated response model"""
    total: int
    page: int
    per_page: int
    total_pages: int

# Vehicle Models
class VehicleBase(BaseModel):
    """Base vehicle model"""
    model_config = {'protected_namespaces': ()}
    
    registration_number: str = Field(..., min_length=1, max_length=50)
    make_type: Optional[str] = None
    model_year: Optional[str] = None
    color: Optional[str] = None
    engine_number: Optional[str] = None
    chassis_number: Optional[str] = None
    fuel_type: Optional[str] = None
    current_odometer: float = Field(default=0.0, ge=0)
    purchase_date: Optional[str] = None
    engine_cc: Optional[int] = None
    status: str = Field(default="active")

class VehicleCreate(VehicleBase):
    """Vehicle creation model"""
    pass

class VehicleUpdate(BaseModel):
    """Vehicle update model"""
    registration_number: Optional[str] = None
    make_type: Optional[str] = None
    model_year: Optional[str] = None
    color: Optional[str] = None
    engine_number: Optional[str] = None
    chassis_number: Optional[str] = None
    fuel_type: Optional[str] = None
    current_odometer: Optional[float] = None
    purchase_date: Optional[str] = None
    engine_cc: Optional[int] = None
    status: Optional[str] = None

class Vehicle(VehicleBase):
    """Vehicle response model"""
    id: str
    created_at: str
    updated_at: str

# Driver Models
class DriverBase(BaseModel):
    """Base driver model"""
    name: str = Field(..., min_length=1, max_length=100)
    employee_id: Optional[str] = None
    cnic: Optional[str] = None  # National ID
    license_number: str = Field(..., min_length=1)
    license_expiry: Optional[str] = None
    license_category: Optional[str] = Field(default="lightVehicle")
    phone: Optional[str] = None
    email: Optional[str] = None
    emergency_contact: Optional[str] = None
    address: Optional[str] = None
    date_of_birth: Optional[str] = None
    joining_date: Optional[str] = None
    basic_salary: Optional[float] = Field(default=50000.0, ge=0)
    assigned_vehicle: Optional[str] = None
    category: Optional[str] = Field(default="regular")
    notes: Optional[str] = None
    status: str = Field(default="active")

class DriverCreate(DriverBase):
    """Driver creation model"""
    pass

class DriverUpdate(BaseModel):
    """Driver update model"""
    name: Optional[str] = None
    employee_id: Optional[str] = None
    cnic: Optional[str] = None
    license_number: Optional[str] = None
    license_expiry: Optional[str] = None
    license_category: Optional[str] = None
    phone: Optional[str] = None
    email: Optional[str] = None
    emergency_contact: Optional[str] = None
    address: Optional[str] = None
    date_of_birth: Optional[str] = None
    joining_date: Optional[str] = None
    basic_salary: Optional[float] = None
    assigned_vehicle: Optional[str] = None
    category: Optional[str] = None
    notes: Optional[str] = None
    status: Optional[str] = None

class Driver(DriverBase):
    """Driver response model"""
    id: str
    created_at: str
    updated_at: str

# Trip Models
class TripBase(BaseModel):
    """Base trip model"""
    vehicle_id: str = Field(..., min_length=1)
    driver_id: Optional[str] = None
    start_km: float = Field(..., ge=0)
    end_km: Optional[float] = None
    start_time: str
    end_time: Optional[str] = None
    purpose: Optional[str] = None
    route: Optional[str] = None
    destination: Optional[str] = None
    officer_staff: Optional[str] = None
    coes: Optional[str] = None
    duty_detail: Optional[str] = None
    remarks: Optional[str] = None
    distance: Optional[float] = Field(default=0.0, ge=0)
    fuel_used: Optional[float] = Field(default=0.0, ge=0)
    status: str = Field(default="in_progress")

class TripCreate(TripBase):
    """Trip creation model"""
    pass

class TripUpdate(BaseModel):
    """Trip update model"""
    vehicle_id: Optional[str] = None
    driver_id: Optional[str] = None
    start_km: Optional[float] = None
    end_km: Optional[float] = None
    start_time: Optional[str] = None
    end_time: Optional[str] = None
    purpose: Optional[str] = None
    route: Optional[str] = None
    destination: Optional[str] = None
    officer_staff: Optional[str] = None
    coes: Optional[str] = None
    duty_detail: Optional[str] = None
    remarks: Optional[str] = None
    distance: Optional[float] = None
    fuel_used: Optional[float] = None
    status: Optional[str] = None

class Trip(TripBase):
    """Trip response model"""
    id: str
    created_at: str
    updated_at: str


# Fuel Entry Models
class FuelEntryBase(BaseModel):
    """Base fuel entry model"""
    vehicle_id: str = Field(..., min_length=1)
    driver_id: Optional[str] = None
    date: str
    liters: float = Field(..., gt=0)
    cost: float = Field(..., ge=0)
    odometer: float = Field(..., ge=0)
    fuel_type: str = Field(default="petrol")
    station: Optional[str] = None
    receipt_number: Optional[str] = None

class FuelEntryCreate(FuelEntryBase):
    """Fuel entry creation model"""
    pass

class FuelEntryUpdate(BaseModel):
    """Fuel entry update model"""
    vehicle_id: Optional[str] = None
    driver_id: Optional[str] = None
    date: Optional[str] = None
    liters: Optional[float] = None
    cost: Optional[float] = None
    odometer: Optional[float] = None
    fuel_type: Optional[str] = None
    station: Optional[str] = None
    receipt_number: Optional[str] = None

class FuelEntry(FuelEntryBase):
    """Fuel entry response model"""
    id: str
    created_at: str
    updated_at: str

# Maintenance Models
class MaintenanceBase(BaseModel):
    """Base maintenance model"""
    vehicle_id: str = Field(..., min_length=1)
    type: str = Field(..., min_length=1)  # service, repair, inspection
    description: str
    date: str
    cost: float = Field(..., ge=0)
    odometer: float = Field(..., ge=0)
    service_provider: Optional[str] = None
    next_service_km: Optional[float] = None
    next_service_date: Optional[str] = None
    status: str = Field(default="completed")

class MaintenanceCreate(MaintenanceBase):
    """Maintenance creation model"""
    pass

class MaintenanceUpdate(BaseModel):
    """Maintenance update model"""
    vehicle_id: Optional[str] = None
    type: Optional[str] = None
    description: Optional[str] = None
    date: Optional[str] = None
    cost: Optional[float] = None
    odometer: Optional[float] = None
    service_provider: Optional[str] = None
    next_service_km: Optional[float] = None
    next_service_date: Optional[str] = None
    status: Optional[str] = None

class Maintenance(MaintenanceBase):
    """Maintenance response model"""
    id: str
    created_at: str
    updated_at: str

# Excel Import Models
class ExcelAnalysisResult(BaseModel):
    """Excel file analysis result"""
    model_config = {'extra': 'allow'}
    
    success: bool
    total_sheets: Optional[int] = None
    sheets: Optional[List[str]] = None
    sheets_info: Optional[dict] = None
    file_size: Optional[int] = None
    error: Optional[str] = None
    suggestion: Optional[str] = None

class ExcelImportRequest(BaseModel):
    """Excel import request"""
    selected_sheets: Optional[List[str]] = None
    entity_mappings: Optional[dict] = None
    clear_existing: bool = False

class ExcelImportResult(BaseModel):
    """Excel import result"""
    success: bool
    message: str
    summary: Optional[dict] = None
    total_imported: Optional[int] = None
    errors: Optional[List[str]] = None

# API Response Models
class VehicleListResponse(BaseResponse):
    """Vehicle list response"""
    data: List[Vehicle]

class VehicleResponse(BaseResponse):
    """Single vehicle response"""
    data: Vehicle

class DriverListResponse(BaseResponse):
    """Driver list response"""
    data: List[Driver]

class DriverResponse(BaseResponse):
    """Single driver response"""
    data: Driver

class TripListResponse(BaseResponse):
    """Trip list response"""
    data: List[Trip]

class TripResponse(BaseResponse):
    """Single trip response"""
    data: Trip

class FuelEntryListResponse(BaseResponse):
    """Fuel entry list response"""
    data: List[FuelEntry]

class FuelEntryResponse(BaseResponse):
    """Single fuel entry response"""
    data: FuelEntry

class MaintenanceListResponse(BaseResponse):
    """Maintenance list response"""
    data: List[Maintenance]

class MaintenanceResponse(BaseResponse):
    """Single maintenance response"""
    data: Maintenance

class DatabaseStatsResponse(BaseResponse):
    """Database statistics response"""
    data: dict