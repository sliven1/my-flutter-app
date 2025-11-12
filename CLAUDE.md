# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

This is a Flutter-based social messaging application with Firebase backend integration. The app includes chat functionality, user profiles, tutor search, weather integration, and audio messaging. It supports both light and dark themes with persistent preferences.

## Build & Development Commands

### Setup
```bash
# Install dependencies
flutter pub get

# Generate launcher icons
flutter pub run flutter_launcher_icons

# Clean build artifacts
flutter clean
```

### Running the App
```bash
# Run on connected device/emulator (debug mode)
flutter run

# Run with specific device
flutter run -d <device_id>

# List available devices
flutter devices

# Hot reload: press 'r' in terminal
# Hot restart: press 'R' in terminal
```

### Building
```bash
# Build APK (Android)
flutter build apk

# Build iOS (requires macOS)
flutter build ios

# Build with release mode
flutter build apk --release
```

### Testing & Analysis
```bash
# Run tests
flutter test

# Analyze code
flutter analyze
```

## Architecture Overview

### State Management
- **Provider Pattern**: Used extensively for state management
- **ThemProvider** (lib/themes/theme_provider.dart): Manages app theme (light/dark mode) with SharedPreferences persistence
- **DatabaseProvider** (lib/service/database_provider.dart): Wraps database operations with ChangeNotifier for reactive UI updates
- **ChatService** (lib/service/chat_service.dart): Extends ChangeNotifier for real-time chat features

### Core Services

#### Authentication Flow (lib/service/)
- **auth_gate.dart**: Entry point that orchestrates authentication state
  - Checks if user is authenticated via Firebase
  - If authenticated but profile incomplete → RegisterProfilePage
  - If authenticated with complete profile → HomePage
  - If not authenticated → LoginOrRegister
- **auth.dart**: Firebase Authentication wrapper
- **login_or_register.dart**: Toggles between login and registration pages

#### Database Layer (lib/service/)
- **databases.dart**: Primary Firestore interface
  - User profile management (CRUD operations)
  - Tutor filtering (role-based queries)
  - City aggregation for search filters
- **database_provider.dart**: Provider wrapper for reactive database operations
- **chat_service.dart**: Chat-specific Firestore operations
  - Message sending (text, image, audio)
  - Real-time message streams
  - User blocking/reporting
  - Unread message tracking

#### File Uploads
- **cloudinary_service.dart**: Handles media uploads to Cloudinary
  - Avatar images → 'avatars' folder
  - Audio messages → 'audio_messages' folder
  - Configured cloud: 'dzyopb2ur', preset: 'Avatar'

### Data Models (lib/models/)
- **user.dart**: UserProfile model with Firestore serialization
  - Fields: uid, name, email, username, birthDate, city, role, bio, avatarUrl
  - Includes copyWith() for immutable updates
- **messenge.dart**: Message model supporting text, image, and audio types
- **weather_model.dart**: Weather data structure

### UI Structure (lib/pages/)

**Authentication Pages**:
- login_page.dart / register_page.dart: Email/password authentication
- register_profile_page.dart: Post-signup profile completion (name, birthDate, city, role)

**Main Pages**:
- **home_page.dart**: Chat list with last message preview and unread counts
- **chat_page.dart**: Individual chat interface with text, image, and audio message support
- **profile_page.dart**: User profile view with bio, avatar, and edit capabilities
- **find_tutor_page.dart**: Search/filter tutors by city and role
- **setting_page.dart**: Theme toggle, account settings, blocked users
- **blocked_user_page.dart**: Manage blocked users

**Auxiliary Pages**:
- song_page.dart: Music player with bundled audio assets
- weather_page.dart: Location-based weather display

### Reusable Components (lib/components/)
- **my_drawer.dart**: Navigation drawer
- **user_tile.dart**: Chat list item with avatar, username, last message, timestamp, unread badge
- **chat_bubble.dart**: Message display with sender/receiver styling
- **audio_player_widget.dart**: Audio message playback control
- **avatar_picker.dart**: Image picker for profile photos
- **user_avatar.dart**: Cached avatar display with fallback
- **my_text_field.dart / input_box.dart**: Custom text inputs
- **my_button.dart**: Styled button component
- **bio_box.dart**: Profile bio display/edit
- **load_animation.dart**: Loading indicators

### Firebase Configuration
- Project ID: flutter-project-eb474
- Configured platforms: Android, iOS, macOS, Web, Windows
- Collections:
  - `Users`: User profiles with subcollection `BlockedUser`
  - `chat_room/{chatRoomId}/messages`: Messages between users
  - `Reports`: User reports

### Theme System (lib/themes/)
- **light_mode.dart / dart_mode.dart**: ColorScheme definitions
- **theme_provider.dart**: Theme switching with SharedPreferences persistence
- User preference saved under key 'isDarkMode'

## Important Implementation Notes

### Chat Room ID Generation
Chat rooms use deterministic IDs by sorting user UIDs alphabetically and joining with underscore:
```dart
List<String> ids = [userId1, userId2];
ids.sort();
String chatRoomId = ids.join('_');
```

### Message Types
Messages support three types (stored in 'type' field):
- 'text': Plain text messages
- 'image': Cloudinary URLs stored in 'message' field
- 'audio': Cloudinary audio URLs stored in 'message' field

### Audio Session
App configures AudioSession at startup (main.dart) for music playback support using flutter_sound and audioplayers packages.

### Permission Requirements
The app requires permissions for:
- Location (weather feature)
- Camera/Photo Library (avatars, image messages)
- Microphone (audio messages)
- Storage (file access)

Handled via permission_handler package.

### Known Issues
- chat_service.dart line 174: Typo in markMessagesAsRead() - sorts [userID1, userID1] instead of [userID1, userID2]
- chat_service.dart line 161: Collection name mismatch in getUnreadCount() - queries "message" instead of "messages"
