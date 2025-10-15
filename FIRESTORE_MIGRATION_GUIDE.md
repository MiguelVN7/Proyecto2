# Firestore Migration Guide for EcoTrack

This guide walks you through the complete migration from SQLite to Firestore for the EcoTrack application.

## 🔥 Overview

The migration replaces the local SQLite database with Google Cloud Firestore, providing:
- **Real-time data synchronization** across all devices
- **Offline support** with automatic sync when online
- **Scalable cloud infrastructure**
- **Built-in security rules**
- **Seamless integration** with existing Firebase services (FCM)

## 📊 Database Schema Migration

### Old SQLite Schema
```sql
CREATE TABLE reports (
  id TEXT PRIMARY KEY,
  timestamp TEXT NOT NULL,
  latitude REAL NOT NULL,
  longitude REAL NOT NULL,
  accuracy REAL DEFAULT 0,
  classification TEXT NOT NULL,
  device_info TEXT,
  image_path TEXT,
  status TEXT DEFAULT 'received',
  created_at DATETIME DEFAULT CURRENT_TIMESTAMP
);
```

### New Firestore Structure
```javascript
// Collection: reports
// Document ID: ECO-XXXXXXXX
{
  id: "ECO-12345678",
  foto_url: "https://storage.googleapis.com/...",
  ubicacion: "Calle 1 #2-3",
  clasificacion: "Plástico",
  estado: "Recibido",
  prioridad: "Media",
  tipo_residuo: "Plástico",
  location: {
    latitude: 6.244203,
    longitude: -75.581212,
    accuracy: 10.0
  },
  created_at: Timestamp,
  updated_at: Timestamp,
  device_info: "Android 14",
  user_id: "anonymous_user_123"
}
```

## 🚀 Implementation Steps

### 1. Frontend Changes

#### Updated Model (`lib/models/reporte.dart`)
- Added Firestore serialization methods (`toFirestore()`, `fromFirestore()`)
- Added timestamp fields (`createdAt`, `updatedAt`)
- Added user authentication support
- Factory constructors for different creation scenarios

#### New Firestore Service (`lib/services/firestore_service.dart`)
- Real-time data streams with `StreamBuilder`
- Offline persistence enabled
- Image upload to Firebase Storage
- User authentication integration
- Geographic queries support

#### Real-time Reports Screen (`lib/screens/firestore_reports_screen.dart`)
- Live updates without manual refresh
- Status-based filtering
- Real-time sync indicators
- Error handling and retry logic

### 2. Backend Changes

#### New Firestore Service (`backend/firestore_service.js`)
- Firebase Admin SDK integration
- Replaces SQLite operations
- Maintains same API interface
- Enhanced error handling
- FCM token management in Firestore

#### Updated Server (`backend/server.js`)
- All database calls now use Firestore
- Maintains backward compatibility
- Enhanced logging and monitoring

## 🔧 Setup Instructions

### 1. Firebase Project Setup
```bash
# If you haven't already for FCM:
# 1. Go to Firebase Console (https://console.firebase.google.com/)
# 2. Select your existing project or create new one
# 3. Enable Firestore Database
# 4. Set up security rules (see below)
```

### 2. Firestore Security Rules
```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    // Reports collection
    match /reports/{reportId} {
      // Allow read for all authenticated users
      allow read: if request.auth != null;

      // Allow create for authenticated users
      allow create: if request.auth != null
        && request.auth.uid == resource.data.user_id;

      // Allow update for report owner or admin
      allow update: if request.auth != null
        && (request.auth.uid == resource.data.user_id || isAdmin());

      // Allow delete for admin only
      allow delete: if request.auth != null && isAdmin();
    }

    // FCM tokens collection
    match /fcm_tokens/{tokenId} {
      allow read, write: if request.auth != null
        && request.auth.uid == resource.data.user_id;
    }

    // Helper functions
    function isAdmin() {
      return request.auth.token.admin == true;
    }
  }
}
```

### 3. Install Dependencies
```bash
# Frontend (if not already installed)
cd frontend
flutter pub get

# Backend (if not already installed)
cd backend
npm install firebase-admin
```

