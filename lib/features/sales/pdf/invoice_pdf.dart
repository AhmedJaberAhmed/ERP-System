import 'dart:typed_data';

import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

import '../../../core/utils/format.dart';
import '../domain/entities/sales_invoice.dart';



/// Builds the A4 PDF of one invoice.
class InvoicePdf {
  InvoicePdf._();

  static const _accent = PdfColors.teal700;
  static const _muted = PdfColors.grey700;
  static const _line = PdfColors.grey400;

  /// Noto fonts (Latin + Arabic) are downloaded once; if that fails
  /// (offline) we fall back to the built-in Latin font.
  static Future<pw.ThemeData> _theme() async {
    try {
      final base = await PdfGoogleFonts.notoSansRegular();
      final bold = await PdfGoogleFonts.notoSansBold();
      final arabic = await PdfGoogleFonts.notoSansArabicRegular();
      return pw.ThemeData.withFont(base: base, bold: bold, fontFallback: [arabic]);
    } catch (_) {
      return pw.ThemeData.base();
    }
  }

  static Future<Uint8List> build(
      SalesInvoice inv, {
        required String companyName,
        required String currency,
      }) async {
    final theme = await _theme();
    final doc = pw.Document(title: inv.number ?? 'Invoice', author: companyName);

    doc.addPage(
      pw.MultiPage(
        pageTheme: pw.PageTheme(
          pageFormat: PdfPageFormat.a4,
          margin: pw.EdgeInsets.all(36),
          theme: theme,
        ),
        footer: (c) => pw.Container(
          alignment: pw.Alignment.centerRight,
          child: pw.Text(
            'Page ${c.pageNumber} of ${c.pagesCount}',
            style: pw.TextStyle(fontSize: 8, color: _muted),
          ),
        ),
        build: (c) => [
          _header(inv, companyName),
          pw.SizedBox(height: 20),
          _info(inv),
          pw.SizedBox(height: 14),
          _items(inv),
          pw.SizedBox(height: 12),
          _totals(inv, currency),
          if (inv.payments.isNotEmpty) ...[
            pw.SizedBox(height: 18),
            _payments(inv),
          ],
          if (inv.note != null && inv.note!.isNotEmpty) ...[
            pw.SizedBox(height: 18),
            pw.Text('Note', style: pw.TextStyle(fontSize: 8, color: _muted)),
            pw.Text(inv.note!, style: pw.TextStyle(fontSize: 10)),
          ],
          pw.SizedBox(height: 28),
          pw.Center(
            child: pw.Text('Thank you for your business.',
                style: pw.TextStyle(fontSize: 9, color: _muted)),
          ),
        ],
      ),
    );

    return doc.save();
  }

