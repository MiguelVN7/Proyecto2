const functions = require('firebase-functions');
const admin = require('firebase-admin');
const vision = require('@google-cloud/vision');

// Initialize Firebase Admin (if not already initialized)
if (!admin.apps.length) {
  admin.initializeApp();
}

// Initialize Vision API client
const visionClient = new vision.ImageAnnotatorClient();

// Firestore reference
const db = admin.firestore();

/**
 * Waste classification mapping
 * Maps Vision API labels to our 3 waste categories
 */
const WASTE_CATEGORIES = {
  ORGANICO: 'Orgánico',
  RECICLABLE: 'Reciclable',
  NO_RECICLABLE: 'No Reciclable'
};

// Enhanced label to category mapping with PRIORITY SYSTEM
// Priority levels: 4 (CRITICAL) > 3 (HIGH) > 2 (MEDIUM) > 1 (LOW)
// NO_RECICLABLE gets 2.0x bonus multiplier
const labelMapping = {
  // ========== NO RECICLABLE (Checked FIRST - highest priority) ==========
  // Snacks y empaques flexibles (HIGH PRIORITY - muy específicos)
  'chip bag': { category: WASTE_CATEGORIES.NO_RECICLABLE, priority: 4 },
  'snack bag': { category: WASTE_CATEGORIES.NO_RECICLABLE, priority: 4 },
  'candy wrapper': { category: WASTE_CATEGORIES.NO_RECICLABLE, priority: 4 },
  'food packaging': { category: WASTE_CATEGORIES.NO_RECICLABLE, priority: 4 },
  'flexible packaging': { category: WASTE_CATEGORIES.NO_RECICLABLE, priority: 4 },
  'potato chip': { category: WASTE_CATEGORIES.NO_RECICLABLE, priority: 4 },
  'chips': { category: WASTE_CATEGORIES.NO_RECICLABLE, priority: 3 },
  'snack': { category: WASTE_CATEGORIES.NO_RECICLABLE, priority: 3 },
  'papas': { category: WASTE_CATEGORIES.NO_RECICLABLE, priority: 3 },
  'papitas': { category: WASTE_CATEGORIES.NO_RECICLABLE, priority: 3 },
  'mecato': { category: WASTE_CATEGORIES.NO_RECICLABLE, priority: 4 },
  'chito': { category: WASTE_CATEGORIES.NO_RECICLABLE, priority: 4 },
  'corn snack': { category: WASTE_CATEGORIES.NO_RECICLABLE, priority: 4 },
  'pop corn': { category: WASTE_CATEGORIES.NO_RECICLABLE, priority: 4 },
  'popcorn': { category: WASTE_CATEGORIES.NO_RECICLABLE, priority: 4 },
  'crisp': { category: WASTE_CATEGORIES.NO_RECICLABLE, priority: 3 },

  // Alimentos procesados/empacados detectados por Vision AI (CRITICAL PRIORITY)
  'junk food': { category: WASTE_CATEGORIES.NO_RECICLABLE, priority: 4 },
  'fast food': { category: WASTE_CATEGORIES.NO_RECICLABLE, priority: 4 },
  'finger food': { category: WASTE_CATEGORIES.NO_RECICLABLE, priority: 4 },
  'convenience food': { category: WASTE_CATEGORIES.NO_RECICLABLE, priority: 4 },
  'comfort food': { category: WASTE_CATEGORIES.NO_RECICLABLE, priority: 3 },
  'processed food': { category: WASTE_CATEGORIES.NO_RECICLABLE, priority: 3 },
  'packaged food': { category: WASTE_CATEGORIES.NO_RECICLABLE, priority: 4 },
  'packaging and labeling': { category: WASTE_CATEGORIES.NO_RECICLABLE, priority: 3 },
  
  // Papel contaminado (HIGH PRIORITY)
  'napkin': { category: WASTE_CATEGORIES.NO_RECICLABLE, priority: 3 },
  'tissue': { category: WASTE_CATEGORIES.NO_RECICLABLE, priority: 3 },
  'paper towel': { category: WASTE_CATEGORIES.NO_RECICLABLE, priority: 3 },
  'servilleta': { category: WASTE_CATEGORIES.NO_RECICLABLE, priority: 3 },
  'papel higiénico': { category: WASTE_CATEGORIES.NO_RECICLABLE, priority: 3 },
  'toilet paper': { category: WASTE_CATEGORIES.NO_RECICLABLE, priority: 3 },
  'used paper': { category: WASTE_CATEGORIES.NO_RECICLABLE, priority: 3 },
  'dirty paper': { category: WASTE_CATEGORIES.NO_RECICLABLE, priority: 3 },
  
  // Materiales no reciclables (MEDIUM PRIORITY)
  'styrofoam': { category: WASTE_CATEGORIES.NO_RECICLABLE, priority: 2 },
  'polystyrene': { category: WASTE_CATEGORIES.NO_RECICLABLE, priority: 2 },
  'foam': { category: WASTE_CATEGORIES.NO_RECICLABLE, priority: 2 },
  'icopor': { category: WASTE_CATEGORIES.NO_RECICLABLE, priority: 2 },
  
  // Envoltorios genéricos (MEDIUM PRIORITY)
  'wrapper': { category: WASTE_CATEGORIES.NO_RECICLABLE, priority: 2 },
  'plastic bag': { category: WASTE_CATEGORIES.NO_RECICLABLE, priority: 2 },
  'shopping bag': { category: WASTE_CATEGORIES.NO_RECICLABLE, priority: 2 },
  'film': { category: WASTE_CATEGORIES.NO_RECICLABLE, priority: 2 },
  'envoltorio': { category: WASTE_CATEGORIES.NO_RECICLABLE, priority: 2 },
  
  // Otros no reciclables (MEDIUM PRIORITY)
  'straw': { category: WASTE_CATEGORIES.NO_RECICLABLE, priority: 2 },
  'cigarette': { category: WASTE_CATEGORIES.NO_RECICLABLE, priority: 2 },
  'diaper': { category: WASTE_CATEGORIES.NO_RECICLABLE, priority: 2 },
  'dirty': { category: WASTE_CATEGORIES.NO_RECICLABLE, priority: 2 },
  'contaminated': { category: WASTE_CATEGORIES.NO_RECICLABLE, priority: 2 },
  'pitillo': { category: WASTE_CATEGORIES.NO_RECICLABLE, priority: 2 },
  'pañal': { category: WASTE_CATEGORIES.NO_RECICLABLE, priority: 2 },
  
  // Basura general (LOW PRIORITY - muy genérico)
  'trash': { category: WASTE_CATEGORIES.NO_RECICLABLE, priority: 1 },
  'waste': { category: WASTE_CATEGORIES.NO_RECICLABLE, priority: 1 },
  'garbage': { category: WASTE_CATEGORIES.NO_RECICLABLE, priority: 1 },
  'rubbish': { category: WASTE_CATEGORIES.NO_RECICLABLE, priority: 1 },
  'basura': { category: WASTE_CATEGORIES.NO_RECICLABLE, priority: 1 },
  
  // ========== RECICLABLE ==========
  // Botellas y envases específicos (HIGH PRIORITY)
  'plastic bottle': { category: WASTE_CATEGORIES.RECICLABLE, priority: 3 },
  'water bottle': { category: WASTE_CATEGORIES.RECICLABLE, priority: 3 },
  'soda bottle': { category: WASTE_CATEGORIES.RECICLABLE, priority: 3 },
  'glass bottle': { category: WASTE_CATEGORIES.RECICLABLE, priority: 3 },
  
  // Metal específico (HIGH PRIORITY)
  'aluminum can': { category: WASTE_CATEGORIES.RECICLABLE, priority: 3 },
  'tin can': { category: WASTE_CATEGORIES.RECICLABLE, priority: 3 },
  'beverage can': { category: WASTE_CATEGORIES.RECICLABLE, priority: 3 },
  'lata de aluminio': { category: WASTE_CATEGORIES.RECICLABLE, priority: 3 },
  
  // Papel limpio (MEDIUM PRIORITY)
  'cardboard': { category: WASTE_CATEGORIES.RECICLABLE, priority: 2 },
  'newspaper': { category: WASTE_CATEGORIES.RECICLABLE, priority: 2 },
  'magazine': { category: WASTE_CATEGORIES.RECICLABLE, priority: 2 },
  'carton': { category: WASTE_CATEGORIES.RECICLABLE, priority: 2 },
  'box': { category: WASTE_CATEGORIES.RECICLABLE, priority: 2 },
  'cartón': { category: WASTE_CATEGORIES.RECICLABLE, priority: 2 },
  'caja': { category: WASTE_CATEGORIES.RECICLABLE, priority: 2 },
  
  // Envases reciclables (MEDIUM PRIORITY)
  'bottle': { category: WASTE_CATEGORIES.RECICLABLE, priority: 2 },
  'container': { category: WASTE_CATEGORIES.RECICLABLE, priority: 2 },
  'jar': { category: WASTE_CATEGORIES.RECICLABLE, priority: 2 },
  'jug': { category: WASTE_CATEGORIES.RECICLABLE, priority: 2 },
  'botella': { category: WASTE_CATEGORIES.RECICLABLE, priority: 2 },
  'envase': { category: WASTE_CATEGORIES.RECICLABLE, priority: 2 },
  'recipiente': { category: WASTE_CATEGORIES.RECICLABLE, priority: 2 },
  
  // Metal genérico (MEDIUM PRIORITY)
  'can': { category: WASTE_CATEGORIES.RECICLABLE, priority: 2 },
  'metal': { category: WASTE_CATEGORIES.RECICLABLE, priority: 2 },
  'aluminum': { category: WASTE_CATEGORIES.RECICLABLE, priority: 2 },
  'aluminium': { category: WASTE_CATEGORIES.RECICLABLE, priority: 2 },
  'tin': { category: WASTE_CATEGORIES.RECICLABLE, priority: 2 },
  'steel': { category: WASTE_CATEGORIES.RECICLABLE, priority: 2 },
  'lata': { category: WASTE_CATEGORIES.RECICLABLE, priority: 2 },
  'aluminio': { category: WASTE_CATEGORIES.RECICLABLE, priority: 2 },
  
  // Vidrio (MEDIUM PRIORITY)
  'glass': { category: WASTE_CATEGORIES.RECICLABLE, priority: 2 },
  'vidrio': { category: WASTE_CATEGORIES.RECICLABLE, priority: 2 },
  
  // Otros reciclables (MEDIUM PRIORITY)
  'tetrapack': { category: WASTE_CATEGORIES.RECICLABLE, priority: 2 },
  'tetrapak': { category: WASTE_CATEGORIES.RECICLABLE, priority: 2 },
  'tetrabrik': { category: WASTE_CATEGORIES.RECICLABLE, priority: 2 },
  
  // Bolsas reciclables específicas (MEDIUM PRIORITY)
  'grocery bag': { category: WASTE_CATEGORIES.RECICLABLE, priority: 2 },
  'tote bag': { category: WASTE_CATEGORIES.RECICLABLE, priority: 2 },
  'reusable bag': { category: WASTE_CATEGORIES.RECICLABLE, priority: 2 },

  // Materiales genéricos (LOW PRIORITY - pueden ser engañosos)
  'plastic': { category: WASTE_CATEGORIES.RECICLABLE, priority: 1 },
  'pet': { category: WASTE_CATEGORIES.RECICLABLE, priority: 1 },
  'hdpe': { category: WASTE_CATEGORIES.RECICLABLE, priority: 1 },
  'polyethylene': { category: WASTE_CATEGORIES.RECICLABLE, priority: 1 },
  'polypropylene': { category: WASTE_CATEGORIES.RECICLABLE, priority: 1 },
  'plástico': { category: WASTE_CATEGORIES.RECICLABLE, priority: 1 },
  'paper': { category: WASTE_CATEGORIES.RECICLABLE, priority: 1 },
  'papel': { category: WASTE_CATEGORIES.RECICLABLE, priority: 1 },
  'packaging': { category: WASTE_CATEGORIES.RECICLABLE, priority: 1 },
  'empaque': { category: WASTE_CATEGORIES.RECICLABLE, priority: 1 },
  'recyclable': { category: WASTE_CATEGORIES.RECICLABLE, priority: 1 },
  'reciclable': { category: WASTE_CATEGORIES.RECICLABLE, priority: 1 },
  'bag': { category: WASTE_CATEGORIES.RECICLABLE, priority: 1 },
  'bolsa': { category: WASTE_CATEGORIES.RECICLABLE, priority: 1 },
  
  // ========== ORGÁNICO ==========
  // Frutas y vegetales (MEDIUM PRIORITY)
  'fruit': { category: WASTE_CATEGORIES.ORGANICO, priority: 2 },
  'vegetable': { category: WASTE_CATEGORIES.ORGANICO, priority: 2 },
  'banana': { category: WASTE_CATEGORIES.ORGANICO, priority: 2 },
  'apple': { category: WASTE_CATEGORIES.ORGANICO, priority: 2 },
  'orange': { category: WASTE_CATEGORIES.ORGANICO, priority: 2 },
  'peel': { category: WASTE_CATEGORIES.ORGANICO, priority: 2 },
  'cáscara': { category: WASTE_CATEGORIES.ORGANICO, priority: 2 },
  'fruta': { category: WASTE_CATEGORIES.ORGANICO, priority: 2 },
  'verdura': { category: WASTE_CATEGORIES.ORGANICO, priority: 2 },
  
  // Plantas (MEDIUM PRIORITY)
  'plant': { category: WASTE_CATEGORIES.ORGANICO, priority: 2 },
  'leaf': { category: WASTE_CATEGORIES.ORGANICO, priority: 2 },
  'flower': { category: WASTE_CATEGORIES.ORGANICO, priority: 2 },
  'grass': { category: WASTE_CATEGORIES.ORGANICO, priority: 2 },
  'tree': { category: WASTE_CATEGORIES.ORGANICO, priority: 2 },
  'branch': { category: WASTE_CATEGORIES.ORGANICO, priority: 2 },
  
  // Comida (MEDIUM PRIORITY)
  'bread': { category: WASTE_CATEGORIES.ORGANICO, priority: 2 },
  'meat': { category: WASTE_CATEGORIES.ORGANICO, priority: 2 },
  'fish': { category: WASTE_CATEGORIES.ORGANICO, priority: 2 },
  'egg': { category: WASTE_CATEGORIES.ORGANICO, priority: 2 },
  'coffee': { category: WASTE_CATEGORIES.ORGANICO, priority: 2 },
  'tea': { category: WASTE_CATEGORIES.ORGANICO, priority: 2 },
  'rice': { category: WASTE_CATEGORIES.ORGANICO, priority: 2 },
  'pasta': { category: WASTE_CATEGORIES.ORGANICO, priority: 2 },
  'cheese': { category: WASTE_CATEGORIES.ORGANICO, priority: 2 },
  'leftover': { category: WASTE_CATEGORIES.ORGANICO, priority: 2 },
  'sobras': { category: WASTE_CATEGORIES.ORGANICO, priority: 2 },
  
  // Genéricos orgánicos (LOW PRIORITY)
  'food': { category: WASTE_CATEGORIES.ORGANICO, priority: 1 },
  'compost': { category: WASTE_CATEGORIES.ORGANICO, priority: 1 },
  'organic': { category: WASTE_CATEGORIES.ORGANICO, priority: 1 },
  'biodegradable': { category: WASTE_CATEGORIES.ORGANICO, priority: 1 },
  'comida': { category: WASTE_CATEGORIES.ORGANICO, priority: 1 },
};

