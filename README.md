# 🏛️ Attendance & Zone Access System

A comprehensive Flutter web application for managing attendance and zone access across Mauritius constituencies.

## 🌟 Features

### 🔐 **User Management**
- Role-based access control (Admin, Operator, Viewer)
- Multi-constituency user assignments
- Secure authentication system
- User creation and management interface

### 🏛️ **Mauritius Constituencies**
- Complete data for all 21 constituencies
- Electoral population statistics
- Ethnic majority demographics
- Interactive constituency browser

### 📊 **Attendance Tracking**
- QR code scanning
- Manual card entry
- Real-time attendance statistics
- Zone-based access control

### 🎨 **Modern UI**
- Orange theme (#ff6600)
- Responsive design
- Mobile-friendly interface
- Intuitive navigation

## 🚀 **Live Demo**

**URL**: [https://your-project-id.web.app](https://your-project-id.web.app)

**Default Admin Login**:
- Username: `admin`
- Password: `admin123`

## 🛠️ **Technology Stack**

- **Frontend**: Flutter Web
- **Database**: Firebase Firestore
- **Authentication**: Firebase Auth
- **Hosting**: Firebase Hosting
- **State Management**: Provider
- **Local Storage**: Hive (for offline capability)

## 📱 **Supported Platforms**

- ✅ Web (Chrome, Firefox, Safari, Edge)
- ✅ Android
- ✅ iOS
- ✅ macOS
- ✅ Windows
- ✅ Linux

## 🏗️ **Architecture**

```
lib/
├── models/           # Data models (User, Constituency, etc.)
├── services/         # Business logic and API services
├── screens/          # UI screens and pages
├── providers/        # State management
└── main.dart         # App entry point
```

## 🔧 **Development Setup**

### Prerequisites
- Flutter SDK (3.35.1+)
- Dart SDK
- Firebase CLI
- Git

### Installation
```bash
# Clone the repository
git clone https://github.com/yourusername/attendance-system.git
cd attendance-system

# Install dependencies
flutter pub get

# Generate code (Hive adapters)
flutter packages pub run build_runner build

# Run the app
flutter run -d chrome
```

## 🔥 **Firebase Deployment**

### Automatic Deployment (Recommended)
1. Fork this repository
2. Create a Firebase project
3. Add GitHub secrets:
   - `FIREBASE_SERVICE_ACCOUNT`
   - `FIREBASE_PROJECT_ID`
4. Push to main branch → Automatic deployment!

### Manual Deployment
```bash
# Install Firebase CLI
npm install -g firebase-tools

# Login and initialize
firebase login
firebase init

# Build and deploy
flutter build web --release
firebase deploy
```

See [FIREBASE_SETUP.md](FIREBASE_SETUP.md) for detailed instructions.

## 📊 **Data Models**

### Constituencies
- 21 Mauritius constituencies
- Electoral population data
- Ethnic majority information
- Geographic details

### Users
- Role-based permissions
- Multi-constituency assignments
- Secure authentication
- Activity tracking

### Attendance Events
- Real-time tracking
- QR code integration
- Zone-based access
- Offline capability

## 🔒 **Security Features**

- Firebase Authentication
- Firestore security rules
- Role-based access control
- Data validation
- HTTPS encryption

## 🌍 **Mauritius Constituencies**

The system includes complete data for all 21 constituencies:

1. Grand River North West and Port Louis West
2. Port Louis South and Port Louis Central
3. Port Louis Maritime and Port Louis East
4. Port Louis North and Montagne Longue
5. Pamplemousses and Triolet
6. Grand Baie and Poudre d'Or
7. Piton and Riviere du Rempart
8. Quartier Militaire and Moka
9. Flacq and Bon Accueil
10. Montagne Blanche and Grand River South East
11. Vieux Grand Port and Rose Belle
12. Mahebourg and Plaine Magnien
13. Riviere des Anguilles and Souillac
14. Savanne and Black River
15. La Caverne and Phoenix
16. Vacoas and Floreal
17. Curepipe and Midlands
18. Belle Rose and Quatre Bornes
19. Stanley and Rose Hill
20. Beau Bassin and Petite Riviere
21. Rodrigues

## 📈 **Usage Statistics**

- **Total Electoral Population**: 1,056,660
- **Average Constituency Size**: 50,317
- **Largest**: La Caverne and Phoenix (61,231)
- **Smallest**: Rodrigues (32,986)

## 🤝 **Contributing**

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Add tests if applicable
5. Submit a pull request

## 📄 **License**

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## 🆘 **Support**

- 📖 [Documentation](FIREBASE_SETUP.md)
- 🐛 [Report Issues](https://github.com/yourusername/attendance-system/issues)
- 💬 [Discussions](https://github.com/yourusername/attendance-system/discussions)

## 🎯 **Roadmap**

- [ ] Mobile app versions
- [ ] Advanced analytics
- [ ] Export functionality
- [ ] Multi-language support
- [ ] API integrations
- [ ] Offline-first architecture

## 🏆 **Acknowledgments**

- Flutter team for the amazing framework
- Firebase for cloud infrastructure
- Mauritius Electoral Commission for constituency data

---

**Made with ❤️ for Mauritius** 🇲🇺

[![Deploy to Firebase](https://github.com/yourusername/attendance-system/actions/workflows/deploy.yml/badge.svg)](https://github.com/yourusername/attendance-system/actions/workflows/deploy.yml)