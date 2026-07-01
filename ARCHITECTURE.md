# RAG Document Assistant - Architecture

## System Architecture Diagram

```
┌─────────────────────────────────────────────────────────────────────┐
│                        Frontend (React)                              │
│                      - Document Upload UI                            │
│                      - Question Input Interface                      │
│                      - Answer Display with Sources                   │
│                      - Chat History Management                       │
└────────────────────────────────────────────────────────────────────┬┘
                              │
                              │ HTTP/REST
                              ▼
┌─────────────────────────────────────────────────────────────────────┐
│                      Backend (FastAPI)                               │
├─────────────────────────────────────────────────────────────────────┤
│  ┌─────────────────────────────────────────────────────────────┐   │
│  │              API Routes                                      │   │
│  │  • POST /documents/upload - Upload & process PDF             │   │
│  │  • GET /documents/info/{id} - Get document info              │   │
│  │  • DELETE /documents/delete/{id} - Delete document           │   │
│  │  • POST /qa/ask - Ask question                               │   │
│  │  • POST /qa/ask-streaming - Stream answer                    │   │
│  │  • GET /chat/history/{id} - Get chat history                 │   │
│  └─────────────────────────────────────────────────────────────┘   │
│                              │                                        │
│                    ┌─────────┴─────────┬──────────────┐              │
│                    ▼                   ▼              ▼              │
│  ┌──────────────────────────┐  ┌───────────────┐  ┌─────────────┐  │
│  │  PDF Processing Service │  │ Embedding     │  │   LLM       │  │
│  │                          │  │   Service     │  │  Service    │  │
│  │ - Extract Text          │  │               │  │             │  │
│  │ - Chunk Documents       │  │ - Generate    │  │ - Generate  │  │
│  │ - Preprocess            │  │   Embeddings  │  │   Answers   │  │
│  │                          │  │ (OpenAI API) │  │ (GPT-3.5)   │  │
│  └──────────────────────────┘  └───────────────┘  └─────────────┘  │
└─────────────────────────────────────────────────────────────────────┘
                              │
                    ┌─────────┴─────────┐
                    ▼                   ▼
        ┌─────────────────────┐  ┌──────────────────┐
        │   ChromaDB Vector   │  │  OpenAI API      │
        │     Database        │  │                  │
        │                     │  │ • Embeddings     │
        │ - Store Vectors     │  │ • GPT-3.5-Turbo  │
        │ - Similarity Search │  │ • Chat API       │
        │ - Metadata Storage  │  │                  │
        └─────────────────────┘  └──────────────────┘
```

---

## Data Flow

### Document Upload Flow

```
1. User Upload
   ├─ PDF File
   └─ Validation (size, type)

2. Text Extraction
   ├─ PDF Parser (PyPDF2)
   └─ Raw Text

3. Document Chunking
   ├─ Split into chunks (1000 chars)
   ├─ Maintain overlap (200 chars)
   └─ Chunk List

4. Embedding Generation
   ├─ Call OpenAI API
   ├─ Text → Vector (384-dim)
   └─ Embedding Vector List

5. Storage in ChromaDB
   ├─ Create Collection (document_id)
   ├─ Store chunks + embeddings + metadata
   └─ Ready for queries
```

### Question Answering Flow

```
1. User Question
   └─ "What is mentioned about AI?"

2. Question Embedding
   ├─ OpenAI API call
   └─ Question Vector

3. Vector Similarity Search
   ├─ ChromaDB query
   ├─ Cosine similarity
   └─ Top-5 relevant chunks

4. Context Assembly
   ├─ Combine retrieved chunks
   ├─ Add relevance scores
   └─ Formatted Context

5. LLM Processing
   ├─ System prompt + Context + Question
   ├─ GPT-3.5-Turbo call
   └─ Generated Answer

6. Response
   ├─ Answer text
   ├─ Source chunks
   ├─ Confidence scores
   └─ Return to user
```

---

## Component Details

### 1. Frontend (React + TypeScript)

**Responsibilities:**
- Document upload interface
- Question input and submission
- Answer and sources display
- Chat history management
- Real-time feedback

**Key Features:**
- Modern, responsive UI
- Loading states and error handling
- Confidence indicators
- Source references with relevance scores
- Multi-document support

---

### 2. Backend (FastAPI)

**Structure:**
```
backend/
├── main.py                 # Entry point
├── requirements.txt        # Dependencies
├── .env                    # Configuration
└── app/
    ├── api/
    │   ├── documents.py   # Document endpoints
    │   ├── qa.py          # Question-answering endpoints
    │   └── chat.py        # Chat endpoints
    ├── services/
    │   ├── pdf_processor.py      # PDF text extraction
    │   ├── document_chunker.py   # Text chunking
    │   ├── embedding_service.py  # Vector generation
    │   ├── chroma_service.py     # ChromaDB integration
    │   └── llm_service.py        # LLM interactions
    ├── models/
    │   └── schemas.py      # Pydantic models
    └── core/
        └── config.py       # Configuration
```

---

### 3. Vector Database (ChromaDB)

