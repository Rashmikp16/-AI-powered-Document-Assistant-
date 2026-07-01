# RAG Document Assistant - Setup Guide

## Prerequisites Checklist

Before you start, ensure you have:

- [ ] Python 3.11 or higher installed
- [ ] Node.js 18 or higher installed  
- [ ] OpenAI API key (from https://platform.openai.com/api-keys)
- [ ] Git installed
- [ ] Docker and Docker Compose (optional, for containerized setup)
- [ ] 2GB free disk space minimum

## Step 1: Verify Prerequisites

### Check Python Version
```bash
python --version
# Should output: Python 3.11.x or higher
```

### Check Node Version
```bash
node --version
npm --version
# Should output: v18.x or higher
```

### Verify OpenAI API Key
Get your API key from: https://platform.openai.com/api-keys

## Step 2: Clone & Setup Backend

### Navigate to Backend
```bash
cd backend
```

### Create Virtual Environment
```bash
# On Windows
python -m venv venv
venv\Scripts\activate

# On macOS/Linux
python3 -m venv venv
source venv/bin/activate
```

### Install Dependencies
```bash
pip install -r requirements.txt
```

### Configure Environment
```bash
# Edit .env file and add your OpenAI API key
# Open the .env file with your editor and replace:
# OPENAI_API_KEY=your_openai_api_key_here

# Example:
# OPENAI_API_KEY=sk-xxxxxxxxxxxxxxxxxxxxx
```

## Step 3: Start Backend

```bash
# Ensure you're in the backend directory with venv activated
uvicorn main:app --reload --host 0.0.0.0 --port 8000
```

You should see:
```
Uvicorn running on http://0.0.0.0:8000
```

✅ **Backend is running!**

### Test Backend Health
In a new terminal:
```bash
curl http://localhost:8000/health
# Should return: {"status": "healthy"}
```

## Step 4: Setup Frontend

### Open New Terminal
```bash
cd frontend
npm install
```

### Start Frontend
```bash
npm run dev
```

You should see:
```
  ➜  Local:   http://localhost:5173/
```

✅ **Frontend is running!**

## Step 5: Access Application

Open your browser and navigate to:
- **Main App**: http://localhost:3000 (or http://localhost:5173 if using Vite)
- **API Documentation**: http://localhost:8000/api/docs
- **API OpenAPI JSON**: http://localhost:8000/api/openapi.json

## Step 6: Test the Application

### Via Web Interface
1. Go to http://localhost:3000
2. Click "Upload PDF" and select a PDF file
3. Wait for the upload to complete
4. Enter a question in the text area
5. Click "Ask Question"
6. View the answer and sources

### Via API (cURL)

#### Upload a Document
```bash
curl -X POST "http://localhost:8000/api/documents/upload" \
  -F "file=@path/to/sample.pdf"
```

#### Ask a Question
```bash
curl -X POST "http://localhost:8000/api/qa/ask" \
  -H "Content-Type: application/json" \
  -d '{
    "document_id": "doc_XXXXX",
    "question": "What is the main topic?"
  }'
```

## Common Issues & Solutions

### Issue: "No module named 'openai'"
**Solution**: 
```bash
# Ensure venv is activated
pip install openai
```

### Issue: "Connection refused" for backend
**Solution**:
- Ensure backend is running on port 8000
- Check if port 8000 is already in use: `netstat -an | grep 8000`
- Try a different port: `uvicorn main:app --port 8001`

### Issue: "Cannot find module 'axios'"
**Solution**:
```bash
cd frontend
npm install
```

### Issue: "OPENAI_API_KEY not found"
**Solution**:
1. Check your `.env` file exists in the backend directory
2. Verify the file contains: `OPENAI_API_KEY=your_key`
3. Ensure the key is valid (test on OpenAI website)

### Issue: PDF upload fails
**Solution**:
- Check file is a valid PDF
- Ensure file size is less than 50MB
- Check backend logs for error details

### Issue: Slow responses
**Solution**:
- OpenAI API may be slow (2-5s is normal)
- Check your internet connection
- Verify OpenAI API is not rate limiting

## Docker Setup (Alternative)

### Using Docker Compose (Recommended)

```bash
# Build and start all services
docker-compose up -d

# Wait 10-15 seconds for services to start

# Access the application
# Frontend: http://localhost:3000
# Backend API: http://localhost:8000
# API Docs: http://localhost:8000/api/docs
```

### Stop Services
```bash
docker-compose down
```

### View Logs
```bash
docker-compose logs -f backend  # Backend logs
docker-compose logs -f frontend # Frontend logs
```

## Production Deployment

See [ARCHITECTURE.md](ARCHITECTURE.md) for production deployment guidelines.

## Getting Help

1. Check the [API_DOCUMENTATION.md](API_DOCUMENTATION.md) for API details
2. Review [ARCHITECTURE.md](ARCHITECTURE.md) for system design
3. Check backend logs: `docker-compose logs backend`
4. Check frontend console: Press F12 in browser

## Next Steps

1. ✅ Test with your own PDF documents
2. ✅ Explore the API documentation at `/api/docs`
3. ✅ Review the source code architecture
4. ✅ Experiment with different chunk sizes and models
5. ✅ Implement additional features (authentication, caching, etc.)

---

**You're all set! 🎉 Start uploading documents and asking questions!**
