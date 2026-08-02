import 'dart:typed_data';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:business_sahaj_erp/data/local/collections/order_collection.dart';
import 'package:business_sahaj_erp/data/local/collections/invoice_collection.dart';
import 'package:business_sahaj_erp/data/local/collections/invoice_item_collection.dart';
import 'package:business_sahaj_erp/core/services/amount_to_words_service.dart';
import 'package:business_sahaj_erp/core/errors/exceptions.dart';

class PdfService {
  final AmountToWordsService _amountToWordsService = AmountToWordsService();

  static final PdfColor primaryCyan = PdfColor.fromHex('#00A8E8');
  static final PdfColor darkNavy = PdfColor.fromHex('#0D1B2A');
  static final PdfColor oceanBlue = PdfColor.fromHex('#007EA7');
  static final PdfColor lightGreyBg = PdfColor.fromHex('#F8F9FA');
  static final PdfColor accentOrange = PdfColor.fromHex('#FF6B35');

  /// Generates an executive PDF document for a Sales Order
  Future<Uint8List> generateOrderPdf(Order order, {String companyName = 'Business Sahaj ERP'}) async {
    try {
      final pdf = pw.Document();

      pdf.addPage(
        pw.MultiPage(
          pageFormat: PdfPageFormat.a4,
          margin: const pw.EdgeInsets.all(24),
          build: (context) {
            return [
              _buildExecutiveHeader(
                title: 'SALES ORDER',
                docNumber: order.orderNumber ?? 'SO-01',
                dateStr: order.orderDate?.toIso8601String().substring(0, 10) ?? 'N/A',
                companyName: companyName,
                companyGst: '27AAAAA1111A1Z1',
                companyAddress: '123 Business Hub, MG Road, Mumbai, MH',
                companyPhone: '+91 98765 43210',
              ),
              pw.SizedBox(height: 16),
              _buildBillToSection(
                name: order.partyName ?? 'N/A',
                gst: order.gstNumber ?? 'N/A',
                phone: order.mobileNumber ?? 'N/A',
                address: order.locationAddress ?? 'N/A',
              ),
              pw.SizedBox(height: 16),
              _buildOrderItemsTable(order),
              pw.SizedBox(height: 16),
              _buildExecutiveSummary(
                subtotal: order.subtotal ?? 0.0,
                discount: order.discountAmount ?? 0.0,
                gst: order.totalGST ?? 0.0,
                roundOff: order.roundOff ?? 0.0,
                grandTotal: order.grandTotal ?? 0.0,
                cgst: (order.totalGST ?? 0.0) / 2.0,
                sgst: (order.totalGST ?? 0.0) / 2.0,
                igst: 0.0,
              ),
              pw.SizedBox(height: 24),
              _buildExecutiveFooter(order.remarks ?? 'Thank you for your business order.'),
            ];
          },
        ),
      );

      return pdf.save();
    } catch (e) {
      throw PDFException('Failed to generate Order PDF: $e');
    }
  }

  /// Generates an executive GST Tax Invoice PDF matching modern blue theme
  Future<Uint8List> generateInvoicePdf(Invoice invoice, {
    List<InvoiceItem>? items,
    String companyName = 'Business Sahaj ERP',
    String companyGst = '27AAAAA1111A1Z1',
    String companyAddress = '123 Business Hub, MG Road, Mumbai, MH, 400001',
    String companyPhone = '+91 98765 43210',
  }) async {
    try {
      final pdf = pw.Document();
      final actualItems = items ?? invoice.invoiceItems.toList();

      pdf.addPage(
        pw.MultiPage(
          pageFormat: PdfPageFormat.a4,
          margin: const pw.EdgeInsets.all(24),
          build: (context) {
            return [
              _buildExecutiveHeader(
                title: invoice.invoiceType?.toUpperCase() ?? 'TAX INVOICE',
                docNumber: invoice.invoiceNumber ?? 'N/A',
                dateStr: invoice.invoiceDate?.toIso8601String().substring(0, 10) ?? 'N/A',
                companyName: companyName,
                companyGst: companyGst,
                companyAddress: companyAddress,
                companyPhone: companyPhone,
              ),
              pw.SizedBox(height: 16),

              _buildBillToSection(
                name: invoice.partyName ?? 'N/A',
                gst: invoice.gstNumber ?? 'N/A',
                phone: 'N/A',
                address: invoice.address ?? 'N/A',
              ),
              pw.SizedBox(height: 16),

              _buildInvoiceItemsTable(invoice, actualItems),
              pw.SizedBox(height: 16),

              _buildExecutiveSummary(
                subtotal: invoice.subtotal ?? 0.0,
                discount: invoice.discountAmount ?? 0.0,
                gst: invoice.totalGST ?? 0.0,
                roundOff: invoice.roundOff ?? 0.0,
                grandTotal: invoice.grandTotal ?? 0.0,
                cgst: invoice.cgstAmount ?? 0.0,
                sgst: invoice.sgstAmount ?? 0.0,
                igst: invoice.igstAmount ?? 0.0,
              ),
              pw.SizedBox(height: 24),

              _buildExecutiveFooter(invoice.remarks ?? 'Thank you for your business. Goods once sold will not be taken back.'),
            ];
          },
        ),
      );

      return pdf.save();
    } catch (e) {
      throw PDFException('Failed to generate Invoice PDF: $e');
    }
  }

