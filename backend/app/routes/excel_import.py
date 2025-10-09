"""
Fleet Management System - Excel Import API Routes
"""

from fastapi import APIRouter, HTTPException, Depends, Request, UploadFile, File, Form
from pathlib import Path
import tempfile
import logging

from app.models.schemas import (
    DatabaseStatsResponse
)
from app.database.hive_manager import HiveManager
from app.services.excel_service import ExcelProcessor

router = APIRouter()
logger = logging.getLogger(__name__)

def get_hive_manager(request: Request) -> HiveManager:
    return request.app.state.hive_manager

def get_excel_processor(hive: HiveManager = Depends(get_hive_manager)) -> ExcelProcessor:
    return ExcelProcessor(hive)

@router.post("/analyze")
async def analyze_excel_file(
    file: UploadFile = File(...),
    processor: ExcelProcessor = Depends(get_excel_processor)
):
    """Analyze an uploaded Excel file to detect sheets and data structure"""
    try:
        # Validate file type
        if not file.filename or not file.filename.lower().endswith(('.xlsx', '.xls')):
            raise HTTPException(status_code=400, detail="Only Excel files (.xlsx, .xls) are supported")
        
        # Create temporary file with proper handling
        temp_path = None
        try:
            # Save uploaded file to temporary location
            content = await file.read()
            temp_path = Path(tempfile.gettempdir()) / f"excel_import_{file.filename}_{hash(content) % 10000}.xlsx"
            
            # Write file content
            with open(temp_path, 'wb') as temp_file:
                temp_file.write(content)
            
            # Analyze the file
            analysis_result = await processor.analyze_excel_file(temp_path)
            
            return analysis_result
            
        finally:
            # Clean up temporary file
            if temp_path and temp_path.exists():
                try:
                    temp_path.unlink()
                except:
                    pass  # Ignore cleanup errors
        
    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"Error analyzing Excel file: {str(e)}")
        raise HTTPException(status_code=500, detail=str(e))

@router.post("/import")
async def import_excel_file(
    file: UploadFile = File(...),
    selected_sheets: str = Form(""),
    clear_existing: bool = Form(False),
    processor: ExcelProcessor = Depends(get_excel_processor)
):
    """Import data from an uploaded Excel file"""
    try:
        # Validate file type
        if not file.filename or not file.filename.lower().endswith(('.xlsx', '.xls')):
            raise HTTPException(status_code=400, detail="Only Excel files (.xlsx, .xls) are supported")
        
        # Create temporary file with proper handling
        temp_path = None
        try:
            # Save uploaded file to temporary location
            content = await file.read()
            temp_path = Path(tempfile.gettempdir()) / f"excel_import_{file.filename}_{hash(content) % 10000}.xlsx"
            
            # Write file content
            with open(temp_path, 'wb') as temp_file:
                temp_file.write(content)
            
            # Parse selected sheets
            sheets_list = [s.strip() for s in selected_sheets.split(',') if s.strip()] if selected_sheets else None
            
            # Debug logging - using print to ensure visibility
            print(f"🔍 BACKEND DEBUG: Raw selected_sheets param: '{selected_sheets}'")
            print(f"🔍 BACKEND DEBUG: Parsed sheets_list: {sheets_list}")
            print(f"🔍 BACKEND DEBUG: Clear existing: {clear_existing}")
            
            # Import the file
            import_result = await processor.import_excel_file(
                temp_path,
                selected_sheets=sheets_list,
                entity_mappings=None,
                clear_existing=clear_existing
            )
            
            return import_result
            
        finally:
            # Clean up temporary file
            if temp_path and temp_path.exists():
                try:
                    temp_path.unlink()
                except:
                    pass  # Ignore cleanup errors
        
    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"Error importing Excel file: {str(e)}")
        raise HTTPException(status_code=500, detail=str(e))

@router.get("/export")
async def export_to_excel(
    tables: str = "all",  # comma-separated list of tables or "all"
    processor: ExcelProcessor = Depends(get_excel_processor)
):
    """Export database data to Excel file"""
    try:
        # Parse tables parameter
        if tables == "all":
            selected_tables = None
        else:
            selected_tables = [t.strip() for t in tables.split(",")]
        
        # Create temporary file for export
        with tempfile.NamedTemporaryFile(delete=False, suffix='.xlsx') as temp_file:
            temp_path = Path(temp_file.name)
        
        try:
            # Export data
            export_result = await processor.export_to_excel(temp_path, selected_tables)
            
            if export_result['success']:
                # Return the file
                from fastapi.responses import FileResponse
                return FileResponse(
                    path=temp_path,
                    filename="fleet_management_export.xlsx",
                    media_type="application/vnd.openxmlformats-officedocument.spreadsheetml.sheet"
                )
            else:
                raise HTTPException(status_code=500, detail=export_result['message'])
                
        except Exception as e:
            # Clean up on error
            temp_path.unlink(missing_ok=True)
            raise
        
    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"Error exporting to Excel: {str(e)}")
        raise HTTPException(status_code=500, detail=str(e))

@router.get("/database/stats", response_model=DatabaseStatsResponse)
async def get_database_stats(
    hive: HiveManager = Depends(get_hive_manager)
):
    """Get database statistics"""
    try:
        stats = await hive.get_stats()
        
        return DatabaseStatsResponse(
            success=True,
            message="Database statistics retrieved successfully",
            data=stats
        )
        
    except Exception as e:
        logger.error(f"Error fetching database stats: {str(e)}")
        raise HTTPException(status_code=500, detail=str(e))

@router.post("/database/clear/{table}")
async def clear_table(
    table: str,
    hive: HiveManager = Depends(get_hive_manager)
):
    """Clear all data from a specific table"""
    try:
        # Validate table name
        valid_tables = ["vehicles", "drivers", "trips", "fuel_entries", "maintenance", "job_orders", "routes", "fuel_prices"]
        if table not in valid_tables:
            raise HTTPException(status_code=400, detail=f"Invalid table name. Valid tables: {', '.join(valid_tables)}")
        
        success = await hive.clear_table(table)
        
        if success:
            return {
                "success": True,
                "message": f"Table '{table}' cleared successfully"
            }
        else:
            raise HTTPException(status_code=500, detail=f"Failed to clear table '{table}'")
        
    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"Error clearing table {table}: {str(e)}")
        raise HTTPException(status_code=500, detail=str(e))

@router.post("/database/clear-all")
async def clear_all_tables(
    hive: HiveManager = Depends(get_hive_manager)
):
    """Clear all data from all tables"""
    try:
        tables = ["vehicles", "drivers", "trips", "fuel_entries", "maintenance", "job_orders", "routes", "fuel_prices"]
        cleared_tables = []
        
        for table in tables:
            try:
                success = await hive.clear_table(table)
                if success:
                    cleared_tables.append(table)
            except Exception as e:
                logger.error(f"Error clearing table {table}: {str(e)}")
        
        return {
            "success": True,
            "message": f"Cleared {len(cleared_tables)} tables",
            "cleared_tables": cleared_tables
        }
        
    except Exception as e:
        logger.error(f"Error clearing all tables: {str(e)}")
        raise HTTPException(status_code=500, detail=str(e))