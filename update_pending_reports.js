const admin = require('firebase-admin');
const serviceAccount = require('./backend/firebase-service-account.json');

admin.initializeApp({
  credential: admin.credential.cert(serviceAccount)
});

const db = admin.firestore();

async function updatePendingReports() {
  try {
    console.log('🔄 Actualizando reportes con estado "Pendiente"...\n');
    
    const snapshot = await db.collection('reports')
      .where('estado', '==', 'Pendiente')
      .get();
    
    console.log(`📊 Reportes encontrados con estado "Pendiente": ${snapshot.size}\n`);
    
    if (snapshot.empty) {
      console.log('✅ No hay reportes para actualizar');
      return;
    }
    
    const batch = db.batch();
    let count = 0;
    
    snapshot.forEach(doc => {
      console.log(`✏️  Actualizando ${doc.id}: "Pendiente" → "received"`);
      batch.update(doc.ref, {
        estado: 'received',
        updated_at: admin.firestore.FieldValue.serverTimestamp()
      });
      count++;
    });
    
    await batch.commit();
    console.log(`\n✅ ${count} reportes actualizados exitosamente`);
    
    // Verificar los estados finales
    console.log('\n🔍 Verificando estados actuales...');
    const allReports = await db.collection('reports')
      .orderBy('created_at', 'desc')
      .limit(20)
      .get();
    
    const estados = {};
    allReports.forEach(doc => {
      const estado = doc.data().estado || 'sin_estado';
      estados[estado] = (estados[estado] || 0) + 1;
    });
    
    console.log('\n📊 Resumen de estados actuales:');
    Object.entries(estados).forEach(([estado, count]) => {
      console.log(`   "${estado}": ${count} reportes`);
    });
    
  } catch (error) {
    console.error('❌ Error:', error);
  } finally {
    process.exit(0);
  }
}

updatePendingReports();