  static pw.Widget _header(SalesInvoice inv, String companyName) => pw.Row(
    crossAxisAlignment: pw.CrossAxisAlignment.start,
    mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
    children: [
      pw.Expanded(
        child: pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Text(companyName,
                style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold)),
            pw.SizedBox(height: 2),
            pw.Text('Sales invoice',
                style: pw.TextStyle(fontSize: 10, color: _muted)),
          ],
        ),
      ),
      pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.end,
        children: [
          pw.Text('INVOICE',
              style: pw.TextStyle(
                  fontSize: 22, fontWeight: pw.FontWeight.bold, color: _accent)),
          pw.Text(inv.number ?? '', style: pw.TextStyle(fontSize: 11)),
          if (inv.payStatus == PaymentStatus.paid)
            pw.Container(
              margin: pw.EdgeInsets.only(top: 6),
              padding: pw.EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: pw.BoxDecoration(
                border: pw.Border.all(color: PdfColors.green700, width: 1.5),
                borderRadius: pw.BorderRadius.circular(4),
              ),
              child: pw.Text('PAID',
                  style: pw.TextStyle(
                      fontSize: 12,
                      fontWeight: pw.FontWeight.bold,
                      color: PdfColors.green700)),
            ),
        ],
      ),
    ],
  );

  static pw.Widget _kv(String k, String v) => pw.Padding(
    padding: pw.EdgeInsets.only(bottom: 6),
    child: pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(k, style: pw.TextStyle(fontSize: 8, color: _muted)),
        pw.Text(v, style: pw.TextStyle(fontSize: 11)),
      ],
    ),
  );

  static pw.Widget _info(SalesInvoice inv) => pw.Row(
    crossAxisAlignment: pw.CrossAxisAlignment.start,
    children: [
      pw.Expanded(child: _kv('Bill to', inv.customerName ?? 'Walk-in customer')),
      pw.Expanded(
        child: pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            _kv('Invoice date', fmtDate(inv.invoiceDate)),
            if (inv.dueDate != null) _kv('Due date', fmtDate(inv.dueDate!)),
            _kv('Payment status', inv.payStatus.label),
          ],
        ),
      ),
    ],
  );

  static pw.Widget _cell(
      String text, {
        bool bold = false,
        bool right = false,
        PdfColor? color,
      }) =>
      pw.Container(
        alignment: right ? pw.Alignment.centerRight : pw.Alignment.centerLeft,
        padding: pw.EdgeInsets.symmetric(horizontal: 6, vertical: 5),
        child: pw.Text(
          text,
          style: pw.TextStyle(
            fontSize: 9,
            fontWeight: bold ? pw.FontWeight.bold : pw.FontWeight.normal,
            color: color,
          ),
        ),
      );

  static pw.Widget _items(SalesInvoice inv) {
    const white = PdfColors.white;
    return pw.Table(
      border: pw.TableBorder(
        horizontalInside: pw.BorderSide(color: _line, width: 0.5),
        bottom: pw.BorderSide(color: _line, width: 0.5),
      ),
      columnWidths: {
        0: pw.FixedColumnWidth(24),
        1: pw.FlexColumnWidth(4),
        2: pw.FlexColumnWidth(1.5),
        3: pw.FlexColumnWidth(1.5),
        4: pw.FlexColumnWidth(1.3),
        5: pw.FlexColumnWidth(1.6),
      },
      children: [
        pw.TableRow(
          repeat: true,
          decoration: pw.BoxDecoration(color: _accent),
          children: [
            _cell('#', bold: true, color: white),
            _cell('Item', bold: true, color: white),
            _cell('Qty', bold: true, right: true, color: white),
            _cell('Unit price', bold: true, right: true, color: white),
            _cell('Discount', bold: true, right: true, color: white),
            _cell('Total', bold: true, right: true, color: white),
          ],
        ),
        for (var i = 0; i < inv.items.length; i++)
          pw.TableRow(
            children: [
              _cell('${i + 1}'),
              pw.Container(
                padding: pw.EdgeInsets.symmetric(horizontal: 6, vertical: 5),
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text(inv.items[i].productName,
                        style: pw.TextStyle(fontSize: 9)),
                    pw.Text(inv.items[i].sku,
                        style: pw.TextStyle(fontSize: 7, color: _muted)),
                  ],
                ),
              ),
              _cell('${fmtQty(inv.items[i].quantity)} ${inv.items[i].unit}', right: true),
              _cell(fmtMoney(inv.items[i].unitPrice), right: true),
              _cell(inv.items[i].discount > 0 ? fmtMoney(inv.items[i].discount) : '-',
                  right: true),
              _cell(fmtMoney(inv.items[i].lineTotal), right: true, bold: true),
            ],
          ),
      ],
    );
  }

  static pw.Widget _totals(SalesInvoice inv, String currency) {
    pw.Widget row(String l, String v,
        {bool bold = false, double size = 10, PdfColor? color}) =>
        pw.Padding(
          padding: pw.EdgeInsets.symmetric(vertical: 2),
          child: pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Text(l,
                  style: pw.TextStyle(
                      fontSize: size,
                      fontWeight: bold ? pw.FontWeight.bold : pw.FontWeight.normal)),
              pw.Text(v,
                  style: pw.TextStyle(
                      fontSize: size,
                      color: color,
                      fontWeight: bold ? pw.FontWeight.bold : pw.FontWeight.normal)),
            ],
          ),
        );

    return pw.Align(
      alignment: pw.Alignment.centerRight,
      child: pw.Container(
        width: 230,
        child: pw.Column(
          children: [
            row('Subtotal', fmtMoney(inv.subtotal)),
            if (inv.discount > 0) row('Discount', '-${fmtMoney(inv.discount)}'),
            row('Tax', fmtMoney(inv.taxTotal)),
            pw.Divider(color: _line),
            row('Total ($currency)', fmtMoney(inv.total), bold: true, size: 12),
            row('Paid', fmtMoney(inv.paidAmount)),
            row('Balance due', fmtMoney(inv.balance),
                bold: true,
                color: inv.balance > 0 ? PdfColors.red700 : PdfColors.green700),
          ],
        ),
      ),
    );
  }

  static pw.Widget _payments(SalesInvoice inv) => pw.Column(
    crossAxisAlignment: pw.CrossAxisAlignment.start,
    children: [
      pw.Text('Payments',
          style: pw.TextStyle(fontSize: 11, fontWeight: pw.FontWeight.bold)),
      pw.SizedBox(height: 6),
      pw.Table(
        border: pw.TableBorder(
          horizontalInside: pw.BorderSide(color: _line, width: 0.5),
          bottom: pw.BorderSide(color: _line, width: 0.5),
        ),
        columnWidths: {
          0: pw.FlexColumnWidth(2),
          1: pw.FlexColumnWidth(2),
          2: pw.FlexColumnWidth(2),
          3: pw.FlexColumnWidth(1.5),
        },
        children: [
          pw.TableRow(
            decoration: pw.BoxDecoration(color: PdfColors.grey200),
            children: [
              _cell('Date', bold: true),
              _cell('Method', bold: true),
              _cell('Reference', bold: true),
              _cell('Amount', bold: true, right: true),
            ],
          ),
          for (final p in inv.payments)
            pw.TableRow(
              children: [
                _cell(fmtDateTime(p.paidAt)),
                _cell(p.method.label),
                _cell(p.reference ?? '-'),
                _cell(fmtMoney(p.amount), right: true),
              ],
            ),
        ],
      ),
    ],
  );
}