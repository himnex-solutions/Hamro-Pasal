import 'dart:typed_data';
import 'package:hamro_pasal/features/tools/presentation/screens/label_print_models.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:qr_flutter/qr_flutter.dart';
import 'package:flutter/material.dart' show Colors;

class LabelPdfBuilder {
  LabelPdfBuilder._();

  // ── QR bytes helper ─────────────────────────────────────────
  static Future<Uint8List> _qrBytes(String data) async {
    final painter = QrPainter(
      data: data.isEmpty ? 'N/A' : data,
      version: QrVersions.auto,
      eyeStyle: const QrEyeStyle(eyeShape: QrEyeShape.square, color: Colors.black),
      dataModuleStyle: const QrDataModuleStyle(dataModuleShape: QrDataModuleShape.square, color: Colors.black),
    );
    final img = await painter.toImageData(300);
    return img!.buffer.asUint8List();
  }

  // ── Page format helper ──────────────────────────────────────
  static PdfPageFormat _fmt(double wMm, double hMm) => PdfPageFormat(
        wMm * PdfPageFormat.mm,
        hMm * PdfPageFormat.mm,
        marginAll: 3 * PdfPageFormat.mm,
      );

  // ── 1. Product Label ─────────────────────────────────────────
  static Future<Uint8List> productLabel({
    required String productName,
    required String shopName,
    required String brandName,
    required String price,
    required String codeValue,
    required BarcodeMode codeMode,
    required double wMm,
    required double hMm,
  }) async {
    final doc = pw.Document();
    final fmt = _fmt(wMm, hMm);

    pw.Widget codeW;
    if (codeMode == BarcodeMode.qr) {
      final bytes = await _qrBytes(codeValue.isEmpty ? 'N/A' : codeValue);
      codeW = pw.Image(pw.MemoryImage(bytes), width: 60, height: 60);
    } else if (codeMode == BarcodeMode.ean13) {
      final d = codeValue.replaceAll(RegExp(r'[^0-9]'), '').padLeft(13, '0').substring(0, 13);
      codeW = pw.BarcodeWidget(barcode: pw.Barcode.ean13(), data: d, width: 90, height: 36, drawText: true, textStyle: const pw.TextStyle(fontSize: 7));
    } else {
      codeW = pw.BarcodeWidget(barcode: pw.Barcode.code128(), data: codeValue.isEmpty ? 'N/A' : codeValue, width: 90, height: 36, drawText: true, textStyle: const pw.TextStyle(fontSize: 7));
    }

    doc.addPage(pw.Page(
      pageFormat: fmt,
      build: (ctx) => pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.center, children: [
        if (shopName.isNotEmpty) pw.Text(shopName, style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold)),
        if (brandName.isNotEmpty) pw.Text(brandName, style: const pw.TextStyle(fontSize: 7)),
        if (shopName.isNotEmpty || brandName.isNotEmpty) ...[pw.SizedBox(height: 2), pw.Divider(thickness: 0.5), pw.SizedBox(height: 2)],
        if (productName.isNotEmpty) pw.Text(productName, style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold), textAlign: pw.TextAlign.center),
        pw.SizedBox(height: 4),
        codeW,
        if (price.isNotEmpty) ...[pw.SizedBox(height: 4), pw.Text('Rs. $price', style: pw.TextStyle(fontSize: 11, fontWeight: pw.FontWeight.bold))],
      ]),
    ));
    return doc.save();
  }

  // ── 2. Barcode Sticker ───────────────────────────────────────
  static Future<Uint8List> barcodeSticker({
    required String itemName,
    required String codeValue,
    required BarcodeMode codeMode,
    required String price,
    required double wMm,
    required double hMm,
  }) async {
    final doc = pw.Document();
    final fmt = _fmt(wMm, hMm);

    pw.Widget codeW;
    if (codeMode == BarcodeMode.qr) {
      final bytes = await _qrBytes(codeValue.isEmpty ? 'N/A' : codeValue);
      codeW = pw.Image(pw.MemoryImage(bytes), width: 50, height: 50);
    } else if (codeMode == BarcodeMode.ean13) {
      final d = codeValue.replaceAll(RegExp(r'[^0-9]'), '').padLeft(13, '0').substring(0, 13);
      codeW = pw.BarcodeWidget(barcode: pw.Barcode.ean13(), data: d, width: 100, height: 38, drawText: true, textStyle: const pw.TextStyle(fontSize: 7));
    } else {
      codeW = pw.BarcodeWidget(barcode: pw.Barcode.code128(), data: codeValue.isEmpty ? 'N/A' : codeValue, width: 100, height: 38, drawText: true, textStyle: const pw.TextStyle(fontSize: 7));
    }

    doc.addPage(pw.Page(
      pageFormat: fmt,
      build: (ctx) => pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.center, children: [
        if (itemName.isNotEmpty) pw.Text(itemName, style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold), textAlign: pw.TextAlign.center),
        pw.SizedBox(height: 3),
        codeW,
        if (price.isNotEmpty) ...[pw.SizedBox(height: 3), pw.Text('Rs. $price', style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold))],
      ]),
    ));
    return doc.save();
  }

  // ── 3. QR Label ──────────────────────────────────────────────
  static Future<Uint8List> qrLabel({
    required String title,
    required String qrData,
    required String subtitle,
    required double wMm,
    required double hMm,
  }) async {
    final doc = pw.Document();
    final fmt = _fmt(wMm, hMm);
    final bytes = await _qrBytes(qrData.isEmpty ? 'https://hamropasal.app' : qrData);

    doc.addPage(pw.Page(
      pageFormat: fmt,
      build: (ctx) => pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.center, children: [
        if (title.isNotEmpty) pw.Text(title, style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold), textAlign: pw.TextAlign.center),
        pw.SizedBox(height: 4),
        pw.Image(pw.MemoryImage(bytes), width: 70, height: 70),
        pw.SizedBox(height: 4),
        if (subtitle.isNotEmpty) pw.Text(subtitle, style: const pw.TextStyle(fontSize: 8), textAlign: pw.TextAlign.center),
        pw.Text(qrData.isEmpty ? '' : (qrData.length > 30 ? '${qrData.substring(0, 30)}…' : qrData),
            style: const pw.TextStyle(fontSize: 7), textAlign: pw.TextAlign.center),
      ]),
    ));
    return doc.save();
  }

  // ── 4. Shipping Label ────────────────────────────────────────
  static Future<Uint8List> shippingLabel({
    required String fromName,
    required String fromAddress,
    required String fromPhone,
    required String toName,
    required String toAddress,
    required String toPhone,
    required String orderNo,
    required String weight,
    required String notes,
    required String codeValue,
    required BarcodeMode codeMode,
    required double wMm,
    required double hMm,
  }) async {
    final doc = pw.Document();
    final fmt = _fmt(wMm, hMm);

    pw.Widget? codeW;
    if (codeValue.isNotEmpty) {
      if (codeMode == BarcodeMode.qr) {
        final bytes = await _qrBytes(codeValue);
        codeW = pw.Image(pw.MemoryImage(bytes), width: 55, height: 55);
      } else {
        codeW = pw.BarcodeWidget(
          barcode: codeMode == BarcodeMode.ean13 ? pw.Barcode.ean13() : pw.Barcode.code128(),
          data: codeMode == BarcodeMode.ean13
              ? codeValue.replaceAll(RegExp(r'[^0-9]'), '').padLeft(13, '0').substring(0, 13)
              : codeValue,
          width: 110, height: 40, drawText: true, textStyle: const pw.TextStyle(fontSize: 7),
        );
      }
    }

    doc.addPage(pw.Page(
      pageFormat: fmt,
      build: (ctx) => pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
        pw.Row(mainAxisAlignment: pw.MainAxisAlignment.spaceBetween, children: [
          pw.Text('SHIPPING LABEL', style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold)),
          if (orderNo.isNotEmpty) pw.Text('Order: $orderNo', style: const pw.TextStyle(fontSize: 8)),
        ]),
        pw.Divider(thickness: 0.5),
        pw.SizedBox(height: 2),
        pw.Text('FROM:', style: pw.TextStyle(fontSize: 7, fontWeight: pw.FontWeight.bold)),
        if (fromName.isNotEmpty) pw.Text(fromName, style: const pw.TextStyle(fontSize: 9)),
        if (fromAddress.isNotEmpty) pw.Text(fromAddress, style: const pw.TextStyle(fontSize: 8)),
        if (fromPhone.isNotEmpty) pw.Text('Ph: $fromPhone', style: const pw.TextStyle(fontSize: 8)),
        pw.SizedBox(height: 4),
        pw.Divider(thickness: 0.3),
        pw.SizedBox(height: 4),
        pw.Text('TO:', style: pw.TextStyle(fontSize: 7, fontWeight: pw.FontWeight.bold)),
        if (toName.isNotEmpty) pw.Text(toName, style: pw.TextStyle(fontSize: 11, fontWeight: pw.FontWeight.bold)),
        if (toAddress.isNotEmpty) pw.Text(toAddress, style: const pw.TextStyle(fontSize: 9)),
        if (toPhone.isNotEmpty) pw.Text('Ph: $toPhone', style: const pw.TextStyle(fontSize: 9)),
        pw.SizedBox(height: 4),
        if (weight.isNotEmpty) pw.Text('Weight: $weight', style: const pw.TextStyle(fontSize: 8)),
        if (notes.isNotEmpty) pw.Text('Note: $notes', style: const pw.TextStyle(fontSize: 8)),
        if (codeW != null) ...[pw.SizedBox(height: 4), pw.Center(child: codeW)],
      ]),
    ));
    return doc.save();
  }

  // ── 5. Receipt ───────────────────────────────────────────────
  static Future<Uint8List> receipt({
    required String shopName,
    required String address,
    required String phone,
    required List<Map<String, String>> items,   // [{name, qty, price}]
    required String subtotal,
    required String discount,
    required String tax,
    required String total,
    required String paymentMethod,
    required String footer,
    required double wMm,
    required double hMm,
  }) async {
    final doc = pw.Document();
    final fmt = _fmt(wMm, hMm);
    final now = DateTime.now();
    final dateStr = '${now.year}-${now.month.toString().padLeft(2,'0')}-${now.day.toString().padLeft(2,'0')} '
        '${now.hour.toString().padLeft(2,'0')}:${now.minute.toString().padLeft(2,'0')}';

    doc.addPage(pw.Page(
      pageFormat: fmt,
      build: (ctx) => pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.center, children: [
        if (shopName.isNotEmpty) pw.Text(shopName, style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold), textAlign: pw.TextAlign.center),
        if (address.isNotEmpty) pw.Text(address, style: const pw.TextStyle(fontSize: 8), textAlign: pw.TextAlign.center),
        if (phone.isNotEmpty) pw.Text(phone, style: const pw.TextStyle(fontSize: 8), textAlign: pw.TextAlign.center),
        pw.SizedBox(height: 4),
        pw.Divider(thickness: 0.5),
        pw.Text(dateStr, style: const pw.TextStyle(fontSize: 8)),
        pw.Divider(thickness: 0.5),
        pw.SizedBox(height: 2),
        // Items
        ...items.map((item) => pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          children: [
            pw.Expanded(child: pw.Text('${item['qty'] ?? '1'}x ${item['name'] ?? ''}', style: const pw.TextStyle(fontSize: 9))),
            pw.Text('Rs.${item['price'] ?? '0'}', style: const pw.TextStyle(fontSize: 9)),
          ],
        )),
        pw.SizedBox(height: 2),
        pw.Divider(thickness: 0.5),
        if (subtotal.isNotEmpty) _receiptRow('Subtotal', 'Rs.$subtotal'),
        if (discount.isNotEmpty) _receiptRow('Discount', '-Rs.$discount'),
        if (tax.isNotEmpty) _receiptRow('Tax', 'Rs.$tax'),
        pw.Divider(thickness: 1),
        if (total.isNotEmpty) pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          children: [
            pw.Text('TOTAL', style: pw.TextStyle(fontSize: 11, fontWeight: pw.FontWeight.bold)),
            pw.Text('Rs.$total', style: pw.TextStyle(fontSize: 11, fontWeight: pw.FontWeight.bold)),
          ],
        ),
        if (paymentMethod.isNotEmpty) ...[pw.SizedBox(height: 2), pw.Text('Paid by: $paymentMethod', style: const pw.TextStyle(fontSize: 8))],
        pw.Divider(thickness: 0.5),
        if (footer.isNotEmpty) pw.Text(footer, style: const pw.TextStyle(fontSize: 8), textAlign: pw.TextAlign.center),
        pw.Text('Thank you!', style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold), textAlign: pw.TextAlign.center),
      ]),
    ));
    return doc.save();
  }

  static pw.Widget _receiptRow(String label, String value) => pw.Row(
    mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
    children: [
      pw.Text(label, style: const pw.TextStyle(fontSize: 8)),
      pw.Text(value, style: const pw.TextStyle(fontSize: 8)),
    ],
  );
}
