# FitQuest - Professional Fitness Tracker

FitQuest is a comprehensive fitness tracking application built with Flutter and Firebase. It provides users with tools to track workouts, monitor fitness goals, view statistics, and maintain a healthy lifestyle.

## 🚀 Features

### ✅ Complete
- **Welcome Screen**: Beautiful onboarding with sign-in/sign-up options
- **Authentication**: Email/password authentication with Firebase
- **Dashboard**: Home screen with user stats and quick actions
- **Workout Tracking**: Real-time workout tracker with timer, distance, heart rate, and calories
- **Statistics**: Comprehensive charts and progress tracking
- **Goals System**: Set and track fitness goals with progress visualization
- **User Profile**: Profile management and settings

## 🏗️ Architecture

FitQuest follows a clean MVVM architecture with clear separation of concerns:

lib/
├── core/
│ ├── theme/ # App theme and styling
│ └── services/ # Business logic and data services
├── features/
│ ├── auth/ # Authentication features
│ ├── dashboard/ # Home dashboard
│ ├── workout/ # Workout tracking
│ ├── stats/ # Statistics and charts
│ ├── goals/ # Goal management
│ └── profile/ # User profile
└── main.dart # App entry point
text


## 🎨 Design

- **Color Scheme**: Professional blue and white theme
- **Typography**: Clean, modern typography
- **Components**: Reusable UI components
- **Responsive**: Fully responsive design for all screen sizes
- **Animations**: Smooth animations and transitions

## 🔧 Setup Instructions

### 1. Prerequisites
- Flutter SDK (>=3.0.0)
- Firebase account
- IDE (VS Code or Android Studio)

### 2. Firebase Setup
1. Create a new Firebase project
2. Enable Email/Password authentication
3. Set up Firestore database
4. Add your Firebase configuration to:
   - Web: Update `index.html` with your config
   - Mobile: Add `google-services.json` (Android) or `GoogleService-Info.plist` (iOS)

### 3. Installation
```bash
# Clone repository
git clone <repository-url>
cd fitquest

# Install dependencies
flutter pub get

# Run the app
flutter run

📱 Screens

    Welcome Screen: Onboarding with sign-in/sign-up

    Sign In/Register: Secure authentication

    Dashboard: Overview with stats and quick actions

    Workout Tracker: Real-time workout monitoring

    Statistics: Charts and progress tracking

    Goals: Goal setting and tracking

    Profile: User account management

🔒 Security

    Firebase Authentication for secure user management

    Firestore rules for data protection

    Input validation and error handling

    Secure password handling

📄 License

This project is licensed under the MIT License.
🙏 Acknowledgments

    Flutter team for the amazing framework

    Firebase for backend services

    Open-source contributors for various packages

    Design inspiration from modern fitness apps

FitQuest - Your journey to fitness starts here! 🏃‍♂️💪
text


## 📂 **How to Set Up:**

1. **Create the folder structure** as shown above
2. **Copy each file** into its respective folder
3. **Run these commands:**
   ```bash
   flutter pub get
   flutter run