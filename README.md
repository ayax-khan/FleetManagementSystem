# Fleet Management System - New Architecture

## 🏗️ Architecture Overview

```
📱 Flutter App (Frontend)
🐍 Python FastAPI Backend  
    ↓ (Excel Processing + Business Logic)
📊 Pandas/OpenPyXL (Excel Handling)
    ↓ (Data Validation & Transformation)
🗃️ Hive Database (Local Storage)
```

This implementation follows your requested architecture with:
- **Flutter** for cross-platform frontend
- **Python FastAPI** for robust backend APIs
- **Pandas/OpenPyXL** for powerful Excel processing
- **Hive-style JSON storage** for local database

## 🚀 Quick Start

### 1. Start the Backend
```batch
# Double-click to run
start_backend.bat
```
Or manually:
```bash
cd backend
python -m venv venv
venv\Scripts\activate
pip install -r requirements.txt
python main.py
```

The backend will start on **http://localhost:8000**
- API Documentation: http://localhost:8000/docs
- Health Check: http://localhost:8000/api/health

### 2. Start the Frontend
```batch
# Double-click to run (in a separate terminal)
start_frontend.bat
```
Or manually:
```bash
flutter pub get
flutter run -d windows
```

## 📁 Project Structure

```
FleetManagementSystem/
├── backend/                     # Python FastAPI Backend
│   ├── app/
│   │   ├── core/
│   │   │   └── config.py        # Configuration & settings
│   │   ├── database/
│   │   │   └── hive_manager.py  # Hive-style JSON database
│   │   ├── models/
│   │   │   └── schemas.py       # Pydantic models
│   │   ├── routes/
│   │   │   ├── vehicles.py      # Vehicle CRUD APIs
│   │   │   ├── drivers.py       # Driver CRUD APIs
│   │   │   ├── trips.py         # Trip management APIs
│   │   │   ├── fuel.py          # Fuel entry APIs
│   │   │   ├── maintenance.py   # Maintenance APIs
│   │   │   └── excel_import.py  # Excel processing APIs
│   │   └── services/
│   │       └── excel_service.py # Pandas/OpenPyXL service
│   ├── main.py                  # FastAPI application
│   └── requirements.txt         # Python dependencies
├── lib/                         # Flutter Frontend
│   ├── services/
│   │   └── api_service.dart     # HTTP client for backend
│   ├── main.dart                # Flutter entry point
│   └── app.dart                 # Main app widget
├── pubspec.yaml                 # Flutter dependencies (cleaned)
├── start_backend.bat            # Backend startup script
└── start_frontend.bat           # Frontend startup script
```

## 🗃️ Database Storage

Following your rule, the Hive database is stored at:
```
C:\Users\{USERNAME}\Documents\fleetManagementSystem\
```

Database files:
- `vehicles.json`
- `drivers.json`
- `trips.json`
- `fuel_entries.json`
- `maintenance.json`
- And more...

## 🔧 Key Features

### Backend (FastAPI)
- ✅ RESTful APIs for all entities
- ✅ Automatic API documentation (Swagger)
- ✅ Data validation with Pydantic
- ✅ Excel import/export with Pandas
- ✅ File-based JSON database (Hive-style)
- ✅ CORS enabled for Flutter communication
- ✅ Comprehensive error handling

### Frontend (Flutter)
- ✅ Modern Material 3 UI
- ✅ Riverpod state management
- ✅ HTTP client (Dio) with interceptors
- ✅ Cross-platform compatibility
- ✅ Clean architecture separation
- ✅ Minimal dependencies

### Excel Processing
- ✅ Smart sheet detection
- ✅ Automatic field mapping
- ✅ Data validation & transformation
- ✅ Batch import/export
- ✅ Error reporting

## 📊 API Endpoints

### Core Entities
- `GET/POST/PUT/DELETE /api/v1/vehicles/`
- `GET/POST/PUT/DELETE /api/v1/drivers/`
- `GET/POST/PUT/DELETE /api/v1/trips/`
- `GET/POST /api/v1/fuel/`
- `GET/POST /api/v1/maintenance/`

### Excel Operations
- `POST /api/v1/excel/analyze` - Analyze Excel file structure
- `POST /api/v1/excel/import` - Import Excel data
- `GET /api/v1/excel/export` - Export data to Excel
- `GET /api/v1/excel/database/stats` - Database statistics

### Utilities
- `GET /api/health` - Health check
- `POST /api/v1/excel/database/clear/{table}` - Clear table data

## 💻 Development

### Backend Development
```bash
cd backend
pip install -r requirements.txt
uvicorn main:app --reload --port 8000
```

### Frontend Development
```bash
flutter pub get
flutter run -d windows
```

### Testing APIs
Visit http://localhost:8000/docs for interactive API documentation.

## ⚡ Benefits of This Architecture

1. **Separation of Concerns**: Clear separation between UI, business logic, and data
2. **Excel Powerhouse**: Pandas provides industrial-strength Excel processing
3. **Local Storage**: No need for external database servers
4. **API-Driven**: RESTful APIs make the backend reusable
5. **Cross-Platform**: Flutter works on desktop, mobile, and web
6. **Type Safety**: Pydantic ensures data validation
7. **Documentation**: Auto-generated API docs
8. **Minimal Setup**: Few dependencies, easy to deploy

## 🔧 Configuration

### Backend Configuration
Edit `backend/app/core/config.py`:
```python
class Settings:
    DEBUG: bool = True
    PORT: int = 8000
    HIVE_DB_PATH: str = "C:\\Users\\{username}\\Documents\\fleetManagementSystem"
```

### Frontend Configuration
Edit `lib/services/api_service.dart`:
```dart
static const String _baseUrl = 'http://localhost:8000/api/v1';
```

## 🎯 Next Steps

The architecture is fully implemented and ready to use. You can now:

1. **Run the backend** with `start_backend.bat`
2. **Run the frontend** with `start_frontend.bat`
3. **Import Excel data** using the Excel Import tab
4. **Manage vehicles, drivers, trips** through the API
5. **View data** in the Hive database files

The system follows your requested architecture exactly and provides a solid foundation for fleet management operations!

## 🆘 Troubleshooting

### Backend Issues
- **Port 8000 in use**: Change port in `config.py`
- **Python not found**: Install Python 3.8+
- **Dependencies fail**: Try `pip install --upgrade pip`

### Frontend Issues
- **Flutter not found**: Install Flutter SDK
- **Dependency conflicts**: Run `flutter clean && flutter pub get`
- **Backend not responding**: Ensure backend is running on localhost:8000

### Database Issues
- **Permission denied**: Check Windows folder permissions
- **Data not saving**: Check the Hive directory path in config