import 'package:flutter/material.dart';

// ── Extension for easy access ─────────────────────────────────
extension AppLocalizationsExt on BuildContext {
  AppStrings get l10n => AppStrings.of(this);
}

// ── App Strings ───────────────────────────────────────────────
class AppStrings {
  final bool isNepali;
  const AppStrings._(this.isNepali);

  static AppStrings of(BuildContext context) {
    final locale = Localizations.localeOf(context);
    return AppStrings._(locale.languageCode == 'ne');
  }

  String _s(String en, String ne) => isNepali ? ne : en;

  // ── Navigation ────────────────────────────────────────────
  String get dashboard => _s('Dashboard', 'ड्यासबोर्ड');
  String get transactions => _s('Transactions', 'कारोबारहरू');
  String get parties => _s('Parties', 'पार्टीहरू');
  String get inventory => _s('Inventory', 'सामानहरू');
  String get expenses => _s('Expenses', 'खर्चहरू');
  String get invoices => _s('Invoices', 'बिलहरू');
  String get reports => _s('Reports', 'रिपोर्टहरू');
  String get accounts => _s('Accounts', 'खाताहरू');
  String get staff => _s('Staff', 'कर्मचारीहरू');
  String get settings => _s('Settings', 'सेटिङहरू');

  // ── Common Actions ────────────────────────────────────────
  String get add => _s('Add', 'थप्नुहोस्');
  String get edit => _s('Edit', 'सम्पादन');
  String get delete => _s('Delete', 'मेटाउनुहोस्');
  String get save => _s('Save', 'सुरक्षित');
  String get cancel => _s('Cancel', 'रद्द');
  String get confirm => _s('Confirm', 'पुष्टि');
  String get search => _s('Search', 'खोज्नुहोस्');
  String get back => _s('Back', 'पछाडि');
  String get close => _s('Close', 'बन्द');
  String get retry => _s('Retry', 'पुनः प्रयास');
  String get refresh => _s('Refresh', 'रिफ्रेस');
  String get loading => _s('Loading...', 'लोड हुँदैछ...');
  String get yes => _s('Yes', 'हो');
  String get no => _s('No', 'होइन');
  String get done => _s('Done', 'सम्पन्न');
  String get submit => _s('Submit', 'पेश');
  String get update => _s('Update', 'अपडेट');
  String get noData => _s('No data found', 'कुनै डाटा भेटिएन');
  String get required => _s('This field is required', 'यो फिल्ड आवश्यक छ');
  String get optional => _s('Optional', 'ऐच्छिक');
  String get all => _s('All', 'सबै');
  String get total => _s('Total', 'जम्मा');
  String get filter => _s('Filter', 'फिल्टर');
  String get sortBy => _s('Sort By', 'क्रमबद्ध गर्नुहोस्');
  String get print => _s('Print', 'प्रिन्ट');
  String get share => _s('Share', 'साझा');
  String get export => _s('Export', 'निर्यात');
  String get markAsPaid => _s('Mark as Paid', 'भुक्तान गरियो भनी चिन्ह लगाउनुहोस्');
  String get viewDetails => _s('View Details', 'विस्तार हेर्नुहोस्');
  String get unknown => _s('Unknown', 'अज्ञात');

  // ── Status ────────────────────────────────────────────────
  String get paid => _s('Paid', 'भुक्तान');
  String get unpaid => _s('Unpaid', 'अभुक्तान');
  String get partial => _s('Partial', 'आंशिक');
  String get pending => _s('Pending', 'बाँकी');
  String get completed => _s('Completed', 'सम्पन्न');
  String get active => _s('Active', 'सक्रिय');
  String get inactive => _s('Inactive', 'निष्क्रिय');
  String get overdue => _s('Overdue', 'म्याद नाघेको');

