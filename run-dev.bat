@echo off
REM RAG Document Assistant - Development Server Script
REM This script starts both frontend and backend services

echo Starting RAG Document Assistant...
echo.

REM Check if .env file has OpenAI API key
if not exist "backend\.env" (
    echo [ERROR] backend\.env file not found!
    echo Please copy backend\.env.example to backend\.env and add your OpenAI API key
    pause
    exit /b 1
)

REM Start backend in new window
echo Starting Backend (FastAPI) on port 8000...
cd backend
start cmd /k "python main.py"
echo Backend started in new window
echo.

REM Wait a moment for backend to start
timeout /t 2

REM Start frontend in new window
echo Starting Frontend (React) on port 3000...
cd ..\frontend
start cmd /k "npm run dev"
echo Frontend started in new window
echo.

echo ======================================
echo RAG Document Assistant is Starting!
echo ======================================
echo.
echo Frontend:  http://localhost:3000
echo API:       http://localhost:8000/api
echo API Docs:  http://localhost:8000/api/docs
echo.
echo Both services are starting in separate windows.
echo Press Ctrl+C in each window to stop the services.
echo.
pause
