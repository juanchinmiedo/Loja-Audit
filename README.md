# Audit App

> Read-only audit dashboard for a beauty salon — monitors every create, edit, and delete action across appointments, clients, and booking requests.

## Stack
Flutter 3 · Dart 3 · Firebase (Firestore + Auth) · Google Sign-In · Material 3 · i18n (es)

## Features
- 🔐 Google Sign-In with Firebase Custom Claims RBAC (admin-only access)
- 📋 Real-time audit log stream from Firestore — ordered by most recent
- 🔍 Full-text search by client name, service, or performer
- 🎛️ Multi-filter panel — by action, category, performer, worker, and date range
- 🃏 Action cards with color-coded icons (create / edit / delete / status / price)
- 📄 Entry detail screen — full event metadata, entity ID, UID, and structured diff

## Structure
```
lib/
├── models/     audit_entry (+ ActionCategory enum, display helpers)
├── services/   auth (Custom Claims check), audit_data (Firestore stream + filters)
├── screens/    login, audit, entry_detail
└── widgets/    audit_entry_card, filter_sheet
```

## Setup
```bash
flutter pub get
flutterfire configure --project=agenda-loja
flutter run
```
> Admin role must be set via Firebase Admin SDK. Shares the `agenda-loja` Firebase project with the main salon app.