  // ── Finance Fields ─────────────────────────────────────────
  String get amount => _s('Amount', 'रकम');
  String get price => _s('Price', 'मूल्य');
  String get quantity => _s('Quantity', 'मात्रा');
  String get tax => _s('Tax', 'कर');
  String get discount => _s('Discount', 'छुट');
  String get subtotal => _s('Subtotal', 'उप-जम्मा');
  String get grandTotal => _s('Grand Total', 'कुल जम्मा');
  String get balance => _s('Balance', 'मौज्दात');
  String get due => _s('Due', 'बाँकी');
  String get received => _s('Received', 'प्राप्त');
  String get paid2 => _s('Paid', 'तिरेको');
  String get outstanding => _s('Outstanding', 'बक्यौता');
  String get profit => _s('Profit', 'नाफा');
  String get loss => _s('Loss', 'नोक्सान');
  String get currency => _s('NPR', 'रु.');

  // ── Common Fields ──────────────────────────────────────────
  String get name => _s('Name', 'नाम');
  String get email => _s('Email', 'इमेल');
  String get phone => _s('Phone', 'फोन');
  String get address => _s('Address', 'ठेगाना');
  String get date => _s('Date', 'मिति');
  String get description => _s('Description', 'विवरण');
  String get notes => _s('Notes', 'टिप्पणी');
  String get status => _s('Status', 'स्थिति');
  String get category => _s('Category', 'वर्ग');
  String get type => _s('Type', 'प्रकार');
  String get reference => _s('Reference', 'सन्दर्भ');

  // ── Auth ──────────────────────────────────────────────────
  String get signIn => _s('Sign In', 'साइन इन');
  String get signOut => _s('Sign Out', 'साइन आउट');
  String get signUp => _s('Sign Up', 'साइन अप');
  String get password => _s('Password', 'पासवर्ड');
  String get forgotPassword => _s('Forgot Password?', 'पासवर्ड बिर्सनुभयो?');
  String get welcomeBack => _s('Welcome Back 👋', 'स्वागत छ 👋');
  String get noAccount => _s("Don't have an account?", 'खाता छैन?');
  String get haveAccount => _s('Already have an account?', 'खाता छ?');
  String get continueWith => _s('Continue with Google', 'Google सँग जारी राख्नुहोस्');
  String get signInToContinue => _s('Sign in to continue managing your business.',
      'आफ्नो व्यापार व्यवस्थापन जारी राख्न साइन इन गर्नुहोस्।');
  String get signOutConfirm => _s('Are you sure you want to sign out?',
      'के तपाईं साइन आउट गर्न चाहनुहुन्छ?');

  // ── Dashboard ─────────────────────────────────────────────
  String get totalSales => _s('Total Sales', 'कुल बिक्री');
  String get totalPurchases => _s('Total Purchases', 'कुल खरिद');
  String get netBalance => _s('Net Balance', 'खुद मौज्दात');
  String get cashInHand => _s('Cash in Hand', 'हातमा नगद');
  String get recentTransactions => _s('Recent Transactions', 'हालका कारोबारहरू');
  String get quickActions => _s('Quick Actions', 'द्रुत कार्यहरू');
  String get addSale => _s('Add Sale', 'बिक्री थप्नुहोस्');
  String get newSale => _s('New Sale', 'नयाँ बिक्री');
  String get addPurchase => _s('Add Purchase', 'खरिद थप्नुहोस्');
  String get addExpense => _s('Add Expense', 'खर्च थप्नुहोस्');
  String get createInvoice => _s('Create Invoice', 'बिल बनाउनुहोस्');
  String get goodMorning => _s('Good Morning', 'शुभ प्रभात');
  String get goodAfternoon => _s('Good Afternoon', 'शुभ दिउँसो');
  String get goodEvening => _s('Good Evening', 'शुभ साँझ');
  String get overviewToday => _s("Today's Overview", 'आजको सारांश');
  String get receivable => _s('Receivable', 'लिनु पर्ने');
  String get payable => _s('Payable', 'दिनु पर्ने');
  String get seeAll => _s('See All', 'सबै हेर्नुहोस्');
  String get viewAll => _s('View All', 'सबै हेर्नुहोस्');
  String get view => _s('View', 'हेर्नुहोस्');
  String get noRecentTransactions => _s('No transactions yet', 'कारोबारहरू छैनन्');
  String get todaySales => _s("Today's Sales", 'आजको बिक्री');
  String get todayExpenses => _s("Today's Expenses", 'आजको खर्च');
  String get receivables => _s('Receivables', 'लिनु पर्ने');
  String get payables => _s('Payables', 'दिनु पर्ने');
  String get todayNetProfit => _s("Today's Net Profit", 'आजको खुद नाफा');
  String get businessMode => _s('Business Mode', 'व्यापार मोड');
  String get subscribe => _s('Subscribe', 'सदस्यता लिनुहोस्');
  String get subscribeNow => _s('Subscribe Now', 'अहिले सदस्यता');
  String get trialExpiredMsg => _s('Your free trial has expired.', 'तपाईंको नि:शुल्क परीक्षण समाप्त भयो।');