/**
 * Cloud Function triggered when a new image is uploaded to Storage
 * Automatically classifies waste using Google Vision AI
 * 
 * COMMENTED OUT: This function requires Firebase Storage bucket configuration
 * Currently using classifyWasteManual instead
 */
/*
exports.classifyWaste = functions.storage.object().onFinalize(async (object) => {
  const startTime = Date.now();
  const filePath = object.name; // e.g., "reports/userId/imageId.jpg"
  const bucketName = object.bucket;

  console.log(`🎯 New image uploaded: ${filePath}`);

  // Only process images in the reports folder
  if (!filePath.startsWith('reports/')) {
    console.log('⏭️  Skipping: Not a report image');
    return null;
  }

  // Skip if it's not an image
  const contentType = object.contentType || '';
  if (!contentType.startsWith('image/')) {
    console.log('⏭️  Skipping: Not an image file');
    return null;
  }

  try {
    // Construct the GCS URI for Vision API
    const imageUri = `gs://${bucketName}/${filePath}`;
    
    console.log(`🔍 Analyzing image with Vision AI: ${imageUri}`);

    // Call Vision API for label detection
    const [result] = await visionClient.labelDetection(imageUri);
    const labels = result.labelAnnotations;

    if (!labels || labels.length === 0) {
      console.log('⚠️  No labels detected by Vision API');
      return null;
    }

    console.log(`✅ Vision API detected ${labels.length} labels:`, 
      labels.map(l => `${l.description} (${(l.score * 100).toFixed(1)}%)`).join(', ')
    );

    // Classify waste based on detected labels
    const classification = classifyWaste(labels);
    
    if (!classification) {
      console.log('⚠️  Could not classify waste from labels');
      return null;
    }

    console.log(`🏷️  Classified as: ${classification.category} (${(classification.confidence * 100).toFixed(1)}% confidence)`);

    // Find the report document by matching the image URL
    const reportsRef = db.collection('reports');
    const snapshot = await reportsRef
      .where('foto_url', '==', `https://firebasestorage.googleapis.com/v0/b/${bucketName}/o/${encodeURIComponent(filePath)}?alt=media`)
      .limit(1)
      .get();

    if (snapshot.empty) {
      console.log('⚠️  No report found matching this image');
      return null;
    }

    const reportDoc = snapshot.docs[0];
    const reportId = reportDoc.id;
    const processingTime = Date.now() - startTime;

    // Update the report with AI classification
    await reportDoc.ref.update({
      clasificacion: classification.category,
      ai_confidence: classification.confidence,
      ai_processing_time_ms: processingTime,
      ai_classified_at: admin.firestore.FieldValue.serverTimestamp(),
      ai_model_version: 'google-vision-v1',
      ai_detected_labels: labels.slice(0, 5).map(l => ({
        label: l.description,
        score: l.score
      })),
      updated_at: admin.firestore.FieldValue.serverTimestamp()
    });

    console.log(`✅ Report ${reportId} updated successfully`);
    console.log(`⏱️  Total processing time: ${processingTime}ms`);

    return {
      success: true,
      reportId,
      classification: classification.category,
      confidence: classification.confidence,
      processingTime
    };

  } catch (error) {
    console.error('❌ Error classifying waste:', error);
    return null;
  }
});
*/

