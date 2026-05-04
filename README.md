# 🏪 Hamro Pasal
### Smart POS & Business Management App for Nepal

> A professional, cross-platform Flutter + Supabase application for small retail shops in Nepal.  
> Supports **Android · iOS · Web** with Nepali & English language support.

---

## 📱 Screenshots Preview

| Splash | Login | Dashboard | POS | Inventory | Customers |
|--------|-------|-----------|-----|-----------|-----------|
| Branded gradient | Email/Google auth | Stats + Quick menu | Product grid + Cart | Stock management | Ledger tracking |

---

## 🗂️ Project Structure

```
hamro_pasal/
├── lib/
│   ├── main.dart                      # App entry point
│   ├── core/
│   │   ├── constants/
│   │   │   └── app_constants.dart     # All app-wide constants
│   │   ├── theme/
│   │   │   └── app_theme.dart         # Light/dark theme + AppColors
│   │   ├── router/
│   │   │   └── app_router.dart        # GoRouter + ShellRoute
│   │   ├── providers/
│   │   │   └── theme_provider.dart    # ThemeMode state
│   │   └── services/
│   │       └── supabase_service.dart  # Centralized Supabase CRUD
│   ├── features/
│   │   ├── auth/
│   │   │   ├── models/user_profile.dart
│   │   │   ├── providers/auth_provider.dart
│   │   │   └── screens/
│   │   │       ├── splash_screen.dart
│   │   │       ├── login_screen.dart
│   │   │       ├── signup_screen.dart
│   │   │       └── profile_setup_screen.dart
│   │   ├── subscription/
│   │   │   ├── models/subscription.dart
│   │   │   ├── providers/subscription_provider.dart
│   │   │   └── screens/subscription_screen.dart
│   │   ├── dashboard/
│   │   │   └── screens/dashboard_screen.dart
│   │   ├── pos/
│   │   │   ├── models/sale.dart
│   │   │   └── screens/
│   │   │       ├── pos_screen.dart
│   │   │       └── receipt_screen.dart
│   │   ├── inventory/
│   │   │   ├── models/product.dart
│   │   │   └── screens/
│   │   │       ├── inventory_screen.dart
│   │   │       └── add_edit_product_screen.dart
│   │   ├── customers/
│   │   │   ├── models/customer.dart
│   │   │   └── screens/
│   │   │       ├── customer_list_screen.dart
│   │   │       └── customer_detail_screen.dart
│   │   ├── reports/
│   │   │   └── screens/reports_screen.dart
│   │   ├── expenses/
│   │   │   ├── models/expense.dart
│   │   │   └── screens/expense_screen.dart
│   │   ├── suppliers/
│   │   │   ├── models/supplier.dart
│   │   │   └── screens/supplier_screen.dart
│   │   └── settings/
│   │       └── screens/settings_screen.dart
│   ├── shared/
│   │   └── widgets/
│   │       ├── app_button.dart
│   │       ├── app_text_field.dart
│   │       ├── empty_state.dart
│   │       ├── loading_overlay.dart
│   │       └── shimmer_card.dart
│   └── l10n/
│       ├── app_en.arb                 # English strings
│       ├── app_ne.arb                 # Nepali strings
│       └── app_localizations.dart    # Generated (run flutter gen-l10n)
├── supabase/
│   └── schema.sql                    # Full DB schema + RLS + triggers
├── web/
│   └── index.html                    # Web splash + Flutter loader
├── android/
│   └── app/src/main/
│       └── AndroidManifest.xml       # Deep links + permissions
├── pubspec.yaml                      # All dependencies
├── analysis_options.yaml             # Linting rules
├── l10n.yaml                         # i18n config
├── .gitignore
└── .env.example                      # Environment variable template
```

---

## 🚀 Quick Start

