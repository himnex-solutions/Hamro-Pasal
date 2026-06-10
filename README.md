# Smart Saoji — Setup & Development Guide

## 🚀 Prerequisites

- Flutter SDK ≥ 3.3.0 (run `flutter --version` to check)
- Dart SDK ≥ 3.3.0
- Supabase account at [supabase.com](https://supabase.com)
- Android Studio / Xcode (for mobile builds)

---

## 1. Clone & Install Dependencies

```bash
git clone <your-repo>
cd "Smart Saoji"
flutter pub get
```

---

## 2. Configure Supabase

### 2a. Create Supabase Project
1. Go to [app.supabase.com](https://app.supabase.com) → New Project
2. Note your **Project URL** and **anon key** from Settings → API

### 2b. Update credentials
Edit `lib/core/constants/supabase_constants.dart`:
```dart
static const String supabaseUrl  = 'https://YOUR_PROJECT_ID.supabase.co';
static const String supabaseAnonKey = 'YOUR_ANON_KEY';
```

### 2c. Run the SQL Schema
1. In Supabase Dashboard → SQL Editor
2. Paste the entire contents of `supabase/schema.sql`
3. Click **Run**

### 2d. Create Storage Buckets
In Supabase Dashboard → Storage → New Bucket:
| Bucket Name      | Public |
|-----------------|--------|
| business-logos  | ✅ Yes |
| product-images  | ✅ Yes |
| receipt-images  | ❌ No  |

---

## 3. Generate Isar Code

Run the code generator for local DB schemas:

```bash
flutter pub run build_runner build --delete-conflicting-outputs
```

---

## 4. Platform Setup

### Android
- Minimum SDK: 21 (Android 5.0+)
- AndroidManifest.xml already configured ✅

### iOS
Add to `ios/Runner/Info.plist`:
```xml
<key>NSCameraUsageDescription</key>
<string>Camera access for scanning barcodes and taking receipts</string>
<key>NSPhotoLibraryUsageDescription</key>
<string>Photo library access for product images and receipts</string>
```

### Windows Desktop
```bash
flutter config --enable-windows-desktop
```

### macOS Desktop
```bash
flutter config --enable-macos-desktop
```
Add to `macos/Runner/DebugProfile.entitlements` and `Release.entitlements`:
```xml
<key>com.apple.security.network.client</key>
<true/>
```

### Web
No extra config required. Supabase auth redirect URL:
`http://localhost:PORT` (for dev) or your production URL.

### Linux
```bash
flutter config --enable-linux-desktop
sudo apt-get install libsecret-1-dev libjsoncpp-dev
```

---

## 5. Run the App

```bash
# Android / iOS
flutter run

# Web
flutter run -d chrome

# Windows
flutter run -d windows

# macOS
flutter run -d macos
```

---

## 6. Supabase Auth Configuration

In Supabase Dashboard → Authentication → Settings:
- **Site URL**: `http://localhost:PORT` (dev) or your production URL
- **Redirect URLs**: Add `io.supabase.smartsaoji://login-callback/`
- **Google OAuth**: Enable in Authentication → Providers → Google
  - Add your Google Client ID and Secret

---

## 7. First Time Setup Flow

1. Open the app → Splash screen
2. Sign up with email/password
3. Business setup screen → Enter business details
4. **14-day free trial starts automatically** 🎉
5. Dashboard is ready to use

---

## 8. Project Structure

```
lib/
├── core/
│   ├── constants/       # App & Supabase constants
│   ├── local/schemas/   # Isar offline DB schemas
│   ├── router/          # GoRouter navigation
│   ├── services/        # LocalDB, Notification, Sync
│   ├── theme/           # Light/dark theme
│   └── widgets/         # Shared widgets
├── features/
│   ├── auth/            # Login, signup, business setup
│   ├── dashboard/       # Home dashboard
│   ├── parties/         # Customers & suppliers
│   ├── inventory/       # Products & stock
│   ├── transactions/    # Sales, purchases
│   ├── invoices/        # Invoice management
│   ├── expenses/        # Expense tracking
│   ├── reports/         # Business reports
│   ├── staff/           # Staff & roles
│   ├── accounts/        # Bank & cash accounts
│   ├── subscription/    # Trial & subscription
│   └── settings/        # App settings
└── main.dart
supabase/
└── schema.sql           # Complete DB schema
```

---

## 9. Subscription Plans (Default)

| Plan    | Price      | Duration |
|---------|-----------|----------|
| Free Trial | Free   | 14 days  |
| Monthly | Rs. 499  | 30 days  |
| Yearly  | Rs. 4,499 | 365 days |

---

## 10. Payment Integration (Khalti / eSewa)

Payment integration is currently a **placeholder**. To integrate:

### Khalti
1. Get API keys from [khalti.com/developers](https://khalti.com/developers/)
2. Add `khalti_flutter` package to `pubspec.yaml`
3. Implement in `subscription_screen.dart`

### eSewa
1. Register at [developer.esewa.com.np](https://developer.esewa.com.np)
2. Implement eSewa SDK in the subscription payment flow

---

## 11. Admin Subscription Management

Use the Supabase Dashboard → Table Editor → `subscriptions` to:
- Manually activate a subscription: Set `status = 'active'`
- Extend trial: Update `trial_end_date`
- Cancel: Set `status = 'cancelled'`

Or create a Supabase Edge Function for admin operations.

---

## 12. Known Issues / TODO

- [ ] Generate Isar `.g.dart` files via `build_runner`
- [ ] Implement full invoice PDF generation
- [ ] Implement Khalti/eSewa payment
- [ ] Add barcode scanner (mobile_scanner)
- [ ] Add Excel export (excel package)
- [ ] Implement staff invitation via email
- [ ] Add Nepali language (l10n)
- [ ] Implement push notifications (FCM)

---

## License

MIT License — Created for small businesses in Nepal 🇳🇵
