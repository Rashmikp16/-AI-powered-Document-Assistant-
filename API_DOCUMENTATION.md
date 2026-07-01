# RAG Document Assistant - API Documentation

## Overview

The RAG Document Assistant is an AI-powered application that allows users to upload PDF documents and ask questions about their content. It leverages:

- **LLMs**: GPT-3.5-Turbo for question answering
- **Embeddings**: OpenAI's text-embedding-3-small for semantic search
- **Vector Database**: ChromaDB for efficient similarity search
- **Backend**: FastAPI for RESTful APIs
- **Frontend**: React with TypeScript for user interface

## Base URL

```
http://localhost:8000/api
```

## Authentication

Currently, the API is open for development. For production, implement JWT-based authentication.

---

## Endpoints

### 1. Document Upload

**Endpoint:** `POST /documents/upload`

**Description:** Upload a PDF document for processing

**Request:**
- Method: `POST`
- Content-Type: `multipart/form-data`
- Body:
  - `file`: PDF file (required)

**Response:**
```json
{
  "document_id": "doc_12345abc",
  "filename": "sample.pdf",
  "status": "success",
  "chunks_created": 25,
  "message": "Document processed successfully. Created 25 chunks."
}
```

**Status Codes:**
- `200`: Success
- `400`: Invalid file type or no text extracted
- `500`: Server error

**Example:**
```bash
curl -X POST "http://localhost:8000/api/documents/upload" \
  -F "file=@sample.pdf"
```

---

### 2. Get Document Information

**Endpoint:** `GET /documents/info/{document_id}`

**Description:** Get information about an uploaded document

**Parameters:**
- `document_id` (path): The document ID returned from upload

**Response:**
```json
{
  "document_id": "doc_12345abc",
  "filename": "sample.pdf",
  "upload_date": "2024-01-15T10:30:00",
  "chunk_count": 25,
  "size_bytes": 2048000
}
```

**Example:**
```bash
curl "http://localhost:8000/api/documents/info/doc_12345abc"
```

---

### 3. Delete Document

**Endpoint:** `DELETE /documents/delete/{document_id}`

**Description:** Delete a document and its embeddings from the system

**Parameters:**
- `document_id` (path): The document ID to delete

**Response:**
```json
{
  "message": "Document doc_12345abc deleted successfully"
}
```

**Example:**
```bash
curl -X DELETE "http://localhost:8000/api/documents/delete/doc_12345abc"
```

---

### 4. Ask Question

**Endpoint:** `POST /qa/ask`

**Description:** Ask a question about a document

**Request Body:**
```json
{
  "document_id": "doc_12345abc",
  "question": "What is the main topic of this document?",
  "use_streaming": false
}
```

**Response:**
```json
{
  "answer": "The document discusses artificial intelligence and machine learning applications...",
  "sources": [
    {
      "chunk_index": 0,
      "content": "Artificial intelligence (AI) is the simulation of human intelligence...",
      "confidence": 0.95
    },
    {
      "chunk_index": 1,
      "content": "Machine learning is a subset of AI that enables systems...",
      "confidence": 0.87
    }
  ],
  "confidence": 0.91
}
```

**Parameters:**
- `document_id` (string): The document ID
- `question` (string): The question to ask
- `use_streaming` (boolean): Whether to use streaming response

**Status Codes:**
- `200`: Success
- `400`: Invalid request
- `404`: Document not found
- `500`: Server error

**Example:**
```bash
curl -X POST "http://localhost:8000/api/qa/ask" \
  -H "Content-Type: application/json" \
  -d '{
    "document_id": "doc_12345abc",
    "question": "What is mentioned about AI in the document?"
  }'
```

---

### 5. Ask Question with Streaming

**Endpoint:** `POST /qa/ask-streaming`

**Description:** Ask a question with streaming response (for real-time updates)

**Request Body:**
```json
{
  "document_id": "doc_12345abc",
  "question": "Explain the key concepts",
  "use_streaming": true
}
```

**Response:** Server-Sent Events (SSE) stream
```
data: The\n\n
data: document\n\n
data: explains\n\n
...
```

**Example:**
```bash
curl -X POST "http://localhost:8000/api/qa/ask-streaming" \
  -H "Content-Type: application/json" \
  -d '{
    "document_id": "doc_12345abc",
    "question": "What are the main topics?"
  }'
```

---

### 6. Chat History

**Endpoint:** `GET /chat/history/{document_id}`

**Description:** Get chat history for a document

**Response:**
```json
{
  "document_id": "doc_12345abc",
  "messages": [
    {
      "role": "user",
      "content": "What is AI?",
      "timestamp": "2024-01-15T10:35:00"
    },
    {
      "role": "assistant",
      "content": "AI is artificial intelligence...",
      "timestamp": "2024-01-15T10:35:05"
    }
  ]
}
```

---

### 7. Clear Chat History

**Endpoint:** `POST /chat/clear/{document_id}`

**Description:** Clear chat history for a document

**Response:**
```json
{
  "message": "Chat history cleared for document doc_12345abc"
}
```

---

## Health Check

**Endpoint:** `GET /health`

**Description:** Check API health status

**Response:**
```json
{
  "status": "healthy"
}
```

---

## Error Handling

All errors follow this format:

```json
{
  "detail": "Error message describing the issue"
}
```

**Common Error Codes:**
- `400`: Bad Request - Invalid input
- `404`: Not Found - Document doesn't exist
- `500`: Internal Server Error - Server-side issue
- `429`: Too Many Requests - Rate limit exceeded
- `503`: Service Unavailable - API temporarily down

---

## Rate Limiting

- **File Upload**: 1 request per 5 seconds per IP
- **Question Asking**: 10 requests per minute per IP
- **General Requests**: 100 requests per minute per IP

---

## CORS

The API accepts requests from:
- `http://localhost:3000`
- `http://localhost:8000`
- `http://127.0.0.1:3000`
- `http://127.0.0.1:8000`

Add additional origins in `backend/app/core/config.py`

---

## Example Workflow

```bash
# 1. Upload a document
RESPONSE=$(curl -X POST "http://localhost:8000/api/documents/upload" \
  -F "file=@document.pdf")
DOC_ID=$(echo $RESPONSE | grep -o '"document_id":"[^"]*' | cut -d'"' -f4)

# 2. Get document info
curl "http://localhost:8000/api/documents/info/$DOC_ID"

# 3. Ask a question
curl -X POST "http://localhost:8000/api/qa/ask" \
  -H "Content-Type: application/json" \
  -d "{
    \"document_id\": \"$DOC_ID\",
    \"question\": \"What is the main topic?\"
  }"

# 4. Get chat history
curl "http://localhost:8000/api/chat/history/$DOC_ID"

# 5. Delete document
curl -X DELETE "http://localhost:8000/api/documents/delete/$DOC_ID"
```

---

## Frequently Asked Questions

**Q: What's the maximum file size?**
A: 50MB by default. Configure in `backend/app/core/config.py`

**Q: How long are embeddings cached?**
A: ChromaDB stores embeddings persistently. They're not expired.

**Q: Can I upload multiple documents?**
A: Yes, each gets a unique `document_id` and separate collection in ChromaDB.

**Q: Is my data encrypted?**
A: Add encryption in production using database-level encryption.

**Q: Can I use a different LLM?**
A: Yes, modify `EmbeddingService` and `LLMService` in `backend/app/services/`

---

## Support

For issues or questions, please refer to the GitHub repository or contact the development team.
