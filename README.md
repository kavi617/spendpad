# 💰 SpendPad

A modern Flutter-based personal expense tracker designed to help users record, organize, analyze, and back up their daily expenses. SpendPad is built with a clean architecture, offline-first storage, and is ready for future cloud and AI enhancements.

---

# 🚀 Overview

SpendPad is a cross-platform mobile application developed using Flutter. The app focuses on simplicity, speed, and privacy by storing all expense data locally while providing secure backup and restore capabilities.

Whether you want to track daily spending, categorize expenses, or visualize your monthly budget, SpendPad provides a lightweight and intuitive experience.

---

# ✨ Features

## Expense Management

- Add new expenses
- Edit existing expenses
- Delete expenses
- View complete expense history
- Store notes for every expense
- Automatic timestamp for each transaction

---

## Category Management

- Create custom categories
- Edit category names
- Delete categories
- Material Design icons for categories
- Icon selection support

Example categories:

- 🍔 Food
- 🚗 Transport
- 🛒 Shopping
- 🏠 Home
- 💊 Health
- 🎬 Entertainment
- ✈ Travel
- 📚 Education
- 📄 Bills
- 📦 Other

---

## Dashboard

- Total spending
- Monthly spending summary
- Category-wise expense tracking
- Recent transactions
- Beautiful Material UI

---

## Local Storage

SpendPad works completely offline using Hive.

Features include:

- Fast NoSQL database
- Offline-first design
- Lightweight storage
- High performance
- No internet required

---

## Backup & Restore

Users can safely back up their data.

### Export

- Export all expenses as JSON
- Share backup using Android Share Sheet
- Save backup anywhere

### Import

- Import JSON backup
- Restore all expenses
- File picker support

---

## Beautiful UI

- Material Design
- Responsive layouts
- Clean navigation
- Mobile-friendly
- Easy-to-use forms

---

# 🏗 Architecture

The application follows a clean modular architecture.

```text
lib/
│
├── models/
│     Expense
│     Category
│
├── services/
│     DatabaseService
│     BackupService
│
├── screens/
│     Home
│     Categories
│     Add Expense
│     Settings
│
├── widgets/
│     Expense Cards
│     Category Widgets
│
└── utils/
      IconHelper
```

---

# 🛠 Technology Stack

| Technology      | Purpose              |
| --------------- | -------------------- |
| Flutter         | Cross-platform UI    |
| Dart            | Programming language |
| Hive            | Local database       |
| Hive Flutter    | Flutter integration  |
| File Picker     | Import backups       |
| Share Plus      | Export backups       |
| Path Provider   | File storage         |
| Material Design | UI Components        |

---

# 📦 Dependencies

- hive
- hive_flutter
- file_picker
- share_plus
- path_provider

---

# Data Model

## Expense

Each expense contains:

- ID
- Amount
- Category
- Note
- Date

---

## Category

Each category contains:

- ID
- Name
- Icon
- Icon Code
- Icon Family

---

# Security

- Local-first storage
- No user account required
- No personal data uploaded
- JSON backups remain under user control
- Android release signing configured using a private keystore

---

# Android Release Build

The project is configured for production APK generation.

Release signing includes:

- Custom JKS keystore
- Release signing configuration
- APK signing verification
- Optimized release builds

Build command:

```bash
flutter clean
flutter pub get
flutter build apk --release
```

---

# Current Features

✅ Expense CRUD

✅ Category CRUD

✅ Hive Database

✅ Backup

✅ Restore

✅ JSON Export

✅ JSON Import

✅ Share Backup

✅ Material Icons

✅ Offline Storage

✅ Android Release APK

✅ Signed Release Build

---

# Future Roadmap

## Version 1.1

- Monthly reports
- Pie charts
- Bar charts
- Search expenses
- Filter by date
- CSV export

---

## Version 1.2

- Google Drive Backup
- OneDrive Backup
- Dropbox Backup
- Cloud Sync

---

## Version 2.0

- AI Spending Insights
- Budget Recommendations
- Spending Predictions
- Voice Expense Entry
- OCR Receipt Scanner
- Natural Language Expense Search

Example:

> "How much did I spend on food this month?"

> "Show shopping expenses from last week."

> "Predict my spending for next month."

---

# Future Enhancements

- Multi-currency support
- Dark mode
- Budget alerts
- Recurring expenses
- Bill reminders
- Family shared accounts
- PIN lock
- Biometric authentication
- PDF reports
- Google Play release

---

# Project Status

**Version:** 1.0.0

**Platform:** Android (Flutter)

**Storage:** Hive (Offline)

**Status:** Stable MVP

---

# Author

**Kavinayan Gopal Senthil**

Built with ❤️ using Flutter.
