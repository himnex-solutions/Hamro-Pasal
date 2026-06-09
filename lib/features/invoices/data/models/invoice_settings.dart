import 'dart:convert';

class InvoiceSettings {
  final String prefix;
  final String themeColorHex;
  final bool showTax;
  final bool showDiscount;
  final String title;
  final String footerNote;
  final String printTemplate; // 'a4', 'a5', 'thermal_58', 'thermal_80'
  final bool showAddress;
  final bool showPhone;
  final bool showPAN;

  InvoiceSettings({
    this.prefix = 'INV',
    this.themeColorHex = '#6366F1', // AppTheme.primaryColor
    this.showTax = true,
    this.showDiscount = true,
    this.title = 'TAX INVOICE',
    this.footerNote = 'Thank you for your business!',
    this.printTemplate = 'a4',
    this.showAddress = true,
    this.showPhone = true,
    this.showPAN = true,
  });

  InvoiceSettings copyWith({
    String? prefix,
    String? themeColorHex,
    bool? showTax,
    bool? showDiscount,
    String? title,
    String? footerNote,
    String? printTemplate,
    bool? showAddress,
    bool? showPhone,
    bool? showPAN,
  }) {
    return InvoiceSettings(
      prefix: prefix ?? this.prefix,
      themeColorHex: themeColorHex ?? this.themeColorHex,
      showTax: showTax ?? this.showTax,
      showDiscount: showDiscount ?? this.showDiscount,
      title: title ?? this.title,
      footerNote: footerNote ?? this.footerNote,
      printTemplate: printTemplate ?? this.printTemplate,
      showAddress: showAddress ?? this.showAddress,
      showPhone: showPhone ?? this.showPhone,
      showPAN: showPAN ?? this.showPAN,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'prefix': prefix,
      'themeColorHex': themeColorHex,
      'showTax': showTax,
      'showDiscount': showDiscount,
      'title': title,
      'footerNote': footerNote,
      'printTemplate': printTemplate,
      'showAddress': showAddress,
      'showPhone': showPhone,
      'showPAN': showPAN,
    };
  }

  factory InvoiceSettings.fromMap(Map<String, dynamic> map) {
    return InvoiceSettings(
      prefix: map['prefix'] ?? 'INV',
      themeColorHex: map['themeColorHex'] ?? '#6366F1',
      showTax: map['showTax'] ?? true,
      showDiscount: map['showDiscount'] ?? true,
      title: map['title'] ?? 'TAX INVOICE',
      footerNote: map['footerNote'] ?? 'Thank you for your business!',
      printTemplate: map['printTemplate'] ?? 'a4',
      showAddress: map['showAddress'] ?? true,
      showPhone: map['showPhone'] ?? true,
      showPAN: map['showPAN'] ?? true,
    );
  }

  String toJson() => json.encode(toMap());

  factory InvoiceSettings.fromJson(String source) =>
      InvoiceSettings.fromMap(json.decode(source));
}