  // Format strings (parameterized)
  String daysLeftTrial(int days) => _s(
    '$days days left in your free trial!',
    '$days दिन बाँकी तपाईंको नि:शुल्क परीक्षणमा!',
  );
  String lowStockAlert(int count) => _s(
    '$count product${count > 1 ? 's' : ''} running low on stock.',
    '$count उत्पादन स्टक कम छ।',
  );

  // ── Parties ───────────────────────────────────────────────
  String get addParty => _s('Add Party', 'पार्टी थप्नुहोस्');
  String get customer => _s('Customer', 'ग्राहक');
  String get supplier => _s('Supplier', 'आपूर्तिकर्ता');
  String get customers => _s('Customers', 'ग्राहकहरू');
  String get suppliers => _s('Suppliers', 'आपूर्तिकर्ताहरू');
  String get partyName => _s('Party Name', 'पार्टीको नाम');
  String get contactPerson => _s('Contact Person', 'सम्पर्क व्यक्ति');
  String get searchParties => _s('Search parties...', 'पार्टी खोज्नुहोस्...');
  String get noPartiesFound => _s('No parties found', 'कुनै पार्टी भेटिएन');
  String get toPay => _s('To Pay', 'दिनु पर्ने');
  String get toReceive => _s('To Receive', 'लिनु पर्ने');

  // ── Inventory ─────────────────────────────────────────────
  String get addProduct => _s('Add Product', 'उत्पादन थप्नुहोस्');
  String get product => _s('Product', 'उत्पादन');
  String get products => _s('Products', 'उत्पादनहरू');
  String get productName => _s('Product Name', 'उत्पादनको नाम');
  String get unit => _s('Unit', 'एकाइ');
  String get stock => _s('Stock', 'स्टक');
  String get lowStock => _s('Low Stock', 'कम स्टक');
  String get outOfStock => _s('Out of Stock', 'स्टक सकियो');
  String get purchasePrice => _s('Purchase Price', 'खरिद मूल्य');
  String get sellingPrice => _s('Selling Price', 'बिक्री मूल्य');
  String get searchProducts => _s('Search products...', 'उत्पादन खोज्नुहोस्...');
  String get noProductsFound => _s('No products found', 'कुनै उत्पादन भेटिएन');

  // ── Transactions ──────────────────────────────────────────
  String get addTransaction => _s('Add Transaction', 'कारोबार थप्नुहोस्');
  String get transaction => _s('Transaction', 'कारोबार');
  String get sale => _s('Sale', 'बिक्री');
  String get purchase => _s('Purchase', 'खरिद');
  String get payment => _s('Payment', 'भुक्तानी');
  String get receipt => _s('Receipt', 'रसिद');
  String get transactionType => _s('Transaction Type', 'कारोबारको प्रकार');
  String get paymentMethod => _s('Payment Method', 'भुक्तानी विधि');
  String get cash => _s('Cash', 'नगद');
  String get bank => _s('Bank', 'बैंक');
  String get searchTransactions => _s('Search transactions...', 'कारोबार खोज्नुहोस्...');
  String get noTransactionsFound => _s('No transactions found', 'कुनै कारोबार भेटिएन');

