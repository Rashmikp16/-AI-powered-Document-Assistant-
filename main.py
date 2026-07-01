from fastapi import FastAPI
from fastapi import Request
from fastapi.middleware.cors import CORSMiddleware
from starlette.responses import JSONResponse
from app.core.config import get_settings
from app.api import documents, qa, chat
import os
import asyncio

# Initialize settings
settings = get_settings()

# Create FastAPI app
app = FastAPI(
    title=settings.API_TITLE,
    version=settings.API_VERSION,
    description=settings.API_DESCRIPTION,
    docs_url="/api/docs",
    openapi_url="/api/openapi.json"
)

# Add CORS middleware
app.add_middleware(
    CORSMiddleware,
    allow_origins=settings.ALLOWED_ORIGINS,
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)


@app.middleware("http")
async def request_timeout_middleware(request: Request, call_next):
    """Abort long-running requests so clients don't hang indefinitely."""
    try:
        return await asyncio.wait_for(call_next(request), timeout=45)
    except asyncio.TimeoutError:
        return JSONResponse(
            status_code=504,
            content={"detail": "Request timed out. Please try again."},
        )

# Create upload directory if it doesn't exist
os.makedirs(settings.UPLOAD_DIR, exist_ok=True)
os.makedirs(settings.CHROMA_DB_PATH, exist_ok=True)

# Include routers
app.include_router(documents.router)
app.include_router(qa.router)
app.include_router(chat.router)

@app.get("/")
async def root():
    """Root endpoint"""
    return {
        "message": "RAG Document Assistant API",
        "version": settings.API_VERSION,
        "docs": "/api/docs",
        "health": "/health"
    }

@app.get("/health")
async def health():
    """Health check endpoint"""
    return {"status": "healthy"}

if __name__ == "__main__":
    import uvicorn
    uvicorn.run(app, host="0.0.0.0", port=8000, reload=True)
