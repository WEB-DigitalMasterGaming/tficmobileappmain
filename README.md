# TFIC Mobile App

The official mobile app for The Frontier Initiative Corporation (TFIC), built with Flutter. This app allows members to view upcoming events, RSVP, and manage their organization presence directly from their mobile device.

## 🚀 Features

- View and RSVP to TFIC events
- Secure login with persistent session
- Real-time updates synced with the TFIC backend
- Push notifications for new or updated events (Firebase Messaging)
- Markdown support for rich event descriptions
- Local secure storage for user credentials
- Android release signing enabled

## 🧱 Project Structure

## 🛠️ Setup

### Prerequisites

- Flutter 3.7.2+
- Android Studio or VS Code
- A valid keystore file for release signing

### Clone & Install

```bash
git clone https://github.com/your-username/tficmobileapp.git
cd tficmobileappmain
flutter pub get
flutter clean
flutter pub get
flutter build appbundle --release
```

### key.properties format

```
storePassword=yourPassword
keyPassword=yourPassword
keyAlias=upload
storeFile=C:\path\to\tfic-upload-keystore.jks
```

## 🔔 Notifications

This app uses:

- `firebase_messaging` for push notifications
- `flutter_local_notifications` for foreground notification display

Ensure your Firebase project is correctly configured and `google-services.json` is placed in `android/app/`.

## 👨‍💻 Maintainer

Maintained by @digitalmaster for the TFIC Star Citizen community.

## 📜 License

MIT — do what you want, just give credit.
---

Let me know if you want to include screenshots, deep links, or Firebase setup instructions.
