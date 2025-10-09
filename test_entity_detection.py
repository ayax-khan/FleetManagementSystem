#!/usr/bin/env python3
"""
Test entity detection for actual sheet names from Google Sheets
"""

import sys
from pathlib import Path

# Add backend to path
sys.path.append(str(Path(__file__).parent / "backend"))

from app.services.excel_service import ExcelProcessor
from app.database.hive_manager import HiveManager

async def test_entity_detection():
    """Test entity detection with actual sheet names"""
    try:
        # Initialize components
        hive_manager = HiveManager()
        await hive_manager.initialize()
        
        processor = ExcelProcessor(hive_manager)
        
        # Test sheet names from your Google Sheets
        test_sheets = {
            'Vehs': ['Registration', 'Make', 'Model', 'Year'],
            'Attendence': ['Name', 'Employee ID', 'Date', 'Status'],
            'OT': ['Employee', 'Hours', 'Rate', 'Total'],
            'DR': ['Date', 'Report', 'Status'],
            'WO & JO': ['Work Order', 'Description', 'Date'],
            'POL Prices': ['Date', 'Fuel Type', 'Price'],
            'Routes': ['Route Name', 'Start', 'End'],
        }
        
        print("🧪 Testing Entity Detection:")
        print("=" * 50)
        
        for sheet_name, columns in test_sheets.items():
            detected = processor._detect_entity_type(sheet_name, columns)
            print(f"Sheet: '{sheet_name}' -> Detected as: '{detected}'")
            
            # Expected mappings based on your description
            expected = {
                'Vehs': 'vehicles',
                'Attendence': 'drivers', 
                'OT': 'overtime',
                'DR': 'reporting',
                'WO & JO': 'job_orders',
                'POL Prices': 'fuel_prices',
                'Routes': 'routes'
            }
            
            if detected == expected.get(sheet_name):
                print(f"  ✅ Correct detection!")
            else:
                print(f"  ❌ Expected: {expected.get(sheet_name, 'unknown')}")
            print()
        
        return True
        
    except Exception as e:
        print(f"❌ Error: {e}")
        return False

if __name__ == "__main__":
    import asyncio
    success = asyncio.run(test_entity_detection())
    sys.exit(0 if success else 1)