**Features:**
- **Persistent Storage**: Data saved to disk
- **Fast Similarity Search**: Efficient vector queries
- **Metadata Support**: Store document references
- **Collection-based**: Organize by document
- **Cosine Similarity**: Default distance metric

**Schema:**
```
Collection (per document):
├── Document chunks (text)
├── Embedding vectors (384-dim)
├── Chunk IDs
└── Metadata
    ├── document_id
    ├── filename
    ├── chunk_index
    └── upload_date
```

---

### 4. External APIs

**OpenAI API**
- **text-embedding-3-small**: Generate embeddings
  - Input: Text up to 8192 tokens
  - Output: 384-dimensional vector
  - Cost: ~$0.02 per 1M tokens

- **gpt-3.5-turbo**: Generate answers
  - Input: Context + Question
  - Output: Natural language answer
  - Temperature: 0.7 (balanced creativity)
  - Max tokens: 2000

---

## Data Storage

### ChromaDB Collections

```
document_id_1/
├── doc_1_chunk_0 → embedding vector + text + metadata
├── doc_1_chunk_1 → embedding vector + text + metadata
└── ...

document_id_2/
├── doc_2_chunk_0 → embedding vector + text + metadata
└── ...
```

### Upload Directory
```
uploads/
├── doc_1.pdf (optional - can be deleted after processing)
├── doc_2.pdf
└── ...
```

---

## Scalability Considerations

### Current Implementation
- **Single-instance backend**
- **Local ChromaDB** (file-based)
- **Synchronous operations**
- **No caching**

### Production Enhancements

1. **Distributed Backend**
   - Multiple FastAPI instances
   - Load balancer (Nginx)
   - Health checks

2. **Database Scaling**
   - ChromaDB server mode (distributed)
   - Sharding by document_id
   - Replication for redundancy

3. **Caching**
   - Redis cache for embeddings
   - LRU cache for frequently asked questions
   - TTL-based cache invalidation

4. **Async Processing**
   - Celery for long-running tasks
   - Queue for document processing
   - WebSocket for real-time updates

5. **Monitoring & Logging**
   - ELK stack for centralized logging
   - Prometheus for metrics
   - Alerting for failures

---

## Security Architecture

```
┌─────────────────────────────────────┐
│    Authentication (JWT)             │
│    • Token validation                │
│    • User identification             │
└─────────────────────────────────────┘
         ▼
┌─────────────────────────────────────┐
│    Authorization (RBAC)             │
│    • Check document ownership        │
│    • Role-based access control       │
└─────────────────────────────────────┘
         ▼
┌─────────────────────────────────────┐
│    Input Validation                 │
│    • File type validation            │
│    • Size limits                     │
│    • Sanitization                    │
└─────────────────────────────────────┘
         ▼
┌─────────────────────────────────────┐
│    API Rate Limiting                │
│    • Per-user limits                 │
│    • IP-based throttling             │
└─────────────────────────────────────┘
         ▼
┌─────────────────────────────────────┐
│    Data Encryption                  │
│    • TLS/HTTPS                       │
│    • Database encryption             │
│    • API key rotation                │
└─────────────────────────────────────┘
```

---

## Performance Metrics

### Expected Performance

| Operation | Time | Notes |
|-----------|------|-------|
| PDF Upload (10MB) | 2-5s | Includes extraction + chunking |
| Embedding Generation | 1-2s | ~100 chunks per API call |
| Vector Similarity Search | 50-100ms | O(log n) complexity |
| LLM Answer Generation | 2-5s | Streaming preferred for UX |
| Total Q&A Response | 4-8s | End-to-end latency |

### Throughput

- **Concurrent Users**: 100+ (with load balancer)
- **Documents Supported**: Thousands
- **Chunks per Document**: ~50-100 (varies by PDF)
- **Daily API Calls**: Limited by OpenAI rate limits

---

## Deployment Architecture

```
Docker Compose (Development)
├── Backend Container (FastAPI)
├── Frontend Container (React)
├── ChromaDB Service
└── Volumes for persistence

Kubernetes (Production)
├── Backend Deployment (HPA)
├── Frontend Deployment
├── ChromaDB StatefulSet
├── Ingress (API Gateway)
├── Secrets (API keys)
└── Persistent Volumes
```

---

## Error Handling & Recovery

```
Error Detection
    ▼
Log Error (Structured)
    ▼
Categorize Severity
    ├─ CRITICAL: Alert immediately
    ├─ ERROR: Log and retry
    ├─ WARNING: Log and continue
    └─ INFO: Log only
    ▼
Recovery Action
    ├─ Retry (exponential backoff)
    ├─ Fallback (cached response)
    └─ User Notification
    ▼
Status Return
```

---

## Monitoring & Observability

**Metrics Collected:**
- API response times
- Error rates
- Document processing time
- ChromaDB query latency
- OpenAI API usage
- User activity

**Logging:**
- Structured JSON logs
- Centralized log aggregation
- Full request tracing
- Query execution time

**Alerting:**
- Service downtime
- High error rates
- Slow response times
- API quota warnings