/**
 * Classifies waste based on Vision API labels with PRIORITY SYSTEM
 * Priority levels: 4 (CRITICAL) > 3 (HIGH) > 2 (MEDIUM) > 1 (LOW)
 * NO RECICLABLE keywords get extra 2.0x boost to avoid false positives
 *
 * @param {Array} labels - Array of label annotations from Vision API
 * @returns {Object} - { category: string, confidence: number }
 */
function classifyWaste(labels) {
  // Weighted score for each category
  const categoryScores = {
    [WASTE_CATEGORIES.ORGANICO]: 0,
    [WASTE_CATEGORIES.RECICLABLE]: 0,
    [WASTE_CATEGORIES.NO_RECICLABLE]: 0
  };

  // Count labels matching each category
  const categoryCounts = {
    [WASTE_CATEGORIES.ORGANICO]: 0,
    [WASTE_CATEGORIES.RECICLABLE]: 0,
    [WASTE_CATEGORIES.NO_RECICLABLE]: 0
  };

  // Track best match per label (for debugging)
  const matchedLabels = [];

  // Check each label against our mapping
  for (const label of labels) {
    const labelText = label.description.toLowerCase();
    const visionScore = label.score;

    // Find BEST matching keyword (longest match = most specific)
    let bestMatch = null;
    let longestKeyword = '';

    for (const [keyword, config] of Object.entries(labelMapping)) {
      if (labelText.includes(keyword) && keyword.length > longestKeyword.length) {
        longestKeyword = keyword;
        bestMatch = config;
      }
    }

    if (bestMatch) {
      const category = bestMatch.category;
      const priority = bestMatch.priority;

      // Calculate weighted score:
      // - Base: Vision API confidence (0.0 - 1.0)
      // - Priority multiplier: 1x, 2x, 3x, or 4x
      // - NO_RECICLABLE bonus: 2.0x (critical to avoid false positives)
      const noReciclaBonus = (category === WASTE_CATEGORIES.NO_RECICLABLE) ? 2.0 : 1.0;
      const weightedScore = visionScore * priority * noReciclaBonus;

      categoryScores[category] += weightedScore;
      categoryCounts[category] += 1;

      matchedLabels.push({
        label: label.description,
        keyword: longestKeyword,
        category,
        priority,
        visionScore: (visionScore * 100).toFixed(1),
        weightedScore: weightedScore.toFixed(3)
      });

      console.log(`  📊 "${label.description}" (${(visionScore * 100).toFixed(1)}%) → "${longestKeyword}" → ${category} [Priority: ${priority}, Weighted: ${weightedScore.toFixed(3)}]`);
    }
  }

  // Find category with highest WEIGHTED score
  let maxScore = 0;
  let bestCategory = null;

  for (const [category, score] of Object.entries(categoryScores)) {
    if (score > maxScore) {
      maxScore = score;
      bestCategory = category;
    }
  }

  // If no category matched, return null
  if (!bestCategory || maxScore === 0) {
    console.log('  ⚠️  No matching keywords found in labels');
    return null;
  }

  // Calculate confidence based on total score
  // Max possible score per label: 1.0 (visionScore) * 4 (priority) * 2.0 (bonus) = 8.0
  // We normalize based on actual max score to get realistic confidence
  const totalScoreAllCategories = Object.values(categoryScores).reduce((a, b) => a + b, 0);
  const rawConfidence = totalScoreAllCategories > 0 ? maxScore / totalScoreAllCategories : 0;

  // Boost confidence if we have multiple strong matches
  const count = categoryCounts[bestCategory];
  const countBoost = Math.min(1.0 + (count - 1) * 0.15, 1.5); // Up to +50% for multiple matches

  // Final confidence calculation (0.0 - 1.0 range)
  const normalizedConfidence = Math.min(rawConfidence * countBoost, 1.0);

  console.log(`  🎯 Final Decision: ${bestCategory} (confidence: ${(normalizedConfidence * 100).toFixed(1)}%)`);
  console.log(`  📈 Score breakdown:`, Object.entries(categoryScores)
    .map(([cat, score]) => `${cat}: ${score.toFixed(2)}`)
    .join(', '));
  console.log(`  🔢 Matches: ${count}, Confidence boost: ${(countBoost * 100).toFixed(0)}%`);

  return {
    category: bestCategory,
    confidence: normalizedConfidence,
    matchedLabels // Include for debugging
  };
}

