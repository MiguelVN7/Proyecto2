const admin = require('firebase-admin');
const serviceAccount = require('./backend/firebase-service-account.json');

admin.initializeApp({
  credential: admin.credential.cert(serviceAccount)
});

const db = admin.firestore();

async function checkReports() {
  try {
    console.log('🔍 Consultando reportes...\n');
    
    const snapshot = await db.collection('reports')
      .orderBy('created_at', 'desc')
      .limit(10)
      .get();
    
    console.log(`📊 Total de reportes encontrados: ${snapshot.size}\n`);
    
    if (snapshot.empty) {
      console.log('❌ No se encontraron reportes');
      return;
    }
    
    const estados = {};
    
    snapshot.forEach(doc => {
      const data = doc.data();
      const estado = data.estado || 'sin_estado';
      estados[estado] = (estados[estado] || 0) + 1;
      
      console.log(`📄 Reporte: ${doc.id}`);
      console.log(`   Estado: "${estado}"`);
      console.log(`   Ubicación: ${data.ubicacion || 'N/A'}`);
      console.log(`   Clasificación: ${data.clasificacion || 'N/A'}`);
      console.log(`   Usuario: ${data.user_id || 'N/A'}`);
      console.log('');
    });
    
    console.log('\n📊 Resumen de estados:');
    Object.entries(estados).forEach(([estado, count]) => {
      console.log(`   "${estado}": ${count} reportes`);
    });
    
  } catch (error) {
    console.error('❌ Error:', error);
  } finally {
    process.exit(0);
  }
}

checkReports();