### 4. Enable Firestore in Firebase Console
1. Go to Firebase Console → Firestore Database
2. Click "Create database"
3. Choose "Start in production mode" (we'll add rules)
4. Select your preferred location
5. Apply the security rules above

## 📱 Key Features

### Real-time Updates
- Reports appear instantly across all devices
- Status changes sync in real-time
- Automatic conflict resolution

### Offline Support
- Data cached locally when offline
- Changes queued and synced when online
- Seamless offline/online transitions

### Enhanced Security
- User-based data access control
- Server-side validation rules
- Encrypted data transmission

### Improved Performance
- Efficient queries with indexing
- Pagination for large datasets
- Optimistic updates

## 🔄 Migration Process

### For New Installations
1. Follow setup instructions above
2. Deploy updated code
3. App will start using Firestore immediately

### For Existing Installations with Data
1. **Backup existing SQLite data**
   ```bash
   cd backend
   cp ecotrack.db ecotrack_backup_$(date +%Y%m%d).db
   ```

2. **Run data migration script** (create this script):
   ```javascript
   // migration_script.js
   const sqlite = require('better-sqlite3');
   const firestoreService = require('./firestore_service');

   async function migrate() {
     const db = sqlite('./ecotrack.db');
     await firestoreService.initialize();

     const reports = db.prepare('SELECT * FROM reports').all();

     for (const report of reports) {
       const firestoreReport = {
         id: report.id,
         timestamp: report.timestamp,
         location: {
           latitude: report.latitude,
           longitude: report.longitude,
           accuracy: report.accuracy
         },
         classification: report.classification,
         device_info: report.device_info,
         image_path: report.image_path,
         status: report.status
       };

       await firestoreService.insertReport(firestoreReport);
       console.log(`Migrated report: ${report.id}`);
     }

     console.log(`Migration complete: ${reports.length} reports`);
   }

   migrate();
   ```

3. **Deploy updated application**
4. **Verify data integrity**
5. **Decommission SQLite database**

## 🧪 Testing

### 1. Test Real-time Updates
```bash
# Terminal 1: Start backend
cd backend
node server.js

# Terminal 2: Run Flutter app
cd frontend
flutter run

# Test: Create report on one device, verify it appears on another
```

### 2. Test Offline Functionality
1. Disable internet on device
2. Create/modify reports
3. Re-enable internet
4. Verify data syncs automatically

### 3. Test Backend Integration
```bash
# Test report creation
curl -X POST http://localhost:3000/api/reports \
  -H "Content-Type: application/json" \
  -d '{
    "photo": "data:image/jpeg;base64,...",
    "latitude": 6.244203,
    "longitude": -75.581212,
    "accuracy": 10,
    "classification": "Plástico",
    "timestamp": "2024-01-01T00:00:00Z",
    "device_info": "Test Device"
  }'

# Test status update
curl -X PATCH http://localhost:3000/api/reports/ECO-12345678/status \
  -H "Content-Type: application/json" \
  -d '{"status": "collected"}'
```

## 📊 Monitoring and Analytics

### Firestore Usage Monitoring
```bash
# View Firestore usage in Firebase Console
# → Firestore → Usage tab
# Monitor: Reads, Writes, Deletes, Storage
```

### Application Monitoring
```javascript
// Add to your Firestore service
console.log('📊 Firestore operation:', {
  operation: 'read',
  collection: 'reports',
  count: snapshot.docs.length,
  timestamp: new Date().toISOString()
});
```

## 🔒 Security Best Practices

### 1. Authentication
- Enable Firebase Authentication
- Use anonymous auth for development
- Implement proper user management for production

### 2. Security Rules
- Test rules in Firebase Console simulator
- Use least-privilege principle
- Regular security rule audits

### 3. Data Validation
- Server-side validation in Cloud Functions
- Client-side validation for UX
- Input sanitization

## 🚨 Troubleshooting

### Common Issues

1. **"Permission denied" errors**
   - Check Firestore security rules
   - Verify user authentication
   - Check document ownership

2. **Offline data not syncing**
   - Verify internet connectivity
   - Check Firestore persistence settings
   - Monitor Firebase Console for errors

3. **Performance issues**
   - Create composite indexes for complex queries
   - Implement pagination
   - Use data denormalization where appropriate

### Debug Commands

```bash
# Check Firestore connection
curl http://localhost:3000/api/stats

# View detailed logs
firebase functions:log --only firestore

# Monitor real-time operations
# Use Firebase Console → Firestore → Usage
```

## 📈 Performance Optimizations

### Indexes
Create indexes for common queries:
```javascript
// Auto-created indexes needed:
// - Collection: reports, Fields: created_at (Descending)
// - Collection: reports, Fields: estado, created_at (Descending)
// - Collection: reports, Fields: user_id, created_at (Descending)
```

### Caching Strategy
```javascript
// Frontend caching
const cachedReports = await _firestore
  .collection('reports')
  .get(GetOptions(source: Source.cache));
```

## 🎯 Benefits Achieved

### Technical Benefits
- ✅ Real-time data synchronization
- ✅ Offline-first architecture
- ✅ Automatic scaling
- ✅ Built-in security
- ✅ Integrated with FCM notifications

### User Experience Benefits
- ✅ Instant updates across devices
- ✅ Works offline
- ✅ Faster load times
- ✅ Consistent data everywhere
- ✅ Push notifications with real-time data

### Developer Benefits
- ✅ No database maintenance
- ✅ Built-in analytics
- ✅ Simplified backend code
- ✅ Better error handling
- ✅ Comprehensive monitoring

---

## 🔮 Next Steps

After successful migration:

1. **Implement advanced queries** using Firestore's powerful query capabilities
2. **Add Cloud Functions** for server-side business logic
3. **Implement user profiles** with Firebase Authentication
4. **Add data analytics** with Firebase Analytics
5. **Scale globally** with Firestore's multi-region support

The migration to Firestore provides a solid foundation for scaling the EcoTrack application while maintaining excellent performance and user experience.