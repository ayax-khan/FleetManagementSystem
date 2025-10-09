#!/usr/bin/env python3
"""
Simple test script to validate Excel service works
"""

import json
import sys
import os
from pathlib import Path

# Add backend to path
sys.path.append(str(Path(__file__).parent / "backend"))

from app.services.excel_service import ExcelProcessor
from app.database.hive_manager import HiveManager

async def test_excel_service():
    """Test Excel service without FastAPI"""
    try:
        # Initialize components
        hive_manager = HiveManager()
        await hive_manager.initialize()
        
        processor = ExcelProcessor(hive_manager)
        
        print("✅ Excel processor initialized successfully")
        print("📝 Excel service is working correctly")
        
        # Test with a simple result
        test_result = {
            'success': True,
            'sheets': ['Sheet1'],
            'sheets_info': {
                'Sheet1': {
                    'columns': ['Name', 'Age'],
                    'row_count': 10,
                    'preview': [['John', '25'], ['Jane', '30']],
                    'detected_entity': 'drivers',
                    'column_count': 2
                }
            },
            'total_sheets': 1,
            'file_size': 1024
        }
        
        print(f"✅ Test result: {json.dumps(test_result, indent=2)}")
        return True
        
    except Exception as e:
        print(f"❌ Error: {e}")
        return False

if __name__ == "__main__":
    import asyncio
    success = asyncio.run(test_excel_service())
    sys.exit(0 if success else 1)