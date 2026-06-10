import 'dart:typed_data';
import 'package:smart_saoji/features/tools/presentation/screens/label_print_models.dart';
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
    final bytes = await _qrBytes(qrData.isEmpty ? 'https://smartsaoji.app' : qrData);

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
    required String pan,
    required String title,
    required String prefix,
    required String receiptNumber,
    required bool showAddress,
    required bool showPhone,
    required bool showPAN,
    required bool showTax,
    required bool showDiscount,
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
        if (showAddress && address.isNotEmpty) pw.Text(address, style: const pw.TextStyle(fontSize: 8), textAlign: pw.TextAlign.center),
        if (showPhone && phone.isNotEmpty) pw.Text('Tel: $phone', style: const pw.TextStyle(fontSize: 8), textAlign: pw.TextAlign.center),
        if (showPAN && pan.isNotEmpty) pw.Text('PAN: $pan', style: const pw.TextStyle(fontSize: 8), textAlign: pw.TextAlign.center),
        pw.SizedBox(height: 4),
        pw.Divider(thickness: 0.5),
        pw.Text('${title.isEmpty ? "TAX INVOICE" : title.toUpperCase()} : ${receiptNumber.isEmpty ? "${prefix.isEmpty ? "INV" : prefix.toUpperCase()}-0001" : receiptNumber}', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 8)),
        pw.Text(dateStr, style: const pw.TextStyle(fontSize: 8)),
        pw.Divider(thickness: 0.5),
        pw.SizedBox(height: 2),
        // Items Table
        pw.Table(
          columnWidths: const {
            0: pw.FlexColumnWidth(4.5), // Name
            1: pw.FlexColumnWidth(1.5), // Qty
            2: pw.FlexColumnWidth(2.0), // Rate
            3: pw.FlexColumnWidth(2.0), // Total
          },
          children: [
            pw.TableRow(
              decoration: const pw.BoxDecoration(
                border: pw.Border(bottom: pw.BorderSide(width: 0.5, style: pw.BorderStyle.dashed)),
              ),
              children: [
                pw.Padding(
                  padding: const pw.EdgeInsets.only(bottom: 2),
                  child: pw.Text('Item', style: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold)),
                ),
                pw.Padding(
                  padding: const pw.EdgeInsets.only(bottom: 2),
                  child: pw.Text('Qty', style: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold), textAlign: pw.TextAlign.right),
                ),
                pw.Padding(
                  padding: const pw.EdgeInsets.only(bottom: 2),
                  child: pw.Text('Rate', style: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold), textAlign: pw.TextAlign.right),
                ),
                pw.Padding(
                  padding: const pw.EdgeInsets.only(bottom: 2),
                  child: pw.Text('Amount', style: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold), textAlign: pw.TextAlign.right),
                ),
              ],
            ),
            ...items.map((item) {
              final qty = double.tryParse(item['qty'] ?? '1') ?? 1;
              final rate = double.tryParse(item['price'] ?? '0') ?? 0;
              final totalAmt = qty * rate;
              return pw.TableRow(
                children: [
                  pw.Padding(
                    padding: const pw.EdgeInsets.symmetric(vertical: 2),
                    child: pw.Text(item['name'] ?? '', style: const pw.TextStyle(fontSize: 8)),
                  ),
                  pw.Padding(
                    padding: const pw.EdgeInsets.symmetric(vertical: 2),
                    child: pw.Text(qty.toStringAsFixed(0), style: const pw.TextStyle(fontSize: 8), textAlign: pw.TextAlign.right),
                  ),
                  pw.Padding(
                    padding: const pw.EdgeInsets.symmetric(vertical: 2),
                    child: pw.Text(rate.toStringAsFixed(2), style: const pw.TextStyle(fontSize: 8), textAlign: pw.TextAlign.right),
                  ),
                  pw.Padding(
                    padding: const pw.EdgeInsets.symmetric(vertical: 2),
                    child: pw.Text(totalAmt.toStringAsFixed(2), style: const pw.TextStyle(fontSize: 8), textAlign: pw.TextAlign.right),
                  ),
                ],
              );
            }),
          ],
        ),
        pw.SizedBox(height: 2),
        pw.Divider(thickness: 0.5),
        if (subtotal.isNotEmpty) _receiptRow('Subtotal', 'Rs.$subtotal'),
        if (showDiscount && discount.isNotEmpty) _receiptRow('Discount', '-Rs.$discount'),
        if (showTax && tax.isNotEmpty) _receiptRow('Tax', 'Rs.$tax'),
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
        pw.Text('Thank You For Your Visit !', style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold), textAlign: pw.TextAlign.center),
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

  static Future<Uint8List> salesStatement({
    required String shopName,
    required String address,
    required String phone,
    required String pan,
    required String periodStr,
    required List<Map<String, dynamic>> receipts,
  }) async {
    final doc = pw.Document();
    
    // Calculate stats
    int totalCount = receipts.length;
    double cashTotal = 0;
    double bankTotal = 0;
    double esewaTotal = 0;
    double grandTotal = 0;

    for (var r in receipts) {
      final t = (r['total'] as num?)?.toDouble() ?? 0.0;
      grandTotal += t;
      final pm = (r['payment_method'] as String? ?? 'Cash').toLowerCase();
      if (pm.contains('cash')) {
        cashTotal += t;
      } else if (pm.contains('bank') || pm.contains('qr')) {
        bankTotal += t;
      } else if (pm.contains('esewa')) {
        esewaTotal += t;
      }
    }

    doc.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(36),
        build: (ctx) => [
          // Header
          pw.Header(
            level: 0,
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Text(shopName.isEmpty ? 'SMART SAOJI' : shopName.toUpperCase(), 
                      style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold, color: PdfColors.teal)),
                    pw.Text('SALES STATEMENT', style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold, color: PdfColors.grey700)),
                  ],
                ),
                pw.SizedBox(height: 4),
                if (address.isNotEmpty) pw.Text(address, style: const pw.TextStyle(fontSize: 8)),
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Text('Tel: ${phone.isEmpty ? 'N/A' : phone} | PAN: ${pan.isEmpty ? 'N/A' : pan}', style: const pw.TextStyle(fontSize: 8)),
                    pw.Text('Period: $periodStr', style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold)),
                  ],
                ),
                pw.Divider(thickness: 1.5, color: PdfColors.teal),
                pw.SizedBox(height: 10),
              ],
            ),
          ),

          // Stats Cards
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              _statementStatCard('Total Prints', '$totalCount', PdfColors.blueGrey),
              _statementStatCard('Cash Total', 'Rs. ${cashTotal.toStringAsFixed(2)}', PdfColors.green),
              _statementStatCard('Bank QR Total', 'Rs. ${bankTotal.toStringAsFixed(2)}', PdfColors.orange),
              _statementStatCard('Esewa Total', 'Rs. ${esewaTotal.toStringAsFixed(2)}', PdfColors.purple),
            ],
          ),
          pw.SizedBox(height: 15),
          pw.Align(
            alignment: pw.Alignment.centerRight,
            child: pw.Container(
              padding: const pw.EdgeInsets.all(8),
              decoration: const pw.BoxDecoration(
                color: PdfColors.teal50,
                borderRadius: pw.BorderRadius.all(pw.Radius.circular(6)),
              ),
              child: pw.Text('GRAND TOTAL SALES: Rs. ${grandTotal.toStringAsFixed(2)}', 
                style: pw.TextStyle(fontSize: 11, fontWeight: pw.FontWeight.bold, color: PdfColors.teal900)),
            ),
          ),
          pw.SizedBox(height: 15),

          // Receipts Table
          pw.Text('Transaction Details', style: pw.TextStyle(fontSize: 11, fontWeight: pw.FontWeight.bold)),
          pw.SizedBox(height: 8),
          pw.Table(
            columnWidths: const {
              0: pw.FlexColumnWidth(2.5), // Date
              1: pw.FlexColumnWidth(3.0), // Receipt No
              2: pw.FlexColumnWidth(2.2), // Payment Method
              3: pw.FlexColumnWidth(4.3), // Items Sold
              4: pw.FlexColumnWidth(2.5), // Total Amount
            },
            children: [
              // Header
              pw.TableRow(
                decoration: const pw.BoxDecoration(color: PdfColors.teal),
                children: [
                  _tableHeaderCell('Date'),
                  _tableHeaderCell('Receipt Number'),
                  _tableHeaderCell('Paid Via'),
                  _tableHeaderCell('Items Sold'),
                  _tableHeaderCell('Total (Rs.)', alignRight: true),
                ],
              ),
              // Rows
              ...receipts.map((r) {
                final dateStr = r['created_at'] != null 
                  ? DateTime.parse(r['created_at'] as String).toLocal().toString().substring(0, 16)
                  : 'N/A';
                final receiptNo = r['receipt_number'] as String? ?? 'N/A';
                final pm = r['payment_method'] as String? ?? 'Cash';
                final tot = ((r['total'] as num?)?.toDouble() ?? 0.0).toStringAsFixed(2);
                
                // Get list of items preview
                String itemsPreview = '';
                try {
                  final list = r['items'] as List<dynamic>? ?? [];
                  itemsPreview = list.map((i) => "${i['name']} (${i['qty']})").join(', ');
                  if (itemsPreview.length > 30) {
                    itemsPreview = '${itemsPreview.substring(0, 28)}...';
                  }
                } catch (_) {
                  itemsPreview = 'Items';
                }

                return pw.TableRow(
                  decoration: const pw.BoxDecoration(
                    border: pw.Border(bottom: pw.BorderSide(color: PdfColors.grey300, width: 0.5)),
                  ),
                  children: [
                    _tableCell(dateStr),
                    _tableCell(receiptNo),
                    _tableCell(pm),
                    _tableCell(itemsPreview),
                    _tableCell(tot, alignRight: true),
                  ],
                );
              }),
            ],
          ),
        ],
        footer: (ctx) => pw.Container(
          alignment: pw.Alignment.centerRight,
          margin: const pw.EdgeInsets.only(top: 20),
          child: pw.Text('Page ${ctx.pageNumber} of ${ctx.pagesCount}', style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey500)),
        ),
      ),
    );
    return doc.save();
  }

  static pw.Widget _statementStatCard(String title, String value, PdfColor color) {
    return pw.Container(
      width: 115,
      padding: const pw.EdgeInsets.all(8),
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: color, width: 1),
        borderRadius: const pw.BorderRadius.all(pw.Radius.circular(6)),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(title, style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey600)),
          pw.SizedBox(height: 4),
          pw.Text(value, style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold, color: color)),
        ],
      ),
    );
  }

  static pw.Widget _tableHeaderCell(String text, {bool alignRight = false}) {
    return pw.Padding(
      padding: const pw.EdgeInsets.all(5),
      child: pw.Text(
        text,
        style: pw.TextStyle(fontWeight: pw.FontWeight.bold, color: PdfColors.white, fontSize: 8),
        textAlign: alignRight ? pw.TextAlign.right : pw.TextAlign.left,
      ),
    );
  }

  static pw.Widget _tableCell(String text, {bool alignRight = false}) {
    return pw.Padding(
      padding: const pw.EdgeInsets.all(5),
      child: pw.Text(
        text,
        style: const pw.TextStyle(fontSize: 8),
        textAlign: alignRight ? pw.TextAlign.right : pw.TextAlign.left,
      ),
    );
  }
}
