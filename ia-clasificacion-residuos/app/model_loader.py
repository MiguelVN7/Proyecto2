# Model loader and predictor
import tensorflow as tf
from pathlib import Path
import logging
import numpy as np
from PIL import Image
import io

logger = logging.getLogger(__name__)

class WasteClassifierModel:
    """
    Waste classifier using TensorFlow/Keras model
    Classifies waste into: Orgánico, Aprovechable, No Aprovechable
    """
    
    def __init__(self, model_path: str = "models/waste_classifier_v1.h5"):
        self.model = None
        self.model_path = Path(model_path)
        self.class_names = ["Aprovechable", "No Aprovechable", "Orgánico"]
        self.input_size = (224, 224)  # Ajustar según tu modelo
        self.version = "1.0.0"
        
    def load(self) -> bool:
        """Load the model at startup (warm-up)"""
        try:
            logger.info(f"🔄 Loading model from {self.model_path}")
            
            # Check if model file exists
            if not self.model_path.exists():
                logger.warning(f"⚠️ Model file not found at {self.model_path}")
                logger.info("📝 Using dummy model for testing...")
                self._load_dummy_model()
                return True
            
            # Load actual model
            self.model = tf.keras.models.load_model(str(self.model_path))
            
            # Warm-up: run dummy prediction
            dummy_input = np.zeros((1, *self.input_size, 3), dtype=np.float32)
            _ = self.model.predict(dummy_input, verbose=0)
            
            logger.info("✅ Model loaded and warmed up successfully")
            return True
            
        except Exception as e:
            logger.error(f"❌ Error loading model: {e}")
            logger.info("📝 Falling back to dummy model for testing...")
            self._load_dummy_model()
            return True
    
    def _load_dummy_model(self):
        """Create a dummy model for testing when real model is not available"""
        logger.info("🔨 Creating dummy model for testing...")
        
        # Simple model that returns random predictions
        inputs = tf.keras.Input(shape=(*self.input_size, 3))
        x = tf.keras.layers.GlobalAveragePooling2D()(inputs)
        outputs = tf.keras.layers.Dense(3, activation='softmax')(x)
        
        self.model = tf.keras.Model(inputs=inputs, outputs=outputs)
        logger.info("✅ Dummy model created successfully")
    
    def is_loaded(self) -> bool:
        """Check if model is loaded"""
        return self.model is not None
    
    def preprocess_image(self, image_bytes: bytes) -> np.ndarray:
        """
        Preprocess image for model input
        
        Args:
            image_bytes: Raw image bytes
            
        Returns:
            Preprocessed image array ready for model
        """
        # Load image
        img = Image.open(io.BytesIO(image_bytes))
        
        # Convert to RGB if necessary
        if img.mode != 'RGB':
            img = img.convert('RGB')
        
        # Resize to model input size
        img = img.resize(self.input_size)
        
        # Convert to array and normalize (0-1)
        img_array = np.array(img, dtype=np.float32) / 255.0
        
        # Add batch dimension
        img_array = np.expand_dims(img_array, axis=0)
        
        return img_array
    
    def predict(self, image_bytes: bytes) -> tuple[str, float]:
        """
        Predict waste classification
        
        Args:
            image_bytes: Raw image bytes
            
        Returns:
            Tuple of (classification, confidence)
            
        Raises:
            RuntimeError: If model is not loaded
        """
        if not self.is_loaded():
            raise RuntimeError("Model not loaded")
        
        # Preprocess image
        processed_img = self.preprocess_image(image_bytes)
        
        # Predict
        predictions = self.model.predict(processed_img, verbose=0)[0]
        
        # Get class with highest confidence
        class_idx = int(predictions.argmax())
        confidence = float(predictions[class_idx])
        classification = self.class_names[class_idx]
        
        logger.info(f"🎯 Prediction: {classification} ({confidence:.2%})")
        
        return classification, confidence

# Global singleton instance
classifier_model = WasteClassifierModel()
