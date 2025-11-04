# Schemas for API requests and responses
from pydantic import BaseModel, HttpUrl
from typing import Literal

class ClassificationRequest(BaseModel):
    """Request model for waste classification"""
    image_url: HttpUrl
    report_id: str
    user_id: str

    model_config = {
        "json_schema_extra": {
            "examples": [
                {
                    "image_url": "https://storage.googleapis.com/bucket/image.jpg",
                    "report_id": "ECO-12345678",
                    "user_id": "user_abc123"
                }
            ]
        }
    }

class ClassificationResult(BaseModel):
    """Response model with classification results"""
    classification: Literal["Orgánico", "Aprovechable", "No Aprovechable"]
    confidence: float  # 0.0 - 1.0
    report_id: str
    processing_time_ms: int
    model_version: str = "1.0.0"
    
    model_config = {
        "json_schema_extra": {
            "examples": [
                {
                    "classification": "Orgánico",
                    "confidence": 0.95,
                    "report_id": "ECO-12345678",
                    "processing_time_ms": 450,
                    "model_version": "1.0.0"
                }
            ]
        }
    }

class HealthCheck(BaseModel):
    """Health check response"""
    status: str
    model_loaded: bool
    version: str
    uptime_seconds: float = 0.0