  // ── Invoices ──────────────────────────────────────────────
  String get invoice => _s('Invoice', 'बिल');
  String get invoiceNumber => _s('Invoice #', 'बिल नं.');
  String get billTo => _s('Bill To', 'बिल दिने');
  String get invoiceDate => _s('Invoice Date', 'बिल मिति');
  String get dueDate => _s('Due Date', 'भुक्तानी मिति');
  String get lineItems => _s('Line Items', 'वस्तुहरू');
  String get addItem => _s('Add Item', 'वस्तु थप्नुहोस्');
  String get noInvoicesFound => _s('No invoices found', 'कुनै बिल भेटिएन');
  String get searchInvoices => _s('Search invoices...', 'बिल खोज्नुहोस्...');
  String get printInvoice => _s('Print Invoice', 'बिल प्रिन्ट');
  String get amountDue => _s('Amount Due', 'बाँकी रकम');

  // ── Expenses ──────────────────────────────────────────────
  String get expense => _s('Expense', 'खर्च');
  String get expenseCategory => _s('Expense Category', 'खर्चको वर्ग');
  String get searchExpenses => _s('Search expenses...', 'खर्च खोज्नुहोस्...');
  String get noExpensesFound => _s('No expenses found', 'कुनै खर्च भेटिएन');
  String get totalExpenses => _s('Total Expenses', 'कुल खर्च');
  String get trackExpensesHere => _s('Track your business expenses here.', 'तपाईंको व्यापारिक खर्चहरू यहाँ ट्र्याक गर्नुहोस्।');

  // ── Reports ───────────────────────────────────────────────
  String get salesReport => _s('Sales Report', 'बिक्री रिपोर्ट');
  String get purchaseReport => _s('Purchase Report', 'खरिद रिपोर्ट');
  String get expenseReport => _s('Expense Report', 'खर्च रिपोर्ट');
  String get profitLoss => _s('Profit & Loss', 'नाफा र नोक्सान');
  String get dateRange => _s('Date Range', 'मिति दायरा');
  String get thisMonth => _s('This Month', 'यो महिना');
  String get lastMonth => _s('Last Month', 'गत महिना');
  String get thisYear => _s('This Year', 'यो वर्ष');
  String get custom => _s('Custom', 'अनुकूलन');

