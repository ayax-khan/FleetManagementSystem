"""
Fleet Management System - Excel Processing Service
Handles Excel import/export using Pandas and OpenPyXL
"""

import pandas as pd
import openpyxl
import json
import asyncio
from pathlib import Path
from datetime import datetime
from typing import Dict, List, Any, Optional, Tuple
from uuid import uuid4
import logging

from app.core.config import settings
from app.database.hive_manager import HiveManager

logger = logging.getLogger(__name__)

class ExcelProcessor:
    """Excel processing service with Pandas and OpenPyXL"""
    
    def __init__(self, hive_manager: HiveManager):
        self.hive_manager = hive_manager
        self.sheet_mappings = {
            "vehicles": ["vehs", "vehicles", "fleet", "cars", "vehicle"],
            "drivers": ["attendence", "attendance", "drivers", "driver", "employees", "staff", "personnel"],
            "trips": ["log book", "logbook", "trips", "journey", "travel", "trip", "logs"],
            "fuel_entries": ["pol soi & ent", "pol utilized", "pol exp (rs)", "pol monthly", "pol (rs)", "fuel", "petrol", "diesel"],
            "fuel_prices": ["pol prices", "fuel prices", "price", "rates", "pol state"],
            "job_orders": ["wo & jo", "job orders", "work orders", "jobs", "orders"],
            "maintenance": ["maintenance", "service", "repair", "budget"],
            "routes": ["routes", "route", "path", "destination"],
            "reporting": ["dr", "daily reporting", "spd reporting", "summary", "summary detail"],
            "overtime": ["ot", "overtime", "over time"]
        }
        
        self.field_mappings = {
            "vehicles": {
                "registration_number": ["registration", "reg no", "reg #", "vehicle no", "number", "plate"],
                "make_type": ["make", "make & type", "brand", "manufacturer"],
                "model_year": ["model", "year", "model year"],
                "color": ["color", "colour"],
                "engine_number": ["engine no", "engine #", "engine number", "engine"],
                "chassis_number": ["chassis no", "chassis #", "chassis number", "chassis"],
                "fuel_type": ["fuel type", "fuel", "petrol/diesel"],
                "current_odometer": ["odometer", "mileage", "km"],
                "purchase_date": ["purchase date", "bought date", "date"],
                "engine_cc": ["engine cc", "cc", "ep(cc)", "engine capacity"]
            },
            "drivers": {
                "name": ["name", "driver name", "full name", "driver"],
                "employee_id": ["employee id", "emp id", "staff id"],
                "license_number": ["license", "license number", "dl", "driving license"],
                "license_expiry": ["license expiry", "expiry date", "dl expiry"],
                "phone": ["phone", "mobile", "contact", "cell"],
                "emergency_contact": ["emergency contact", "emergency phone"],
                "address": ["address", "location", "residence"],
                "joining_date": ["hire date", "joining date", "start date"],
                "assigned_vehicle": ["assigned vehicle", "vehicle", "assigned to"]
            },
            "trips": {
                "vehicle_id": ["vehicle id", "vehicle", "reg no", "registration"],
                "driver_id": ["driver id", "driver", "driver name"],
                "start_km": ["start odometer", "start km", "opening km"],
                "end_km": ["end odometer", "end km", "closing km"],
                "start_time": ["start time", "date", "trip date", "departure"],
                "end_time": ["end time", "end date", "arrival"],
                "purpose": ["purpose", "reason", "description", "trip purpose"],
                "route": ["route id", "route", "path"],
                "distance": ["distance", "km traveled", "total km"],
                "fuel_used": ["fuel used", "fuel consumed", "liters"]
            },
            "fuel_entries": {
                "vehicle_id": ["vehicle id", "vehicle", "reg no", "registration"],
                "driver_id": ["driver id", "driver", "driver name"],
                "date": ["date", "fuel date", "purchase date"],
                "liters": ["liters", "quantity", "fuel quantity", "amount"],
                "cost": ["cost", "amount", "price", "total"],
                "odometer": ["odometer", "mileage", "km"],
                "fuel_type": ["fuel type", "type", "petrol", "diesel"],
                "station": ["station", "fuel station", "pump"],
                "receipt_number": ["receipt", "bill no", "receipt no"]
            },
            "maintenance": {
                "vehicle_id": ["vehicle id", "vehicle", "reg no", "registration"],
                "type": ["type", "service type", "maintenance type"],
                "description": ["description", "details", "work done"],
                "date": ["date", "service date", "maintenance date"],
                "cost": ["cost", "amount", "price", "total"],
                "odometer": ["odometer", "mileage", "km"],
                "service_provider": ["provider", "garage", "workshop"],
                "next_service_km": ["next service km", "next km"],
                "next_service_date": ["next service date", "due date"]
            },
            "job_orders": {
                "vehicle_id": ["vehicle id", "vehicle", "reg no", "registration"],
                "order_number": ["order no", "job no", "wo no", "work order"],
                "description": ["description", "work description", "job description"],
                "date": ["date", "order date", "work date"],
                "cost": ["cost", "amount", "price", "total"],
                "status": ["status", "work status", "job status"]
            },
            "fuel_prices": {
                "date": ["date", "price date"],
                "fuel_type": ["fuel type", "type", "petrol", "diesel"],
                "price_per_liter": ["price", "rate", "price per liter", "cost"],
                "location": ["location", "station", "area"]
            },
            "routes": {
                "route_name": ["route", "route name", "name"],
                "start_location": ["start", "from", "origin", "start location"],
                "end_location": ["end", "to", "destination", "end location"],
                "distance": ["distance", "km", "kilometers"],
                "estimated_time": ["time", "duration", "estimated time"]
            },
            "reporting": {
                "date": ["date", "report date"],
                "vehicle_id": ["vehicle", "vehicle id", "reg no"],
                "description": ["description", "details", "report"],
                "status": ["status", "report status"]
            },
            "overtime": {
                "employee_id": ["employee", "employee id", "staff id"],
                "date": ["date", "overtime date"],
                "hours": ["hours", "ot hours", "overtime hours"],
                "rate": ["rate", "hourly rate"],
                "total": ["total", "amount"]
            }
        }
    
    async def analyze_excel_file(self, file_path: Path) -> Dict[str, Any]:
        """Analyze Excel file structure and detect entity types"""
        try:
            # Check if file exists and is accessible
            if not file_path.exists():
                return {
                    "success": False,
                    "error": f"File not found: {file_path}",
                    "suggestion": "Please check the file path and ensure the file exists."
                }
            
            # Read all sheets using pandas
            try:
                excel_file = pd.ExcelFile(file_path)
            except Exception as e:
                return {
                    "success": False,
                    "error": f"Cannot read Excel file: {str(e)}",
                    "suggestion": "Ensure the file is a valid Excel (.xlsx or .xls) file and not corrupted."
                }
            
            sheets_info = {}
            
            for sheet_name in excel_file.sheet_names:
                try:
                    # Read first few rows for preview
                    df = pd.read_excel(file_path, sheet_name=sheet_name, nrows=5)
                    
                    # Get full row count
                    full_df = pd.read_excel(file_path, sheet_name=sheet_name)
                    row_count = len(full_df)
                    
                    sheets_info[sheet_name] = {
                        'columns': [str(col) for col in df.columns.tolist()],
                        'row_count': int(row_count),
                        'preview': [[str(cell) if cell is not None else '' for cell in row] for row in df.head().fillna('').values.tolist()],
                        'detected_entity': str(self._detect_entity_type(sheet_name, df.columns.tolist())),
                        'column_count': int(len(df.columns))
                    }
                    
                except Exception as e:
                    logger.error(f"Error analyzing sheet '{sheet_name}': {str(e)}")
                    sheets_info[sheet_name] = {
                        'error': str(e),
                        'columns': [],
                        'row_count': int(0),
                        'preview': [],
                        'detected_entity': str('unknown'),
                        'column_count': int(0)
                    }
            
            return {
                'success': True,
                'sheets': list(excel_file.sheet_names),
                'sheets_info': sheets_info,
                'total_sheets': int(len(excel_file.sheet_names)),
                'file_size': int(file_path.stat().st_size)
            }
            
        except Exception as e:
            logger.error(f"Excel analysis failed: {str(e)}")
            return {
                'success': False,
                'error': str(e),
                'suggestion': self._get_error_suggestion(str(e))
            }
    
    def _detect_entity_type(self, sheet_name: str, columns: List[str]) -> str:
        """Detect what type of entity this sheet contains"""
        sheet_lower = sheet_name.lower()
        columns_lower = [str(col).lower() for col in columns]
        
        # Check sheet name patterns first
        for entity, patterns in self.sheet_mappings.items():
            if any(pattern in sheet_lower for pattern in patterns):
                return entity
        
        # Check column patterns
        best_match = 'unknown'
        best_score = 0
        
        for entity, field_mappings in self.field_mappings.items():
            score = 0
            total_fields = len(field_mappings)
            
            for field, patterns in field_mappings.items():
                for pattern in patterns:
                    if any(pattern in col for col in columns_lower):
                        score += 1
                        break
            
            # Calculate match percentage
            match_percentage = score / total_fields if total_fields > 0 else 0
            
            if match_percentage > best_score and match_percentage > 0.3:
                best_score = match_percentage
                best_match = entity
        
        return best_match
    
    async def import_excel_file(self, file_path: Path, selected_sheets: Optional[List[str]] = None, 
                               entity_mappings: Optional[Dict[str, str]] = None, 
                               clear_existing: bool = False) -> Dict[str, Any]:
        """Import Excel file data into Hive database"""
        try:
            # First analyze the file
            analysis = await self.analyze_excel_file(file_path)
            if not analysis['success']:
                return analysis
            
            imported_data = {}
            summary = {}
            errors = []
            
            # Clear existing data if requested
            if clear_existing:
                for entity_type in self.field_mappings.keys():
                    await self.hive_manager.clear_table(entity_type)
            
            # Process ONLY selected sheets - CRITICAL FIX
            print(f"🔍 EXCEL SERVICE DEBUG: Selected sheets for import: {selected_sheets}")
            print(f"🔍 EXCEL SERVICE DEBUG: Available sheets: {analysis['sheets']}")
            
            # If no sheets selected, return error
            if not selected_sheets:
                return {
                    'success': False,
                    'message': 'No sheets selected for import',
                    'errors': ['Please select at least one sheet to import']
                }
            
            # Process ONLY the selected sheets
            for sheet_name in selected_sheets:
                if sheet_name not in analysis['sheets']:
                    print(f"⚠️ EXCEL SERVICE WARNING: Selected sheet '{sheet_name}' not found in file")
                    continue
                
                print(f"🔍 EXCEL SERVICE DEBUG: Processing selected sheet '{sheet_name}' for import")
                
                try:
                    # Determine entity type
                    if entity_mappings and sheet_name in entity_mappings:
                        entity_type = entity_mappings[sheet_name]
                        logger.info(f"Sheet '{sheet_name}' mapped to entity type: {entity_type}")
                    else:
                        entity_type = analysis['sheets_info'][sheet_name]['detected_entity']
                        logger.info(f"Sheet '{sheet_name}' detected as entity type: {entity_type}")
                    
                    if entity_type == 'unknown':
                        logger.warning(f"Skipping sheet '{sheet_name}' - unknown entity type")
                        continue
                    
                    # Import the sheet
                    sheet_data = await self._import_sheet(file_path, sheet_name, entity_type)
                    
                    if sheet_data:
                        # Insert into database
                        inserted_ids = await self.hive_manager.insert_many(entity_type, sheet_data)
                        
                        imported_data[entity_type] = imported_data.get(entity_type, 0) + len(sheet_data)
                        summary[sheet_name] = {
                            'entity_type': entity_type,
                            'records': len(sheet_data),
                            'inserted_ids': inserted_ids[:5]  # First 5 IDs for reference
                        }
                
                except Exception as e:
                    error_msg = f"Error processing sheet '{sheet_name}': {str(e)}"
                    logger.error(error_msg)
                    errors.append(error_msg)
            
            return {
                'success': True,
                'message': f'Excel import completed. Imported {sum(imported_data.values())} records.',
                'summary': summary,
                'total_imported': sum(imported_data.values()),
                'errors': errors
            }
            
        except Exception as e:
            logger.error(f"Excel import failed: {str(e)}")
            return {
                'success': False,
                'message': f'Excel import failed: {str(e)}',
                'suggestion': self._get_error_suggestion(str(e))
            }
    
    async def _import_sheet(self, file_path: Path, sheet_name: str, entity_type: str) -> List[Dict[str, Any]]:
        """Import a specific sheet as an entity type"""
        try:
            # Read the sheet
            df = pd.read_excel(file_path, sheet_name=sheet_name)
            
            if df.empty:
                print(f"🔍 SHEET DEBUG: Sheet '{sheet_name}' is empty")
                return []
            
            # Clean column names
            original_columns = list(df.columns)
            df.columns = df.columns.astype(str).str.lower().str.strip()
            cleaned_columns = list(df.columns)
            
            print(f"🔍 SHEET DEBUG: Sheet '{sheet_name}' has {len(df)} rows")
            print(f"🔍 SHEET DEBUG: Original columns: {original_columns}")
            print(f"🔍 SHEET DEBUG: Cleaned columns: {cleaned_columns}")
            
            # Get field mappings for this entity
            if entity_type not in self.field_mappings:
                raise Exception(f"No field mappings found for entity type: {entity_type}")
            
            field_mappings = self.field_mappings[entity_type]
            print(f"🔍 SHEET DEBUG: Field mappings for {entity_type}: {field_mappings}")
            
            records = []
            valid_records = 0
            invalid_records = 0
            
            for index, row in df.iterrows():
                try:
                    record = self._map_row_to_entity(row, field_mappings, entity_type)
                    print(f"🔍 ROW DEBUG {index+1}: Mapped record: {record}")
                    
                    if record and self._is_valid_record(record, entity_type):
                        records.append(record)
                        valid_records += 1
                        print(f"✅ ROW {index+1}: Record is VALID")
                    else:
                        invalid_records += 1
                        print(f"❌ ROW {index+1}: Record is INVALID - missing required fields")
                        print(f"❌ ROW {index+1}: Required fields check result: {self._is_valid_record(record, entity_type)}")
                        
                except Exception as e:
                    invalid_records += 1
                    print(f"❌ ROW {index+1}: Error processing - {str(e)}")
                    logger.error(f"Error processing row {index + 1} in sheet '{sheet_name}': {str(e)}")
            
            print(f"🔍 SHEET SUMMARY: {sheet_name} -> {valid_records} valid, {invalid_records} invalid, {len(records)} total records")
            return records
            
        except Exception as e:
            raise Exception(f"Failed to import sheet '{sheet_name}': {str(e)}")
    
    def _map_row_to_entity(self, row: pd.Series, field_mappings: Dict[str, List[str]], entity_type: str) -> Dict[str, Any]:
        """Map a row to an entity record"""
        record = {}
        
        for field, column_patterns in field_mappings.items():
            value = None
            
            # Find matching column
            for pattern in column_patterns:
                for col_name in row.index:
                    if pattern.lower() in str(col_name).lower():
                        value = row[col_name]
                        break
                if value is not None and pd.notna(value):
                    break
            
            # Process the value based on field type
            if value is not None and pd.notna(value):
                record[field] = self._process_field_value(value, field, entity_type)
        
        return record
    
    def _process_field_value(self, value: Any, field_name: str, entity_type: str) -> Any:
        """Process field value based on its type"""
        try:
            # Handle dates
            if 'date' in field_name or 'time' in field_name:
                if isinstance(value, (pd.Timestamp, datetime)):
                    return value.isoformat()
                elif isinstance(value, str) and value.strip():
                    try:
                        return pd.to_datetime(value).isoformat()
                    except:
                        return value.strip()
                else:
                    return str(value) if pd.notna(value) else None
            
            # Handle numbers
            elif field_name in ['current_odometer', 'engine_cc', 'start_km', 'end_km', 'distance', 'fuel_used', 'liters', 'cost', 'odometer']:
                try:
                    return float(value) if pd.notna(value) else 0.0
                except (ValueError, TypeError):
                    return 0.0
            
            # Handle strings
            else:
                return str(value).strip() if pd.notna(value) and str(value).strip() else None
                
        except Exception as e:
            logger.error(f"Error processing field value '{value}' for field '{field_name}': {str(e)}")
            return str(value) if pd.notna(value) else None
    
    def _is_valid_record(self, record: Dict[str, Any], entity_type: str) -> bool:
        """Check if record has minimum required fields"""
        required_fields = {
            'vehicles': ['registration_number'],
            'drivers': ['name'],
            'trips': ['vehicle_id', 'start_km', 'start_time'],
            'fuel_entries': ['vehicle_id', 'liters', 'date'],
            'maintenance': ['vehicle_id', 'type', 'date'],
            'job_orders': ['description', 'date'],
            'fuel_prices': ['fuel_type', 'price_per_liter'],
            'routes': ['route_name'],
            'reporting': ['date', 'description'],
            'overtime': ['employee_id', 'hours']
        }
        
        if entity_type in required_fields:
            missing_fields = []
            for field in required_fields[entity_type]:
                field_value = record.get(field)
                if not field_value:
                    missing_fields.append(f"{field}={field_value}")
            
            if missing_fields:
                print(f"❌ VALIDATION: Record invalid for {entity_type} - missing: {missing_fields}")
                print(f"❌ VALIDATION: Record contents: {record}")
                return False
        
        return True
    
    async def export_to_excel(self, output_path: Path, tables: Optional[List[str]] = None) -> Dict[str, Any]:
        """Export Hive database data to Excel file"""
        try:
            if tables is None:
                tables = list(self.field_mappings.keys())
            
            with pd.ExcelWriter(output_path, engine='openpyxl') as writer:
                summary = {}
                
                for table in tables:
                    try:
                        # Get data from Hive
                        records = await self.hive_manager.find_all(table)
                        
                        if records:
                            # Convert to DataFrame
                            df = pd.DataFrame(records)
                            
                            # Remove internal fields
                            if 'id' in df.columns:
                                df = df.drop(columns=['id'])
                            if 'created_at' in df.columns:
                                df = df.drop(columns=['created_at'])
                            if 'updated_at' in df.columns:
                                df = df.drop(columns=['updated_at'])
                            
                            # Write to sheet
                            sheet_name = table.replace('_', ' ').title()
                            df.to_excel(writer, sheet_name=sheet_name, index=False)
                            
                            summary[table] = len(records)
                        else:
                            # Create empty sheet
                            pd.DataFrame().to_excel(writer, sheet_name=table.replace('_', ' ').title(), index=False)
                            summary[table] = 0
                            
                    except Exception as e:
                        logger.error(f"Error exporting table '{table}': {str(e)}")
                        summary[table] = f"Error: {str(e)}"
            
            return {
                'success': True,
                'message': f'Data exported successfully to {output_path}',
                'summary': summary,
                'file_path': str(output_path)
            }
            
        except Exception as e:
            logger.error(f"Export failed: {str(e)}")
            return {
                'success': False,
                'message': f'Export failed: {str(e)}',
                'suggestion': 'Ensure you have write permissions to the output directory.'
            }
    
    def _get_error_suggestion(self, error_str: str) -> str:
        """Provide helpful suggestions based on error"""
        error_lower = error_str.lower()
        
        if 'permission' in error_lower:
            return "File may be open in Excel. Please close Excel and try again."
        elif 'corrupted' in error_lower or 'invalid' in error_lower:
            return "File may be corrupted. Try opening and re-saving in Excel."
        elif 'sheet' in error_lower:
            return "Check if the Excel file contains the expected sheets with data."
        elif 'encoding' in error_lower:
            return "File encoding issue. Save the file as a new Excel (.xlsx) file."
        elif 'memory' in error_lower:
            return "File may be too large. Try splitting into smaller files."
        else:
            return "Ensure the file is a valid Excel (.xlsx or .xls) file with proper data formatting."