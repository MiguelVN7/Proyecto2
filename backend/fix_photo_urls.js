/**
 * Script to fix photo URLs in Firestore after IP change
 * Updates all reports with old backend URLs to use current IP
 */

const admin = require('firebase-admin');
const os = require('os');

// Initialize Firebase Admin using Application Default Credentials
try {
  admin.app(); // Check if already initialized
} catch (error) {
  // Initialize with default credentials (same as backend server)
  admin.initializeApp({
    credential: admin.credential.applicationDefault(),
    projectId: 'ecotrack-app-23a64', // Your Firebase project ID
  });
}

const db = admin.firestore();

// Get current IP address
function getCurrentIP() {
  const interfaces = os.networkInterfaces();
  for (const name of Object.keys(interfaces)) {
    for (const iface of interfaces[name]) {
      // Skip internal and non-IPv4 addresses
      if (iface.family === 'IPv4' && !iface.internal) {
        return iface.address;
      }
    }
  }
  return 'localhost';
}

async function fixPhotoUrls() {
  try {
    const currentIP = getCurrentIP();
    console.log(`🌐 Current IP: ${currentIP}`);
    console.log(`🔄 Updating photo URLs in Firestore...`);

    // Get all reports
    const reportsSnapshot = await db.collection('reports').get();

    if (reportsSnapshot.empty) {
      console.log('📭 No reports found');
      return;
    }

    let updatedCount = 0;
    let skippedCount = 0;

    // Process each report
    for (const doc of reportsSnapshot.docs) {
      const data = doc.data();
      const oldUrl = data.foto_url || '';

      // Check if URL needs updating (has http:// and port 3000)
      if (oldUrl && oldUrl.includes('http://') && oldUrl.includes(':3000')) {
        // Extract report ID from URL (e.g., ECO-XXXXXXXX.jpeg)
        const urlMatch = oldUrl.match(/\/images\/(ECO-[A-F0-9]+\.(jpeg|jpg|png))/i);

        if (urlMatch) {
          const imageFilename = urlMatch[1];
          const newUrl = `http://${currentIP}:3000/images/${imageFilename}`;

          // Only update if URL actually changed
          if (oldUrl !== newUrl) {
            await doc.ref.update({
              foto_url: newUrl,
              updated_at: admin.firestore.FieldValue.serverTimestamp()
            });

            console.log(`✅ Updated ${doc.id}: ${imageFilename}`);
            updatedCount++;
          } else {
            skippedCount++;
          }
        } else {
          console.log(`⚠️  Could not parse URL for ${doc.id}: ${oldUrl}`);
          skippedCount++;
        }
      } else {
        skippedCount++;
      }
    }

    console.log(`\n📊 Summary:`);
    console.log(`   ✅ Updated: ${updatedCount} reports`);
    console.log(`   ⏭️  Skipped: ${skippedCount} reports`);
    console.log(`   📝 Total: ${reportsSnapshot.size} reports`);

  } catch (error) {
    console.error('❌ Error fixing photo URLs:', error);
  } finally {
    process.exit(0);
  }
}

// Run the script
fixPhotoUrls();
