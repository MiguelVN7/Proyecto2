# Firebase Cloud Messaging (FCM) Setup Guide for EcoTrack

This guide walks you through setting up Firebase Cloud Messaging for push notifications in the EcoTrack application.

## 🔥 Firebase Project Setup

### 1. Create Firebase Project
1. Go to [Firebase Console](https://console.firebase.google.com/)
2. Click "Create a project" or "Add project"
3. Enter project name: `ecotrack-notifications`
4. Enable Google Analytics (optional)
5. Create project

### 2. Add Android App
1. In Firebase Console, click "Add app" → Android
2. Enter package name: `com.example.eco_track` (or your actual package name)
3. Enter app nickname: `EcoTrack Android`
4. Download `google-services.json`
5. Place it in `frontend/android/app/google-services.json`

### 3. Add iOS App (if needed)
1. In Firebase Console, click "Add app" → iOS
2. Enter bundle ID: `com.example.ecoTrack`
3. Enter app nickname: `EcoTrack iOS`
4. Download `GoogleService-Info.plist`
5. Place it in `frontend/ios/Runner/GoogleService-Info.plist`

## 🔧 Backend Configuration

### 1. Generate Service Account Key
1. In Firebase Console → Project Settings → Service Accounts
2. Click "Generate new private key"
3. Save the JSON file as `firebase-service-account.json`
4. Place it in the `backend/` directory
5. **Important**: Add this file to `.gitignore` for security

### 2. Install Dependencies
```bash
cd backend
npm install firebase-admin
```

## 📱 Frontend Configuration

### 1. Install Dependencies
```bash
cd frontend
flutter pub get
```

### 2. Android Configuration
Add the following to `android/build.gradle`:
```gradle
buildscript {
    dependencies {
        classpath 'com.google.gms:google-services:4.3.15'
    }
}
```

Add to `android/app/build.gradle`:
```gradle
apply plugin: 'com.google.gms.google-services'

dependencies {
    implementation 'com.google.firebase:firebase-messaging:23.1.2'
}
```

### 3. iOS Configuration (if needed)
Add GoogleService-Info.plist to your iOS project in Xcode.

## 🚀 Testing FCM Notifications

### 1. Start the Backend Server
```bash
cd backend
node server.js
```

### 2. Run the Flutter App
```bash
cd frontend
flutter run
```

### 3. Test Notification Flow

#### A. Register FCM Token
The app automatically registers the FCM token when it starts. Check the console logs for:
```
📱 FCM Token obtained: [token]
📤 Registering FCM token with backend...
✅ FCM token registered successfully with backend
```

#### B. Test Manual Notification
Send a test notification using curl:
```bash
curl -X POST http://localhost:3000/api/fcm/test \
  -H "Content-Type: application/json" \
  -d '{
    "title": "Test Notification",
    "body": "Testing FCM from EcoTrack backend"
  }'
```

#### C. Test Report Status Notifications
1. Submit a report through the app
2. Update the report status:
```bash
curl -X PATCH http://localhost:3000/api/reports/ECO-[REPORT_ID]/status \
  -H "Content-Type: application/json" \
  -d '{
    "status": "received"
  }'
```

### 4. Check FCM Statistics
```bash
curl http://localhost:3000/api/fcm/stats
```

## 📋 Notification Types

The system sends notifications for these report status changes:

| Status | Notification Title | Description |
|--------|-------------------|-------------|
| `received` | ✅ Report Received | Report has been received and is being processed |
| `en_route` | 🚛 Collection Started | Collection team is on route to location |
| `collected` | ♻️ Waste Collected | Waste has been successfully collected |
| `completed` | 🎉 Report Completed | Environmental report has been completed |

## 🔒 Security Best Practices

### 1. Environment Variables
For production, use environment variables instead of the service account file:
```bash
export FIREBASE_PROJECT_ID="your-project-id"
export GOOGLE_APPLICATION_CREDENTIALS="/path/to/service-account.json"
```

### 2. API Key Security
- Keep `google-services.json` and `GoogleService-Info.plist` secure
- Never commit service account keys to version control
- Use Firebase App Check for additional security

### 3. Token Management
- Tokens are automatically refreshed by the FCM SDK
- Implement token cleanup for inactive devices
- Consider storing tokens in a persistent database for production

## 🐛 Troubleshooting

### Common Issues

1. **No notifications received**
   - Check if notifications are enabled in device settings
   - Verify Firebase project configuration
   - Check backend logs for FCM errors

2. **Invalid token errors**
   - Tokens are automatically cleaned up when invalid
   - Check device time/date settings
   - Verify Firebase project ID matches

3. **Background notifications not working**
   - Ensure app has background execution permissions
   - Check battery optimization settings
   - Verify background message handler is registered

### Debug Commands

Check FCM service status:
```bash
curl http://localhost:3000/api/fcm/stats
```

View backend logs for FCM:
```bash
# In backend directory
tail -f backend.log | grep FCM
```

## 📚 Additional Resources

- [Firebase Cloud Messaging Documentation](https://firebase.google.com/docs/cloud-messaging)
- [FlutterFire FCM Plugin](https://firebase.flutter.dev/docs/messaging/overview)
- [Firebase Admin SDK](https://firebase.google.com/docs/admin/setup)

## 🔄 Next Steps

After setting up FCM:

1. **Test on real devices** - Notifications work differently on physical devices vs simulators
2. **Implement user preferences** - Allow users to customize notification settings
3. **Add notification history** - Store and display notification history in the app
4. **Implement topics** - Use FCM topics for different types of notifications
5. **Analytics integration** - Track notification engagement metrics

---

## 📝 Implementation Summary

### ✅ What's Implemented

- **Frontend FCM Service** (`lib/services/fcm_service.dart`)
  - Token registration and management
  - Foreground/background notification handling
  - Local notification display
  - Navigation handling for notification taps

- **Backend FCM Integration** (`backend/fcm_service.js`)
  - Firebase Admin SDK integration
  - Token registration endpoints
  - Automatic status notifications
  - Test notification capabilities

- **Report Integration**
  - Automatic notifications on status changes
  - Notification triggers in report submission
  - Status update notifications in PATCH endpoint

- **Android Configuration**
  - FCM permissions and services
  - Notification channels
  - Firebase manifest configuration

### 🎯 Notification Flow

1. **User submits report** → `received` notification sent
2. **Admin updates status to "en_route"** → `collection started` notification
3. **Admin updates status to "collected"** → `waste collected` notification
4. **Admin updates status to "completed"** → `report completed` notification

Each notification includes:
- Appropriate emoji and title
- Descriptive message
- Report ID for tracking
- Deep linking to reports section

The implementation provides a complete, production-ready FCM solution for the EcoTrack application with proper error handling, security considerations, and user experience features.