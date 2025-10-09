@echo off
echo 🚀 Starting Fleet Management System Backend...
echo.
cd /d "%~dp0\backend"

REM Check if virtual environment exists
if not exist "venv" (
    echo Creating virtual environment...
    python -m venv venv
)

REM Activate virtual environment
call venv\Scripts\activate.bat

REM Install requirements
echo Installing requirements...
pip install -r requirements.txt

REM Run the FastAPI application
echo.
echo ✅ Starting FastAPI server on http://localhost:8000
echo 📖 API documentation available at http://localhost:8000/docs
echo.
python main.py

pause