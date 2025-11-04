/**
 * AI Classification Service
 * Integrates with Google Cloud Functions to classify waste images using Vision AI
 */

const axios = require('axios');
const fs = require('fs-extra');

// Cloud Function endpoint (deployed Firebase Function)
const AI_FUNCTION_URL = 'https://us-central1-ecotrack-app-23a64.cloudfunctions.net/classifyWasteManual';

/**
 * Classify waste image using AI
 * @param {string} imagePath - Local path to the image file
 * @returns {Promise<Object>} Classification result with category and confidence
 */
async function classifyWasteImage(imagePath) {
  try {
    console.log(`🤖 Starting AI classification for: ${imagePath}`);
    
    // Read image file and convert to base64
    const imageBuffer = await fs.readFile(imagePath);
    const base64Image = imageBuffer.toString('base64');
    
    // Determine image MIME type
    const extension = imagePath.split('.').pop().toLowerCase();
    const mimeTypes = {
      'jpg': 'image/jpeg',
      'jpeg': 'image/jpeg',
      'png': 'image/png',
      'gif': 'image/gif',
      'webp': 'image/webp'
    };
    const mimeType = mimeTypes[extension] || 'image/jpeg';
    
    // Prepare request payload
    const payload = {
      imageData: base64Image,
      mimeType: mimeType
    };
    
    console.log(`📤 Sending image to AI (${(base64Image.length / 1024).toFixed(1)} KB)`);
    
    // Call Cloud Function
    const startTime = Date.now();
    const response = await axios.post(AI_FUNCTION_URL, payload, {
      headers: {
        'Content-Type': 'application/json'
      },
      timeout: 30000 // 30 seconds timeout
    });
    
    const processingTime = Date.now() - startTime;
    
    if (response.data && response.data.success) {
      const result = {
        success: true,
        category: response.data.classification,
        confidence: response.data.confidence,
        processingTime: processingTime,
        modelVersion: response.data.model_version || '1.0',
        labels: response.data.labels || []
      };
      
      console.log(`✅ AI Classification successful:`);
      console.log(`   Category: ${result.category}`);
      console.log(`   Confidence: ${(result.confidence * 100).toFixed(1)}%`);
      console.log(`   Processing time: ${result.processingTime}ms`);
      
      return result;
    } else {
      console.warn('⚠️  AI returned no classification');
      return {
        success: false,
        error: 'No classification returned',
        processingTime: processingTime
      };
    }
    
  } catch (error) {
    console.error('❌ Error calling AI classification:', error.message);
    
    if (error.response) {
      console.error(`   Status: ${error.response.status}`);
      console.error(`   Data:`, error.response.data);
    }
    
    return {
      success: false,
      error: error.message,
      processingTime: 0
    };
  }
}

/**
 * Check if AI classification is available
 * @returns {Promise<boolean>} True if AI service is reachable
 */
async function isAIAvailable() {
  try {
    const response = await axios.get(AI_FUNCTION_URL, { timeout: 5000 });
    return response.status === 200;
  } catch (error) {
    console.warn('⚠️  AI service not available:', error.message);
    return false;
  }
}

module.exports = {
  classifyWasteImage,
  isAIAvailable
};
