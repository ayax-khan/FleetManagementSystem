#!/usr/bin/env python3
"""
Create a sample Excel file with proper format for testing
"""

import pandas as pd
from pathlib import Path

def create_sample_excel():
    """Create sample Excel file with multiple sheets"""
    
    # Sample Vehicles data
    vehicles_data = {
        'Registration Number': ['ABC-123', 'DEF-456', 'GHI-789', 'JKL-012'],
        'Make': ['Toyota', 'Honda', 'Suzuki', 'Nissan'],
        'Model Year': ['2020', '2019', '2021', '2018'],
        'Color': ['White', 'Blue', 'Red', 'Black'],
        'Fuel Type': ['Petrol', 'Diesel', 'Petrol', 'Diesel'],
        'Current Odometer': [45000, 67000, 23000, 89000],
        'Status': ['active', 'active', 'active', 'maintenance']
    }
    
    # Sample Drivers data
    drivers_data = {
        'Name': ['John Smith', 'Jane Doe', 'Mike Johnson', 'Sarah Wilson'],
        'Employee ID': ['EMP001', 'EMP002', 'EMP003', 'EMP004'],
        'License Number': ['DL12345', 'DL67890', 'DL11111', 'DL22222'],
        'Phone': ['555-0001', '555-0002', '555-0003', '555-0004'],
        'License Expiry': ['2025-12-31', '2024-06-30', '2026-03-15', '2025-09-20']
    }
    
    # Sample Fuel Entries data
    fuel_data = {
        'Vehicle ID': ['ABC-123', 'DEF-456', 'GHI-789', 'ABC-123'],
        'Date': ['2024-01-15', '2024-01-16', '2024-01-17', '2024-01-20'],
        'Liters': [45.5, 52.3, 38.2, 41.8],
        'Cost': [2275, 3138, 1910, 2090],
        'Odometer': [45500, 67200, 23150, 45800],
        'Fuel Type': ['Petrol', 'Diesel', 'Petrol', 'Petrol']
    }
    
    # Create Excel file with multiple sheets
    file_path = Path('sample_fleet_data.xlsx')
    
    with pd.ExcelWriter(file_path, engine='openpyxl') as writer:
        # Write each sheet
        pd.DataFrame(vehicles_data).to_excel(writer, sheet_name='Vehicles', index=False)
        pd.DataFrame(drivers_data).to_excel(writer, sheet_name='Drivers', index=False)
        pd.DataFrame(fuel_data).to_excel(writer, sheet_name='Fuel Entries', index=False)
    
    print(f"✅ Sample Excel file created: {file_path.absolute()}")
    print(f"📊 Contains 3 sheets: Vehicles ({len(vehicles_data['Registration Number'])} records), Drivers ({len(drivers_data['Name'])} records), Fuel Entries ({len(fuel_data['Vehicle ID'])} records)")
    
    return file_path

if __name__ == "__main__":
    create_sample_excel()