/**
 * HTTP endpoint for manual classification (for testing)
 * Call with: POST /classifyWaste
 * Body: { "imageUrl": "gs://bucket/path/to/image.jpg" }
 */
exports.classifyWasteManual = functions.https.onRequest(async (req, res) => {
  // Enable CORS
  res.set('Access-Control-Allow-Origin', '*');
  
  if (req.method === 'OPTIONS') {
    res.set('Access-Control-Allow-Methods', 'POST');
    res.set('Access-Control-Allow-Headers', 'Content-Type');
    res.status(204).send('');
    return;
  }

  if (req.method !== 'POST') {
    res.status(405).send('Method Not Allowed');
    return;
  }

  const { imageUrl, imageData, mimeType, reportId } = req.body;

  // Accept either imageUrl OR imageData (base64)
  if (!imageUrl && !imageData) {
    res.status(400).json({ error: 'Either imageUrl or imageData is required' });
    return;
  }

  const startTime = Date.now();

  try {
    console.log(`🔍 Manual classification requested`);

    // Prepare image for Vision API
    let visionRequest;
    if (imageData) {
      // Use base64 image data
      console.log(`📷 Processing base64 image (${Math.round(imageData.length / 1024)} KB)`);
      visionRequest = {
        image: {
          content: imageData
        }
      };
    } else {
      // Use GCS URL
      console.log(`📷 Processing GCS image: ${imageUrl}`);
      visionRequest = imageUrl;
    }

    // Call Vision API
    const [result] = await visionClient.labelDetection(visionRequest);
    const labels = result.labelAnnotations;

    if (!labels || labels.length === 0) {
      res.status(200).json({
        success: false,
        message: 'No labels detected'
      });
      return;
    }

    // Classify waste
    const classification = classifyWaste(labels);

    if (!classification) {
      res.status(200).json({
        success: false,
        message: 'Could not classify waste',
        labels: labels.map(l => l.description)
      });
      return;
    }

    const processingTime = Date.now() - startTime;

    // If reportId provided, update Firestore
    if (reportId) {
      await db.collection('reports').doc(reportId).update({
        clasificacion: classification.category,
        ai_confidence: classification.confidence,
        ai_processing_time_ms: processingTime,
        ai_classified_at: admin.firestore.FieldValue.serverTimestamp(),
        ai_model_version: 'google-vision-v1',
        updated_at: admin.firestore.FieldValue.serverTimestamp()
      });
    }

    res.status(200).json({
      success: true,
      classification: classification.category,
      confidence: classification.confidence,
      model_version: 'google-vision-v1',
      processingTime,
      labels: labels.slice(0, 10).map(l => ({
        label: l.description,
        score: l.score
      }))
    });

  } catch (error) {
    console.error('❌ Error:', error);
    res.status(500).json({
      success: false,
      error: error.message
    });
  }
});
