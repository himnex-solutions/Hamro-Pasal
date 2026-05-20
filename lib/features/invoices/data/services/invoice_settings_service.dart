import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:hamro_pasal/features/invoices/data/models/invoice_settings.dart';

final invoiceSettingsProvider =
    NotifierProvider<InvoiceSettingsNotifier, InvoiceSettings>(() {
  return InvoiceSettingsNotifier();
});

class InvoiceSettingsNotifier extends Notifier<InvoiceSettings> {
  static const _key = 'invoice_customization_settings';

  @override
  InvoiceSettings build() {
    _load();
    return InvoiceSettings();
  }

  Future<void> _load() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final dataStr = prefs.getString(_key);
      if (dataStr != null) {
        state = InvoiceSettings.fromJson(dataStr);
      }
    } catch (_) {}
  }

  Future<void> updateSettings(InvoiceSettings newSettings) async {
    state = newSettings;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_key, newSettings.toJson());
    } catch (_) {}
  }
}
