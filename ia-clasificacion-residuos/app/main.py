# FastAPI Main Application
from fastapi import FastAPI, HTTPException, Request
from fastapi.middleware.cors import CORSMiddleware
from fastapi.responses import JSONResponse
import logging
import sys
import time

from .schemas import (
    ClassificationRequest,
    ClassificationResult,
    HealthCheck
)
from .model_loader import classifier_model
from .classifier import classify_waste

# Configure logging
logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s - %(name)s - %(levelname)s - %(message)s',
    handlers=[logging.StreamHandler(sys.stdout)]
)
logger = logging.getLogger(__name__)

# Track startup time
startup_time = time.time()

# Create FastAPI app
app = FastAPI(
    title="EcoTrack Waste Classifier API",
    version="1.0.0",
    description="Microservicio de clasificación automática de residuos con IA",
    docs_url="/docs",
    redoc_url="/redoc"
)

# CORS middleware
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],  # En producción, especificar dominios exactos
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

@app.on_event("startup")
async def startup_event():
    """Load model on startup (warm-up)"""
    logger.info("🚀 Starting EcoTrack Waste Classifier API...")
    success = classifier_model.load()
    if not success:
        logger.error("❌ Failed to load model on startup!")
        # Don't raise error - use dummy model for testing
    logger.info("✅ API ready to classify waste!")

@app.get("/", response_model=HealthCheck, tags=["Health"])
async def health_check():
    """
    Health check endpoint
    
    Returns service status and model information
    """
    uptime = time.time() - startup_time
    
    return HealthCheck(
        status="healthy" if classifier_model.is_loaded() else "unhealthy",
        model_loaded=classifier_model.is_loaded(),
        version=classifier_model.version,
        uptime_seconds=round(uptime, 2)
    )

@app.get("/health", response_model=HealthCheck, tags=["Health"])
async def health():
    """Alias for health check"""
    return await health_check()

@app.post("/classify", response_model=ClassificationResult, tags=["Classification"])
async def classify_endpoint(request: ClassificationRequest):
    """
    Classify waste from image URL
    
    - **image_url**: Public Firebase Storage URL
    - **report_id**: Report ID in Firestore
    - **user_id**: User ID who created the report
    
    Returns classification with confidence level
    """
    try:
        logger.info(f"📥 Received classification request for report {request.report_id}")
        
        # Verify model is loaded
        if not classifier_model.is_loaded():
            raise HTTPException(
                status_code=503,
                detail="Model not loaded. Service unavailable."
            )
        
        # Classify
        classification, confidence, processing_time = await classify_waste(
            image_url=str(request.image_url),
            model=classifier_model
        )
        
        result = ClassificationResult(
            classification=classification,
            confidence=round(confidence, 4),
            report_id=request.report_id,
            processing_time_ms=processing_time,
            model_version=classifier_model.version
        )
        
        logger.info(f"✅ Classification complete: {result.classification} ({result.confidence:.2%})")
        return result
        
    except ValueError as e:
        logger.error(f"❌ Validation error: {e}")
        raise HTTPException(status_code=400, detail=str(e))
    except Exception as e:
        logger.error(f"❌ Internal error: {e}", exc_info=True)
        raise HTTPException(status_code=500, detail="Internal server error")

@app.exception_handler(Exception)
async def global_exception_handler(request: Request, exc: Exception):
    """Global exception handler"""
    logger.error(f"❌ Unhandled exception: {exc}", exc_info=True)
    return JSONResponse(
        status_code=500,
        content={"detail": "An unexpected error occurred"}
    )

if __name__ == "__main__":
    import uvicorn
    uvicorn.run(app, host="0.0.0.0", port=8080, log_level="info")
