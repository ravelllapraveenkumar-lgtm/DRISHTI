import logging
from contextlib import asynccontextmanager
from fastapi import FastAPI, Request, status
from fastapi.middleware.cors import CORSMiddleware
from fastapi.responses import JSONResponse
from fastapi.exceptions import RequestValidationError
from starlette.exceptions import HTTPException as StarletteHTTPException

from backend.app.config import settings
from backend.app.database import engine, Base, SessionLocal
from backend.app.seed import seed_database_if_empty
from backend.app.api.v1 import api_v1_router
from backend.app.api.v1.health import router as root_health_router

# Configure logging
logging.basicConfig(
    level=getattr(logging, settings.LOG_LEVEL.upper(), logging.INFO),
    format="%(asctime)s - %(name)s - %(levelname)s - %(message)s"
)
logger = logging.getLogger("drishti.backend")

@asynccontextmanager
async def lifespan(app: FastAPI):
    """Initializes tables and seeds initial demo data on startup."""
    logger.info("Initializing DRISHTI backend application...")
    try:
        # Create database tables if they do not exist
        Base.metadata.create_all(bind=engine)
        logger.info("Database schema validated successfully.")

        # Run seeder to ensure initial demonstration data is present
        with SessionLocal() as db:
            seed_database_if_empty(db)
        logger.info("Database demonstration seeding check completed.")
    except Exception as e:
        logger.error("Database startup sequence error: %s", str(e), exc_info=True)

    yield
    logger.info("Shutting down DRISHTI backend application...")

app = FastAPI(
    title=settings.PROJECT_NAME,
    description="DRISHTI: Digital Real-Time Inspection & Scheme Holistic Tracking Infrastructure. "
                "National monitoring and unannounced inspection dispatch platform for MoSJE schemes "
                "(DDRS, AVYAY, NAPDDR, PM-DAKSH).",
    version=settings.VERSION,
    openapi_url=f"{settings.API_V1_STR}/openapi.json",
    docs_url=f"{settings.API_V1_STR}/docs",
    redoc_url=f"{settings.API_V1_STR}/redoc",
    lifespan=lifespan
)

# CORS Configuration
app.add_middleware(
    CORSMiddleware,
    allow_origins=settings.CORS_ORIGINS,
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# Global Validation Error Handler (Returns clean 422 with invalid field path and error message)
@app.exception_handler(RequestValidationError)
async def validation_exception_handler(request: Request, exc: RequestValidationError):
    error_details = []
    for err in exc.errors():
        field = " -> ".join([str(loc) for loc in err.get("loc", [])])
        error_details.append({
            "field": field,
            "message": err.get("msg"),
            "type": err.get("type")
        })
    logger.warning("422 Validation Error on %s %s: %s", request.method, request.url.path, error_details)
    return JSONResponse(
        status_code=status.HTTP_422_UNPROCESSABLE_ENTITY,
        content={
            "status": "error",
            "error_code": "UNPROCESSABLE_ENTITY",
            "message": "Input validation failed. Please check submitted fields.",
            "details": error_details
        }
    )

# Global HTTP Exception Handler
@app.exception_handler(StarletteHTTPException)
async def http_exception_handler(request: Request, exc: StarletteHTTPException):
    return JSONResponse(
        status_code=exc.status_code,
        content={
            "status": "error",
            "error_code": f"HTTP_{exc.status_code}",
            "message": exc.detail
        }
    )

# Generic Unhandled Exception Handler
@app.exception_handler(Exception)
async def generic_exception_handler(request: Request, exc: Exception):
    logger.error("Unhandled error on %s %s: %s", request.method, request.url.path, str(exc), exc_info=True)
    return JSONResponse(
        status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
        content={
            "status": "error",
            "error_code": "INTERNAL_SERVER_ERROR",
            "message": "An unexpected server error occurred."
        }
    )

# Mount root health router and API v1 router
app.include_router(root_health_router)
app.include_router(api_v1_router)

@app.get("/", tags=["Root"])
def root():
    return {
        "service": settings.PROJECT_NAME,
        "version": settings.VERSION,
        "environment": settings.ENVIRONMENT,
        "api_documentation": f"{settings.API_V1_STR}/docs",
        "health_check": "/health",
        "db_health_check": f"{settings.API_V1_STR}/health/db"
    }

if __name__ == "__main__":
    import uvicorn
    uvicorn.run("backend.app.main:app", host="0.0.0.0", port=8000, reload=True)
