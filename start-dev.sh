#!/bin/bash
# RAG Document Assistant - Development Server Script

echo "🚀 Starting RAG Document Assistant..."
echo ""

# Check if Python is installed
if ! command -v python &> /dev/null; then
    echo "❌ Python 3.11+ is not installed"
    exit 1
fi

# Check if Node.js is installed
if ! command -v node &> /dev/null; then
    echo "❌ Node.js 18+ is not installed"
    exit 1
fi

# Start backend
echo "📦 Starting Backend (FastAPI)..."
cd backend

# Activate virtual environment if it exists
if [ -d "venv" ]; then
    source venv/bin/activate
else
    echo "⚠️  Virtual environment not found. Creating one..."
    python -m venv venv
    source venv/bin/activate
    pip install -r requirements.txt
fi

# Start backend in background
uvicorn main:app --reload --host 0.0.0.0 --port 8000 &
BACKEND_PID=$!
echo "✅ Backend running on http://localhost:8000 (PID: $BACKEND_PID)"

# Start frontend
echo ""
echo "🎨 Starting Frontend (React)..."
cd ../frontend

if [ ! -d "node_modules" ]; then
    echo "⚠️  Dependencies not installed. Installing..."
    npm install
fi

npm run dev &
FRONTEND_PID=$!
echo "✅ Frontend running on http://localhost:3000 (PID: $FRONTEND_PID)"

echo ""
echo "======================================="
echo "✨ RAG Document Assistant is Ready!"
echo "======================================="
echo ""
echo "📱 Frontend:     http://localhost:3000"
echo "⚙️  Backend:      http://localhost:8000"
echo "📚 API Docs:     http://localhost:8000/api/docs"
echo ""
echo "Press Ctrl+C to stop both services"
echo ""

# Handle Ctrl+C
trap "kill $BACKEND_PID $FRONTEND_PID" INT

# Wait for both processes
wait $BACKEND_PID $FRONTEND_PID
