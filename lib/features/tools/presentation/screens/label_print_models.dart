// ── Label Types ───────────────────────────────────────────────
enum LabelType {
  productLabel,
  barcodeSticker,
  qrLabel,
  shippingLabel,
  receipt,
}

extension LabelTypeX on LabelType {
  String get title {
    switch (this) {
      case LabelType.productLabel:   return 'Product Label';
      case LabelType.barcodeSticker: return 'Barcode Sticker';
      case LabelType.qrLabel:        return 'QR Label';
      case LabelType.shippingLabel:  return 'Shipping Label';
      case LabelType.receipt:        return 'Receipt';
    }
  }

  String get icon {
    switch (this) {
      case LabelType.productLabel:   return '🏷️';
      case LabelType.barcodeSticker: return '📊';
      case LabelType.qrLabel:        return '📱';
      case LabelType.shippingLabel:  return '📦';
      case LabelType.receipt:        return '🧾';
    }
  }
}

// ── Printer Brands ────────────────────────────────────────────
enum PrinterBrand {
  xprinter,
  zebra,
  tsc,
  epson,
  honeywell,
  generic,
}

extension PrinterBrandX on PrinterBrand {
  String get name {
    switch (this) {
      case PrinterBrand.xprinter:  return 'Xprinter';
      case PrinterBrand.zebra:     return 'Zebra';
      case PrinterBrand.tsc:       return 'TSC';
      case PrinterBrand.epson:     return 'Epson';
      case PrinterBrand.honeywell: return 'Honeywell';
      case PrinterBrand.generic:   return 'Generic';
    }
  }

  List<LabelPreset> get presets {
    switch (this) {
      case PrinterBrand.xprinter:
        return const [
          LabelPreset('58mm Receipt',  58,  160, isRoll: true),
          LabelPreset('80mm Receipt',  80,  160, isRoll: true),
          LabelPreset('40×30mm Label', 40,  30),
          LabelPreset('60×40mm Label', 60,  40),
        ];
      case PrinterBrand.zebra:
        return const [
          LabelPreset('2"×1" (51×25mm)',  51,  25),
          LabelPreset('4"×2" (102×51mm)', 102, 51),
          LabelPreset('4"×6" (102×152mm)',102, 152),
          LabelPreset('2"×4" (51×102mm)', 51,  102),
        ];
      case PrinterBrand.tsc:
        return const [
          LabelPreset('40×25mm', 40, 25),
          LabelPreset('60×40mm', 60, 40),
          LabelPreset('80×50mm', 80, 50),
          LabelPreset('100×75mm',100, 75),
        ];
      case PrinterBrand.epson:
        return const [
          LabelPreset('58mm Receipt', 58,  160, isRoll: true),
          LabelPreset('80mm Receipt', 80,  160, isRoll: true),
          LabelPreset('58×40mm Label',58,  40),
        ];
      case PrinterBrand.honeywell:
        return const [
          LabelPreset('2"×1" (51×25mm)',  51,  25),
          LabelPreset('4"×2" (102×51mm)', 102, 51),
          LabelPreset('4"×6" (102×152mm)',102, 152),
        ];
      case PrinterBrand.generic:
        return const [
          LabelPreset('Small (50×25mm)',  50,  25),
          LabelPreset('Medium (75×40mm)', 75,  40),
          LabelPreset('Large (100×60mm)', 100, 60),
          LabelPreset('A6 Receipt',       105, 148),
          LabelPreset('Custom…',          0,   0),
        ];
    }
  }
}

// ── Label Preset ──────────────────────────────────────────────
class LabelPreset {
  final String name;
  final double widthMm;
  final double heightMm;
  final bool isRoll;          // roll paper (continuous form)
  final bool isCustom;

  const LabelPreset(this.name, this.widthMm, this.heightMm,
      {this.isRoll = false})
      : isCustom = widthMm == 0 && heightMm == 0;
}

// ── Barcode mode ──────────────────────────────────────────────
enum BarcodeMode { qr, code128, ean13 }

extension BarcodeModeX on BarcodeMode {
  String get label {
    switch (this) {
      case BarcodeMode.qr:      return 'QR Code';
      case BarcodeMode.code128: return 'Code 128';
      case BarcodeMode.ean13:   return 'EAN-13';
    }
  }
}
