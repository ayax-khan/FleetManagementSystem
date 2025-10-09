"""
Fleet Management System - Hive Database Manager
Handles all database operations using a simple file-based approach
"""

import json
import asyncio
import aiofiles
import os
from pathlib import Path
from datetime import datetime
from typing import Dict, List, Any, Optional
from uuid import uuid4

from app.core.config import settings

class HiveManager:
    """Simple file-based database manager mimicking Hive behavior"""
    
    def __init__(self):
        self.db_path = Path(settings.HIVE_DB_PATH)
        self.tables = {
            'vehicles': 'vehicles.json',
            'drivers': 'drivers.json', 
            'trips': 'trips.json',
            'fuel_entries': 'fuel_entries.json',
            'maintenance': 'maintenance.json',
            'job_orders': 'job_orders.json',
            'routes': 'routes.json',
            'fuel_prices': 'fuel_prices.json',
            'reporting': 'reporting.json',
            'overtime': 'overtime.json'
        }
        self._locks = {table: asyncio.Lock() for table in self.tables}
    
    async def initialize(self):
        """Initialize database structure"""
        # Ensure database directory exists
        self.db_path.mkdir(parents=True, exist_ok=True)
        
        # Initialize table files if they don't exist
        for table_name, filename in self.tables.items():
            file_path = self.db_path / filename
            if not file_path.exists():
                await self._write_file(file_path, [])
                
        print(f"🗄️ Hive database initialized at: {self.db_path}")
    
    async def close(self):
        """Close database connections"""
        print("📁 Closing Hive database connections...")
    
    async def _read_file(self, file_path: Path) -> List[Dict]:
        """Read JSON file asynchronously"""
        try:
            async with aiofiles.open(file_path, 'r', encoding='utf-8') as f:
                content = await f.read()
                return json.loads(content) if content.strip() else []
        except (FileNotFoundError, json.JSONDecodeError):
            return []
    
    async def _write_file(self, file_path: Path, data: List[Dict]):
        """Write JSON file asynchronously"""
        async with aiofiles.open(file_path, 'w', encoding='utf-8') as f:
            await f.write(json.dumps(data, indent=2, ensure_ascii=False, default=str))
    
    def _generate_id(self) -> str:
        """Generate unique ID"""
        return str(uuid4())
    
    async def insert(self, table: str, data: Dict) -> str:
        """Insert record into table"""
        if table not in self.tables:
            raise ValueError(f"Table '{table}' does not exist")
        
        async with self._locks[table]:
            file_path = self.db_path / self.tables[table]
            records = await self._read_file(file_path)
            
            # Add metadata
            record = {
                'id': self._generate_id(),
                'created_at': datetime.now().isoformat(),
                'updated_at': datetime.now().isoformat(),
                **data
            }
            
            records.append(record)
            await self._write_file(file_path, records)
            
            return record['id']
    
    async def insert_many(self, table: str, data_list: List[Dict]) -> List[str]:
        """Insert multiple records into table"""
        if table not in self.tables:
            raise ValueError(f"Table '{table}' does not exist")
        
        async with self._locks[table]:
            file_path = self.db_path / self.tables[table]
            records = await self._read_file(file_path)
            
            inserted_ids = []
            for data in data_list:
                record = {
                    'id': self._generate_id(),
                    'created_at': datetime.now().isoformat(),
                    'updated_at': datetime.now().isoformat(),
                    **data
                }
                records.append(record)
                inserted_ids.append(record['id'])
            
            await self._write_file(file_path, records)
            return inserted_ids
    
    async def find_all(self, table: str) -> List[Dict]:
        """Get all records from table"""
        if table not in self.tables:
            raise ValueError(f"Table '{table}' does not exist")
        
        file_path = self.db_path / self.tables[table]
        return await self._read_file(file_path)
    
    async def find_by_id(self, table: str, record_id: str) -> Optional[Dict]:
        """Find record by ID"""
        records = await self.find_all(table)
        for record in records:
            if record.get('id') == record_id:
                return record
        return None
    
    async def find_where(self, table: str, **filters) -> List[Dict]:
        """Find records matching filters"""
        records = await self.find_all(table)
        result = []
        
        for record in records:
            matches = True
            for key, value in filters.items():
                if key not in record or record[key] != value:
                    matches = False
                    break
            if matches:
                result.append(record)
        
        return result
    
    async def update(self, table: str, record_id: str, data: Dict) -> bool:
        """Update record by ID"""
        if table not in self.tables:
            raise ValueError(f"Table '{table}' does not exist")
        
        async with self._locks[table]:
            file_path = self.db_path / self.tables[table]
            records = await self._read_file(file_path)
            
            updated = False
            for i, record in enumerate(records):
                if record.get('id') == record_id:
                    records[i] = {
                        **record,
                        **data,
                        'updated_at': datetime.now().isoformat()
                    }
                    updated = True
                    break
            
            if updated:
                await self._write_file(file_path, records)
            
            return updated
    
    async def delete(self, table: str, record_id: str) -> bool:
        """Delete record by ID"""
        if table not in self.tables:
            raise ValueError(f"Table '{table}' does not exist")
        
        async with self._locks[table]:
            file_path = self.db_path / self.tables[table]
            records = await self._read_file(file_path)
            
            original_count = len(records)
            records = [r for r in records if r.get('id') != record_id]
            
            if len(records) < original_count:
                await self._write_file(file_path, records)
                return True
            
            return False
    
    async def clear_table(self, table: str) -> bool:
        """Clear all records from table"""
        if table not in self.tables:
            raise ValueError(f"Table '{table}' does not exist")
        
        async with self._locks[table]:
            file_path = self.db_path / self.tables[table]
            await self._write_file(file_path, [])
            return True
    
    async def get_stats(self) -> Dict:
        """Get database statistics"""
        stats = {}
        for table_name in self.tables:
            records = await self.find_all(table_name)
            stats[table_name] = len(records)
        
        return {
            'database_path': str(self.db_path),
            'tables': stats,
            'total_records': sum(stats.values())
        }