# RAG Document Assistant - Testing Guide

## Manual Testing Checklist

### 1. Backend API Tests

#### Health Check
```bash
curl http://localhost:8000/health
# Expected: {"status": "healthy"}
```

#### Get API Info
```bash
curl http://localhost:8000/
# Expected: API information and documentation links
```

#### API Documentation
Open in browser: http://localhost:8000/api/docs

### 2. Document Upload Tests

#### Upload Valid PDF
```bash
curl -X POST "http://localhost:8000/api/documents/upload" \
  -F "file=@sample.pdf"
# Expected: document_id, filename, status, chunks_created
```

#### Upload Invalid File Type
```bash
curl -X POST "http://localhost:8000/api/documents/upload" \
  -F "file=@sample.txt"
# Expected: Error - Only PDF files are allowed
```

#### Get Document Info
```bash
curl "http://localhost:8000/api/documents/info/{document_id}"
# Expected: document info with chunk count
```

### 3. Question Answering Tests

#### Ask Question
```bash
curl -X POST "http://localhost:8000/api/qa/ask" \
  -H "Content-Type: application/json" \
  -d '{
    "document_id": "{doc_id}",
    "question": "What is the main topic?",
    "use_streaming": false
  }'
# Expected: Answer with sources and confidence score
```

#### Ask with Streaming
```bash
curl -X POST "http://localhost:8000/api/qa/ask-streaming" \
  -H "Content-Type: application/json" \
  -d '{
    "document_id": "{doc_id}",
    "question": "Summarize the document"
  }'
# Expected: Streaming response with data chunks
```

### 4. Frontend Tests

#### Upload Flow
1. Go to http://localhost:3000
2. Click "Upload PDF"
3. Select a PDF file
4. Verify upload success message
5. Verify Document ID appears

#### Question Flow
1. Upload a document (complete)
2. Type a question
3. Click "Ask Question"
4. Wait for response
5. Verify answer appears
6. Verify sources are displayed
7. Verify confidence score

#### Error Handling
1. Try uploading without file (should show error)
2. Try asking question without document (should show error)
3. Try asking empty question (should show error)

### 5. Performance Tests

#### Response Time Test
```bash
# Measure upload time
time curl -X POST "http://localhost:8000/api/documents/upload" \
  -F "file=@large.pdf"

# Measure Q&A time
time curl -X POST "http://localhost:8000/api/qa/ask" \
  -H "Content-Type: application/json" \
  -d '{...}'
```

#### Concurrent Load Test
```bash
# Use Apache Bench (if installed)
ab -n 100 -c 10 http://localhost:8000/health

# Or use curl in a loop
for i in {1..10}; do
  curl http://localhost:8000/health &
done
```

### 6. Integration Tests

#### Complete Workflow
```bash
# 1. Upload document
RESPONSE=$(curl -s -X POST "http://localhost:8000/api/documents/upload" \
  -F "file=@sample.pdf")
DOC_ID=$(echo $RESPONSE | grep -o '"document_id":"[^"]*' | cut -d'"' -f4)

# 2. Get document info
curl -s "http://localhost:8000/api/documents/info/$DOC_ID"

# 3. Ask question
curl -s -X POST "http://localhost:8000/api/qa/ask" \
  -H "Content-Type: application/json" \
  -d "{\"document_id\": \"$DOC_ID\", \"question\": \"What is this document about?\"}"

# 4. Get chat history
curl -s "http://localhost:8000/api/chat/history/$DOC_ID"

# 5. Delete document
curl -s -X DELETE "http://localhost:8000/api/documents/delete/$DOC_ID"
```

## Test Data

### Sample PDF
Create a test PDF with:
- Title page
- Introduction (200 words)
- Main content (500 words)
- Conclusion (150 words)

### Sample Questions
- What is the main topic?
- Summarize the document
- What are the key points?
- Explain the methodology
- What conclusions are drawn?

## Expected Results

### Success Criteria
- ✅ All API endpoints respond in <5s
- ✅ PDF upload completes successfully
- ✅ Document chunks are created (typically 10-50 per PDF)
- ✅ Questions are answered with sources
- ✅ Confidence scores are between 0-1
- ✅ Frontend UI responds smoothly
- ✅ No 5xx errors in logs

### Performance Targets
| Operation | Target | Acceptable |
|-----------|--------|-----------|
| Health Check | <100ms | <500ms |
| PDF Upload | <3s | <10s |
| Q&A Response | <4s | <8s |
| Search Query | <100ms | <500ms |

## Debugging

### View Backend Logs
```bash
# If running locally
# Check terminal where uvicorn is running

# If using Docker
docker-compose logs -f backend
```

### View Frontend Logs
```bash
# Press F12 in browser
# Check browser console for errors
```

### Database Inspection
```bash
# Check ChromaDB collections
python -c "
import chromadb
client = chromadb.PersistentClient(path='./chroma_db')
collections = client.list_collections()
print('Collections:', collections)
for col in collections:
    print(f'{col.name}: {col.count()} items')
"
```

## Test Automation (Future)

```python
# tests/test_api.py (example structure)
import pytest
from fastapi.testclient import TestClient
from main import app

client = TestClient(app)

def test_health():
    response = client.get("/health")
    assert response.status_code == 200

def test_upload_pdf():
    with open("test.pdf", "rb") as f:
        response = client.post("/documents/upload", files={"file": f})
    assert response.status_code == 200
    assert "document_id" in response.json()

def test_ask_question():
    # First upload
    # Then ask question
    # Assert answer contains relevant text
    pass
```

## Troubleshooting Common Issues

### No Response from API
- Check if backend is running: `curl http://localhost:8000/health`
- Check if port 8000 is in use: `netstat -an | grep 8000`
- Check backend logs for errors

### PDF Upload Fails
- Verify PDF is valid (open in PDF reader)
- Check file size < 50MB
- Check UPLOAD_DIR exists
- Check disk space available

### Question Answering Returns Empty Answer
- Verify document uploaded successfully
- Verify chunks were created (check in API response)
- Verify OpenAI API key is valid
- Check for API rate limiting

### Slow Responses
- This is normal with API calls (2-5s expected)
- Check network connection
- Verify OpenAI API is responsive
- Consider implementing caching

---

**Last Updated**: 2024-01-15