  // ── Settings ──────────────────────────────────────────────
  String get account => _s('Account', 'खाता');
  String get profile => _s('Profile', 'प्रोफाइल');
  String get businessProfile => _s('Business Profile', 'व्यापार प्रोफाइल');
  String get editProfile => _s('Edit your personal information', 'आफ्नो व्यक्तिगत जानकारी सम्पादन गर्नुहोस्');
  String get editBusiness => _s('Edit business name, logo, address', 'व्यापारको नाम, लोगो, ठेगाना सम्पादन');
  String get preferences => _s('Preferences', 'प्राथमिकताहरू');
  String get language => _s('Language', 'भाषा');
  String get languageSubtitle => _s('English / नेपाली', 'English / नेपाली');
  String get english => _s('English', 'अंग्रेजी');
  String get nepali => _s('Nepali', 'नेपाली');
  String get darkMode => _s('Dark Mode', 'डार्क मोड');
  String get on => _s('On', 'चालु');
  String get off => _s('Off', 'बन्द');
  String get currency2 => _s('Currency', 'मुद्रा');
  String get currencySubtitle => _s('NPR — Nepalese Rupee', 'रु. — नेपाली रुपैयाँ');
  String get subscription => _s('Subscription', 'सदस्यता');
  String get manageSubscription => _s('Manage Subscription', 'सदस्यता व्यवस्थापन');
  String get viewPlans => _s('View plans & payment history', 'योजना र भुक्तानी इतिहास हेर्नुहोस्');
  String get dataSync => _s('Data & Sync', 'डाटा र सिंक');
  String get syncNow => _s('Sync Now', 'अहिले सिंक');
  String get syncSubtitle => _s('Manually sync offline data', 'अफलाइन डाटा म्यानुअल सिंक');
  String get backupData => _s('Backup Data', 'डाटा ब्याकअप');
  String get backupSubtitle => _s('Export all your business data', 'सबै व्यापार डाटा निर्यात');
  String get support => _s('Support', 'सहयोग');
  String get helpFaq => _s('Help & FAQ', 'मद्दत र FAQ');
  String get helpSubtitle => _s('Get help with Hamro Pasal', 'Hamro Pasal सँग मद्दत लिनुहोस्');
  String get sendFeedback => _s('Send Feedback', 'प्रतिक्रिया पठाउनुहोस्');
  String get feedbackSubtitle => _s('Help us improve the app', 'एपलाई सुधार गर्न मद्दत');
  String get privacyPolicy => _s('Privacy Policy', 'गोपनीयता नीति');
  String get termsOfService => _s('Terms of Service', 'सेवा सर्तहरू');
  String get switchProfile => _s('Switch Profile', 'प्रोफाइल बदल्नुहोस्');
  String get personal => _s('Personal', 'व्यक्तिगत');
  String get business => _s('Business', 'व्यापार');
  String get currentlyPersonal => _s('Currently: Personal View', 'अहिले: व्यक्तिगत दृश्य');
  String get currentlyBusiness => _s('Currently: Business View', 'अहिले: व्यापार दृश्य');
  String get switchedToPersonal => _s('Switched to Personal Mode', 'व्यक्तिगत मोडमा स्विच भयो');
  String get switchedToBusiness => _s('Switched to Business Mode', 'व्यापार मोडमा स्विच भयो');
  String get madeWithLove => _s('Hamro Pasal v1.0.0\nMade with love for Nepal',
      'हाम्रो पसल v1.0.0\nनेपालको लागि माया सँग बनाइएको');
  String get selectLanguage => _s('Select Language', 'भाषा छनौट');
  String get languageChanged => _s('Language changed to English', 'भाषा नेपालीमा परिवर्तन भयो');

  // ── Business Setup ────────────────────────────────────────
  String get businessSetup => _s('Business Setup', 'व्यापार सेटअप');
  String get businessName => _s('Business Name', 'व्यापारको नाम');
  String get businessType => _s('Business Type', 'व्यापारको प्रकार');
  String get gstPan => _s('GST / PAN Number', 'GST / PAN नम्बर');

  // ── Subscription ──────────────────────────────────────────
  String get trialActive => _s('Trial Active', 'परीक्षण सक्रिय');
  String get trialExpired => _s('Trial Expired', 'परीक्षण समाप्त');
  String get subscribed => _s('Subscribed', 'सदस्यता');
  String get daysLeft => _s('days left', 'दिन बाँकी');

  // ── Errors / Messages ─────────────────────────────────────
  String get somethingWentWrong => _s('Something went wrong', 'केही गलत भयो');
  String get networkError => _s('Network error. Please check your connection.',
      'नेटवर्क त्रुटि। कृपया आफ्नो जडान जाँच गर्नुहोस्।');
  String get dataLoadError => _s('Failed to load data', 'डाटा लोड गर्न असफल');
  String get savedSuccessfully => _s('Saved successfully', 'सफलतापूर्वक सुरक्षित');
  String get deletedSuccessfully => _s('Deleted successfully', 'सफलतापूर्वक मेटाइयो');
  String get updatedSuccessfully => _s('Updated successfully', 'सफलतापूर्वक अपडेट');
  String get confirmDelete => _s('Confirm Delete', 'मेटाउने पुष्टि');
  String get deleteWarning => _s('This action cannot be undone.', 'यो कार्य फिर्ता गर्न सकिँदैन।');
}