  /// Helper to share or print PDF directly using printing package
  Future<void> printOrSharePdf(Uint8List pdfData, String filename) async {
    try {
      await Printing.layoutPdf(
        onLayout: (PdfPageFormat format) async => pdfData,
        name: filename,
      );
    } catch (e) {
      throw PDFException('Failed to layout/print PDF: $e');
    }
  }

  // --- Executive Header Builder ---
  pw.Widget _buildExecutiveHeader({
    required String title,
    required String docNumber,
    required String dateStr,
    required String companyName,
    required String companyGst,
    required String companyAddress,
    required String companyPhone,
  }) {
    return pw.Container(
      decoration: pw.BoxDecoration(
        border: pw.Border(bottom: pw.BorderSide(color: primaryCyan, width: 2)),
      ),
      padding: const pw.EdgeInsets.bottom(12),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Row(
                children: [
                  pw.Container(
                    width: 28,
                    height: 28,
                    decoration: pw.BoxDecoration(
                      color: primaryCyan,
                      borderRadius: const pw.BorderRadius.all(pw.Radius.circular(6)),
                    ),
                    child: pw.Center(
                      child: pw.Text('S', style: pw.TextStyle(color: PdfColors.white, fontWeight: pw.FontWeight.bold, fontSize: 16)),
                    ),
                  ),
                  pw.SizedBox(width: 10),
                  pw.Text(companyName.toUpperCase(), style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold, color: darkNavy)),
                ],
              ),
              pw.SizedBox(height: 6),
              pw.Text(companyAddress, style: const pw.TextStyle(fontSize: 8.5, color: PdfColors.grey700)),
              pw.Text('GSTIN: $companyGst | Phone: $companyPhone', style: pw.TextStyle(fontSize: 8.5, fontWeight: pw.FontWeight.bold, color: oceanBlue)),
            ],
          ),
          pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.end,
            children: [
              pw.Container(
                padding: const pw.EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: pw.BoxDecoration(
                  color: darkNavy,
                  borderRadius: const pw.BorderRadius.all(pw.Radius.circular(4)),
                ),
                child: pw.Text(title, style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold, color: PdfColors.white)),
              ),
              pw.SizedBox(height: 8),
              pw.Row(
                children: [
                  pw.Text('Invoice No: ', style: const pw.TextStyle(fontSize: 8.5, color: PdfColors.grey700)),
                  pw.Text('#$docNumber', style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold, color: darkNavy)),
                ],
              ),
              pw.Row(
                children: [
                  pw.Text('Date: ', style: const pw.TextStyle(fontSize: 8.5, color: PdfColors.grey700)),
                  pw.Text(dateStr, style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold, color: darkNavy)),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  // --- Bill To Section ---
  pw.Widget _buildBillToSection({
    required String name,
    required String gst,
    required String phone,
    required String address,
  }) {
    return pw.Container(
      width: double.infinity,
      padding: const pw.EdgeInsets.all(12),
      decoration: pw.BoxDecoration(
        color: lightGreyBg,
        borderRadius: const pw.BorderRadius.all(pw.Radius.circular(6)),
        border: pw.Border.all(color: PdfColors.grey300, width: 0.5),
      ),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text('Billed To (Customer):', style: pw.TextStyle(fontSize: 8.5, color: PdfColors.grey600, fontWeight: pw.FontWeight.bold)),
              pw.SizedBox(height: 4),
              pw.Text(name, style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold, color: darkNavy)),
              if (gst.isNotEmpty && gst != 'N/A')
                pw.Text('GSTIN: $gst', style: pw.TextStyle(fontSize: 8.5, fontWeight: pw.FontWeight.bold, color: oceanBlue)),
            ],
          ),
          pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.end,
            children: [
              pw.Text('Billing Address:', style: pw.TextStyle(fontSize: 8.5, color: PdfColors.grey600, fontWeight: pw.FontWeight.bold)),
              pw.SizedBox(height: 4),
              pw.Text(address.isNotEmpty ? address : 'Main Market Area', style: const pw.TextStyle(fontSize: 8.5, color: PdfColors.grey800)),
            ],
          ),
        ],
      ),
    );
  }

  // --- Invoice Items Table ---
  pw.Widget _buildInvoiceItemsTable(Invoice invoice, List<InvoiceItem> items) {
    final headers = ['S.NO', 'PRODUCT DESCRIPTION', 'HSN', 'QTY', 'RATE (Rs.)', 'DISC (Rs.)', 'TOTAL (Rs.)'];

    int index = 1;
    final data = items.map<List<dynamic>>((item) {
      final double qty = item.quantity ?? 0.0;
      return [
        '${index++}',
        item.itemName ?? 'Item',
        item.hsnCode ?? '-',
        '${qty % 1 == 0 ? qty.toInt() : qty} ${item.unit ?? "PCS"}',
        'Rs. ${item.rate?.toStringAsFixed(2) ?? "0.00"}',
        'Rs. ${item.discount?.toStringAsFixed(2) ?? "0.00"}',
        'Rs. ${item.totalAmount?.toStringAsFixed(2) ?? "0.00"}',
      ];
    }).toList();

    return pw.Table.fromTextArray(
      headers: headers,
      data: data,
      border: pw.TableBorder.all(color: PdfColors.grey300, width: 0.5),
      headerStyle: pw.TextStyle(fontSize: 8.5, fontWeight: pw.FontWeight.bold, color: PdfColors.white),
      headerDecoration: pw.BoxDecoration(color: primaryCyan),
      cellStyle: const pw.TextStyle(fontSize: 8.0),
      cellAlignment: pw.Alignment.centerLeft,
      rowDecoration: const pw.BoxDecoration(color: PdfColors.white),
    );
  }

  // --- Order Items Table ---
  pw.Widget _buildOrderItemsTable(Order order) {
    final headers = ['S.NO', 'PRODUCT DESCRIPTION', 'HSN', 'QTY', 'RATE (Rs.)', 'DISC (Rs.)', 'TOTAL (Rs.)'];

    int index = 1;
    final data = order.orderItems.map<List<dynamic>>((item) {
      final double qty = item.quantity ?? 0.0;
      return [
        '${index++}',
        item.itemName ?? 'N/A',
        item.hsnCode ?? 'N/A',
        '${qty % 1 == 0 ? qty.toInt() : qty} ${item.unit ?? "PCS"}',
        'Rs. ${item.rate?.toStringAsFixed(2) ?? "0.00"}',
        'Rs. ${item.discountAmount?.toStringAsFixed(2) ?? "0.00"}',
        'Rs. ${item.totalAmount?.toStringAsFixed(2) ?? "0.00"}',
      ];
    }).toList();

    return pw.Table.fromTextArray(
      headers: headers,
      data: data,
      border: pw.TableBorder.all(color: PdfColors.grey300, width: 0.5),
      headerStyle: pw.TextStyle(fontSize: 8.5, fontWeight: pw.FontWeight.bold, color: PdfColors.white),
      headerDecoration: pw.BoxDecoration(color: primaryCyan),
      cellStyle: const pw.TextStyle(fontSize: 8.0),
      cellAlignment: pw.Alignment.centerLeft,
      rowDecoration: const pw.BoxDecoration(color: PdfColors.white),
    );
  }

  // --- Executive Summary & Highlight Total ---
  pw.Widget _buildExecutiveSummary({
    required double subtotal,
    required double discount,
    required double gst,
    required double roundOff,
    required double grandTotal,
    required double cgst,
    required double sgst,
    required double igst,
  }) {
    final words = _amountToWordsService.convertToWords(grandTotal);

    return pw.Row(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        // Left Column: Words & Payment Details & Terms
        pw.Expanded(
          flex: 3,
          child: pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text('Amount in Words:', style: pw.TextStyle(fontSize: 8.5, fontWeight: pw.FontWeight.bold, color: darkNavy)),
              pw.Text(words, style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey800)),
              pw.SizedBox(height: 10),
              pw.Text('Payment Bank Details:', style: pw.TextStyle(fontSize: 8.5, fontWeight: pw.FontWeight.bold, color: darkNavy)),
              pw.Text('Bank Name: State Bank of India', style: const pw.TextStyle(fontSize: 7.5, color: PdfColors.grey700)),
              pw.Text('A/C No: 1234 5678 9101', style: const pw.TextStyle(fontSize: 7.5, color: PdfColors.grey700)),
              pw.Text('IFSC / Branch: SBIN0001234 / Main Market', style: const pw.TextStyle(fontSize: 7.5, color: PdfColors.grey700)),
              if (cgst > 0 || sgst > 0 || igst > 0) ...[
                pw.SizedBox(height: 6),
                pw.Text('Tax Split: CGST: Rs. ${cgst.toStringAsFixed(2)} | SGST: Rs. ${sgst.toStringAsFixed(2)} | IGST: Rs. ${igst.toStringAsFixed(2)}', style: const pw.TextStyle(fontSize: 7.5, color: PdfColors.grey700)),
              ],
            ],
          ),
        ),
        pw.SizedBox(width: 20),
        // Right Column: Summary Table + Solid Cyan Total Box
        pw.Expanded(
          flex: 2,
          child: pw.Column(
            children: [
              _buildSummaryRow('Subtotal:', 'Rs. ${subtotal.toStringAsFixed(2)}'),
              _buildSummaryRow('Discount:', 'Rs. ${discount.toStringAsFixed(2)}'),
              _buildSummaryRow('Tax Amount:', 'Rs. ${gst.toStringAsFixed(2)}'),
              _buildSummaryRow('Round Off:', 'Rs. ${roundOff.toStringAsFixed(2)}'),
              pw.SizedBox(height: 6),
              pw.Container(
                padding: const pw.EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: pw.BoxDecoration(
                  color: primaryCyan,
                  borderRadius: const pw.BorderRadius.all(pw.Radius.circular(4)),
                ),
                child: pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Text('GRAND TOTAL:', style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold, color: PdfColors.white)),
                    pw.Text('Rs. ${grandTotal.toStringAsFixed(2)}', style: pw.TextStyle(fontSize: 11, fontWeight: pw.FontWeight.bold, color: PdfColors.white)),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  pw.Widget _buildSummaryRow(String label, String value) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 2.5),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text(label, style: const pw.TextStyle(fontSize: 8.5, color: PdfColors.grey700)),
          pw.Text(value, style: pw.TextStyle(fontSize: 8.5, fontWeight: pw.FontWeight.bold, color: darkNavy)),
        ],
      ),
    );
  }

  // --- Executive Footer Section ---
  pw.Widget _buildExecutiveFooter(String remarks) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          crossAxisAlignment: pw.CrossAxisAlignment.end,
          children: [
            pw.Expanded(
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text('Terms & Conditions:', style: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold, color: darkNavy)),
                  pw.SizedBox(height: 2),
                  pw.Text(remarks, style: const pw.TextStyle(fontSize: 7.5, color: PdfColors.grey700)),
                ],
              ),
            ),
            pw.SizedBox(width: 30),
            pw.Column(
              children: [
                pw.Container(
                  width: 130,
                  decoration: const pw.BoxDecoration(
                    border: pw.Border(bottom: pw.BorderSide(color: PdfColors.grey400, width: 1)),
                  ),
                ),
                pw.SizedBox(height: 4),
                pw.Text('Authorised Signatory', style: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold, color: darkNavy)),
              ],
            ),
          ],
        ),
      ],
    );
  }
}