### 1. Prerequisites
- Flutter SDK ≥ 3.3.0
- Dart SDK ≥ 3.3.0
- A [Supabase](https://supabase.com) project

### 2. Clone & Setup

```bash
# Clone the repository
git clone https://github.com/yourname/hamro-pasal.git
cd hamro-pasal

# Copy environment template
cp .env.example .env
# Edit .env with your Supabase credentials
```

### 3. Configure Supabase

1. Create a new project at [supabase.com](https://supabase.com)
2. Open the **SQL Editor** in your Supabase dashboard
3. Run the entire contents of `supabase/schema.sql`
4. Copy your **Project URL** and **anon key** into `lib/core/constants/app_constants.dart`

```dart
// lib/core/constants/app_constants.dart
static const String supabaseUrl = 'https://your-project.supabase.co';
static const String supabaseAnonKey = 'your-anon-key';
```

> **Security**: Use `--dart-define` flags in production:
> ```bash
> flutter run --dart-define=SUPABASE_URL=https://xxx.supabase.co \
>             --dart-define=SUPABASE_ANON_KEY=your-key
> ```

### 4. Install Dependencies

```bash
flutter pub get
flutter gen-l10n        # Generate localizations
```

### 5. Run the App

```bash
# Android
flutter run

# Web
flutter run -d chrome

# iOS
flutter run -d ios
```

---

## 🗄️ Database Schema

| Table | Purpose |
|-------|---------|
| `profiles` | Shop info (name, PAN, address) |
| `subscriptions` | Plan type, dates, payment |
| `products` | Inventory with stock levels |
| `customers` | Customer list |
| `sales` | Sale headers with bill number |
| `sale_items` | Line items per sale |
| `ledger_transactions` | Credit/payment per customer |
| `expenses` | Shop expenses by category |
| `suppliers` | Supplier directory |
| `purchase_entries` | Stock purchase records |
| `purchase_items` | Items per purchase |
| `staff_users` | Owner + role-based staff |
| `branches` | Multi-branch support (Phase 6) |

### Key Database Features
- ✅ **RLS** on every table — users only see their own data
- ✅ **Auto stock decrement** via `decrement_stock()` function
- ✅ **Auto customer due update** via trigger on `ledger_transactions`
- ✅ **Auto stock increment** on purchase via trigger on `purchase_items`
- ✅ **Generated column** for `due_amount` on `purchase_entries`

---

## 📦 Key Packages

| Package | Purpose |
|---------|---------|
| `supabase_flutter` | Backend: Auth, DB, Storage |
| `flutter_riverpod` | State management |
| `go_router` | Navigation + deep links |
| `google_fonts` | Poppins typography |
| `intl` | Date/number formatting |
| `nepali_date_converter` | BS ↔ AD date conversion |
| `fl_chart` | Dashboard charts |
| `pdf` + `printing` | Receipt PDF generation |
| `mobile_scanner` | Barcode scanner (Phase 3) |
| `hive_flutter` | Offline local storage (Phase 5) |
| `connectivity_plus` | Network status (Phase 5) |
| `shimmer` | Loading skeletons |

---

## 🔐 Security

- **RLS enabled** on all tables — every query is user-scoped
- `decrement_stock` runs as `SECURITY DEFINER` (trusted function)
- Google Sign-In via Supabase OAuth
- Supabase deep link scheme: `io.supabase.hamropasal://login-callback`
- No credentials hardcoded — use `--dart-define` or `.env`

---

## 💳 Subscription Plans

| Plan | Price | Duration | Features |
|------|-------|----------|---------|
| Free Trial | NPR 0 | 14 days | Basic billing, 50 products, 20 customers |
| Monthly | NPR 250 | 30 days | Unlimited + ledger + reports |
| 6 Month | NPR 1,299 | 180 days | + Expenses + Suppliers + Export |
| Yearly | NPR 2,299 | 365 days | + Staff + Analytics + Priority support |

---

## 🗺️ Development Roadmap

### ✅ Phase 1 – MVP (Implemented)
- [x] Splash, Login, Signup, Profile Setup
- [x] Subscription plan selection
- [x] Dashboard with analytics cards
- [x] POS billing with cart + checkout
- [x] Inventory management (add/edit/delete)
- [x] Customer ledger (udhaar/payment)
- [x] Receipt generation + PDF print
- [x] Expenses tracking
- [x] Suppliers directory
- [x] Reports with bar chart
- [x] Settings with dark mode toggle
- [x] Supabase Auth (email + Google)
- [x] Full RLS security

### 🔄 Phase 2 – Business Management
- [ ] Profit & Loss dashboard
- [ ] Daily/monthly expense vs revenue
- [ ] CSV/PDF export for all reports
- [ ] Nepali date (BS) full support

### 🔄 Phase 3 – Advanced POS
- [ ] Barcode scanner (mobile_scanner)
- [ ] Low stock push notifications
- [ ] Expiry date alerts
- [ ] Purchase entry system

### 🔄 Phase 4 – Customer Communication
- [ ] WhatsApp reminder (url_launcher)
- [ ] SMS receipt/reminder
- [ ] Customer loyalty points

### 🔄 Phase 5 – Offline & Security
- [ ] Hive offline storage
- [ ] Supabase sync when online
- [ ] Multi-user staff system
- [ ] Owner / Manager / Cashier roles

### 🔄 Phase 6 – Premium
- [ ] Khalti payment integration
- [ ] eSewa payment integration
- [ ] Bluetooth thermal printer (58mm/80mm)
- [ ] Multi-branch management
- [ ] AI restock suggestions

---

## 🤝 Contributing

1. Fork the repo
2. Create your feature branch: `git checkout -b feature/amazing-feature`
3. Commit your changes: `git commit -m 'Add amazing feature'`
4. Push to branch: `git push origin feature/amazing-feature`
5. Open a Pull Request

---

## 📄 License

MIT License — see [LICENSE](LICENSE) for details.

---

## 📞 Support

Built with ❤️ for Nepali shopkeepers.  
**Hamro Pasal** — *Smart Business for Nepal* 🇳🇵
