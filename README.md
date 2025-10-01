# Pivot - Academic Management System

A comprehensive Flutter-based academic management system for educational institutions, featuring announcements, task management, schedules, and administrative tools.

## 🎯 Project Overview

Pivot is a full-featured academic platform built with Flutter and Firebase, designed to streamline communication and management between students, professors, and administrators.

## ✨ Key Features

- **📢 Announcements**: Real-time announcement system with department filtering
- **✅ Task Management**: Comprehensive task tracking and assignment system
- **📅 Schedule Management**: Class schedules and calendar integration
- **👥 User Profiles**: Detailed profiles for students, professors, and administrators
- **📚 Subject Management**: Subject organization and material sharing
- **🔐 Role-Based Access**: Multi-level permission system (Student, Professor, Admin, Super Admin)
- **📊 Analytics**: Administrative analytics and reporting
- **🔔 Notifications**: Real-time push notifications via Firebase Cloud Messaging

## 🏗️ Architecture

### State Management

- **Riverpod**: Modern state management (Migration completed October 1, 2025)
- **Clean Architecture**: Service → Repository → Provider pattern
- **Feature-First Structure**: Organized by features for scalability

### Backend Services

- **Firebase Authentication**: Secure user authentication
- **Cloud Firestore**: Real-time database
- **Firebase Storage**: File and image storage
- **Firebase Cloud Messaging**: Push notifications
- **Firebase App Check**: Security and abuse prevention

## 📁 Project Structure

```
lib/
├── features/              # Feature-based modules
│   ├── announcements/     # Announcement system
│   ├── auth/              # Authentication
│   ├── profile/           # User profiles
│   ├── tasks/             # Task management
│   ├── schedule/          # Schedule system
│   ├── administration/    # Admin features
│   └── ...
├── models/                # Data models
├── services/              # Backend services
├── providers/             # Legacy providers (being phased out)
└── widgets/               # Shared UI components
```

## 🚀 Getting Started

### Prerequisites

- Flutter SDK (latest stable version)
- Firebase account and project setup
- Android Studio / VS Code with Flutter extensions

### Installation

1. Clone the repository:

```bash
git clone <repository-url>
cd 02-Pivot
```

2. Install dependencies:

```bash
flutter pub get
```

3. Configure Firebase:

   - Add your `google-services.json` to `android/app/`
   - Update `firebase_options.dart` with your project configuration

4. Run the app:

```bash
flutter run
```

## 📊 Migration Status

✅ **Riverpod Migration: 100% Complete** (as of October 1, 2025)

- 46/46 files migrated
- All features tested and working
- Legacy provider bridges in place for gradual cleanup

See `RIVERPOD_MIGRATION_PLAN.md` for detailed migration documentation.

## 📚 Documentation

- `RIVERPOD_MIGRATION_PLAN.md` - Comprehensive migration guide
- `PRODUCTION_CHECKLIST.md` - Production deployment checklist
- `PLAY_STORE_UPLOAD_CHECKLIST.md` - Play Store submission guide
- `FIREBASE_OPTIMIZATION_RECOMMENDATIONS.md` - Firebase optimization tips
- `LOCAL_NOTIFICATION_SYSTEM_DOCUMENTATION.md` - Notification system docs

## 🔒 Security & Privacy

- All user data encrypted in transit and at rest
- Firebase Security Rules implemented
- App Check enabled for abuse prevention
- See `PRIVACY_POLICY.md` for detailed privacy information

## 🛠️ Development

### Code Style

- Follow Flutter/Dart style guidelines
- Use Riverpod for state management
- Maintain feature-first folder structure
- Write comprehensive comments for complex logic

### Testing

```bash
flutter test
```

### Building for Production

**Android:**

```bash
flutter build apk --release
# or
flutter build appbundle --release
```

## 📱 Supported Platforms

- ✅ Android
- ✅ iOS (configured but not tested)
- ⚠️ Web (partial support)

## 🤝 Contributing

1. Follow the established architecture patterns
2. Use Riverpod for new features
3. Maintain code documentation
4. Test thoroughly before submitting

## 📄 License

[Add your license information here]

## 👥 Team

[Add team/contact information here]

---

**Last Updated**: October 1, 2025
**Version**: 1.0.0
**Status**: Production Ready ✅
