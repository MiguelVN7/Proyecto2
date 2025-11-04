# Image downloader and classifier
import logging
import requests
from typing import Optional
import time

logger = logging.getLogger(__name__)

class ImageDownloader:
    """Download images from URLs safely"""
    
    @staticmethod
    def download(url: str, max_size_mb: int = 10) -> Optional[bytes]:
        """
        Download image from URL with validations
        
        Args:
            url: Image URL
            max_size_mb: Maximum allowed image size in MB
            
        Returns:
            Image bytes or None if download failed
        """
        try:
            # Download with timeout
            response = requests.get(
                url,
                timeout=15,
                stream=True,
                headers={'User-Agent': 'EcoTrack-AI-Classifier/1.0'}
            )
            response.raise_for_status()
            
            # Validate Content-Type
            content_type = response.headers.get('Content-Type', '')
            if not content_type.startswith('image/'):
                logger.error(f"❌ Invalid content type: {content_type}")
                return None
            
            # Validate size
            content_length = response.headers.get('Content-Length')
            if content_length:
                size_mb = int(content_length) / (1024 * 1024)
                if size_mb > max_size_mb:
                    logger.error(f"❌ Image too large: {size_mb:.2f}MB")
                    return None
            
            # Read content
            image_bytes = response.content
            
            # Validate actual size
            actual_size_mb = len(image_bytes) / (1024 * 1024)
            if actual_size_mb > max_size_mb:
                logger.error(f"❌ Downloaded image exceeds {max_size_mb}MB")
                return None
            
            logger.info(f"✅ Downloaded image ({actual_size_mb:.2f}MB)")
            return image_bytes
            
        except requests.exceptions.RequestException as e:
            logger.error(f"❌ Error downloading image: {e}")
            return None

async def classify_waste(
    image_url: str,
    model
) -> tuple[str, float, int]:
    """
    Classify waste from an image URL
    
    Args:
        image_url: Public URL of the image
        model: Loaded classifier model
        
    Returns:
        Tuple of (classification, confidence, processing_time_ms)
        
    Raises:
        ValueError: If image download fails
    """
    start_time = time.time()
    
    # Download image
    downloader = ImageDownloader()
    image_bytes = downloader.download(image_url)
    
    if not image_bytes:
        raise ValueError("Failed to download image")
    
    # Classify
    classification, confidence = model.predict(image_bytes)
    
    processing_time = int((time.time() - start_time) * 1000)
    
    logger.info(
        f"✅ Classified as '{classification}' "
        f"({confidence:.2%} confidence) in {processing_time}ms"
    )
    
    return classification, confidence, processing_time
