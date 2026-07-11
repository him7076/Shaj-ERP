import 'dart:typed_data';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:business_sahaj_erp/data/local/collections/order_collection.dart';
import 'package:business_sahaj_erp/data/local/collections/invoice_collection.dart';
import 'package:business_sahaj_erp/core/services/amount_to_words_service.dart';
import 'package:business_sahaj_erp/core/errors/exceptions.dart';
import 'package:business_sahaj_erp/core/services/logger_service.dart';

class PdfService {
  final AmountToWordsService _amountToWordsService = AmountToWordsService();

  /// Generates a professional PDF document for a Sales Order
  Future<Uint8List> generateOrderPdf(Order order, {String companyName = 'Business Sahaj ERP'}) async {
    try {
      final pdf = pw.Document();

      pdf.addPage(
        pw.MultiPage(
          pageFormat: PdfPageFormat.a4,
          build: (context) {
            return [
              _buildHeader(order.orderNumber ?? 'N/A', 'Sales Order', order.orderDate, companyName),
              pw.SizedBox(height: 20),
              _buildPartyDetailsSection(
                name: order.partyName ?? 'N/A',
                gst: order.gstNumber ?? 'N/A',
                mobile: order.mobileNumber ?? 'N/A',
                address: order.locationAddress ?? 'N/A',
              ),
              pw.SizedBox(height: 20),
              _buildOrderItemsTable(order),
              pw.SizedBox(height: 20),
              _buildFinancialSummary(
                subtotal: order.subtotal ?? 0.0,
                discount: order.discountAmount ?? 0.0,
                gst: order.totalGST ?? 0.0,
                roundOff: order.roundOff ?? 0.0,
                grandTotal: order.grandTotal ?? 0.0,
                cgst: (order.totalGST ?? 0.0) / 2.0, // mock splits if not stored
                sgst: (order.totalGST ?? 0.0) / 2.0,
                igst: 0.0,
              ),
              pw.SizedBox(height: 30),
              _buildFooterSection(order.remarks ?? 'Thank you for your order.'),
            ];
          },
        ),
      );

      return pdf.save();
    } catch (e) {
      throw PDFException('Failed to generate Order PDF: $e');
    }
  }

  /// Generates a professional GST Tax Invoice PDF
  Future<Uint8List> generateInvoicePdf(Invoice invoice, {
    String companyName = 'Business Sahaj ERP',
    String companyGst = '27AAAAA1111A1Z1',
    String companyAddress = '123 Business Hub, MG Road, Mumbai, MH, 400001',
    String companyPhone = '+91 98765 43210',
  }) async {
    try {
      final pdf = pw.Document();

      pdf.addPage(
        pw.MultiPage(
          pageFormat: PdfPageFormat.a4,
          build: (context) {
            return [
              // Company Header info
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text(companyName, style: pw.TextStyle(fontSize: 22, fontWeight: pw.FontWeight.bold)),
                      pw.Text(companyAddress, style: const pw.TextStyle(fontSize: 10)),
                      pw.Text('GSTIN: $companyGst', style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold)),
                      pw.Text('Phone: $companyPhone', style: const pw.TextStyle(fontSize: 10)),
                    ],
                  ),
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.end,
                    children: [
                      pw.Text(invoice.invoiceType ?? 'Tax Invoice', style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold, color: PdfColors.blueGrey)),
                      pw.Text('Invoice No: ${invoice.invoiceNumber ?? "N/A"}', style: pw.TextStyle(fontSize: 11, fontWeight: pw.FontWeight.bold)),
                      pw.Text('Date: ${invoice.invoiceDate?.toIso8601String().substring(0, 10) ?? "N/A"}', style: const pw.TextStyle(fontSize: 10)),
                      if (invoice.sourceOrderNumber != null)
                        pw.Text('Ref Order: ${invoice.sourceOrderNumber}', style: const pw.TextStyle(fontSize: 9)),
                    ],
                  ),
                ],
              ),
              pw.Divider(thickness: 1.5, color: PdfColors.blueGrey),
              pw.SizedBox(height: 15),

              // Party Billing Info
              _buildPartyDetailsSection(
                name: invoice.partyName ?? 'N/A',
                gst: invoice.gstNumber ?? 'N/A',
                mobile: 'N/A',
                address: invoice.address ?? 'N/A',
              ),
              pw.SizedBox(height: 15),

              // Items Table
              _buildInvoiceItemsTable(invoice),
              pw.SizedBox(height: 15),

              // Summary
              _buildFinancialSummary(
                subtotal: invoice.subtotal ?? 0.0,
                discount: invoice.discountAmount ?? 0.0,
                gst: invoice.totalGST ?? 0.0,
                roundOff: invoice.roundOff ?? 0.0,
                grandTotal: invoice.grandTotal ?? 0.0,
                cgst: invoice.cgstAmount ?? 0.0,
                sgst: invoice.sgstAmount ?? 0.0,
                igst: invoice.igstAmount ?? 0.0,
              ),
              pw.SizedBox(height: 25),

              // Signatures
              _buildFooterSection(invoice.remarks ?? 'Goods once sold will not be taken back.'),
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

  // Header Builder
  pw.Widget _buildHeader(String number, String title, DateTime? date, String companyName) {
    return pw.Row(
      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
      children: [
        pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Text(companyName, style: pw.TextStyle(fontSize: 20, fontWeight: pw.FontWeight.bold)),
            pw.Text('Authorized Distributor', style: const pw.TextStyle(fontSize: 10)),
          ],
        ),
        pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.end,
          children: [
            pw.Text(title, style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold, color: PdfColors.blue)),
            pw.Text('No: $number', style: pw.TextStyle(fontSize: 11, fontWeight: pw.FontWeight.bold)),
            if (date != null)
              pw.Text('Date: ${date.toIso8601String().substring(0, 10)}', style: const pw.TextStyle(fontSize: 10)),
          ],
        ),
      ],
    );
  }

  // Party details Builder
  pw.Widget _buildPartyDetailsSection({
    required String name,
    required String gst,
    required String mobile,
    required String address,
  }) {
    return pw.Container(
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: PdfColors.grey400),
        borderRadius: const pw.BorderRadius.all(pw.Radius.circular(6)),
      ),
      padding: const pw.EdgeInsets.all(10),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text('BILL TO:', style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold, color: PdfColors.grey700)),
          pw.SizedBox(height: 4),
          pw.Text(name, style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold)),
          pw.Text('GSTIN: $gst', style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold)),
          if (mobile != 'N/A') pw.Text('Mobile: $mobile', style: const pw.TextStyle(fontSize: 10)),
          pw.Text('Address: $address', style: const pw.TextStyle(fontSize: 9)),
        ],
      ),
    );
  }

  // Order Table Builder
  pw.Widget _buildOrderItemsTable(Order order) {
    final headers = ['Item Name', 'HSN', 'Qty', 'Rate', 'Disc %', 'GST %', 'Total'];
    final data = order.orderItems.map((item) {
      return [
        item.itemName ?? 'N/A',
        item.hsnCode ?? 'N/A',
        item.quantity?.toStringAsFixed(0) ?? '0',
        '₹${item.rate?.toStringAsFixed(2) ?? "0.00"}',
        '${item.discountPercent?.toStringAsFixed(0) ?? "0"}%',
        '${item.gstPercent?.toStringAsFixed(0) ?? "0"}%',
        '₹${item.totalAmount?.toStringAsFixed(2) ?? "0.00"}',
      ];
    }).toList();

    return pw.Table.fromTextArray(
      headers: headers,
      data: data,
      border: pw.TableBorder.all(color: PdfColors.grey300),
      headerStyle: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold),
      cellStyle: const pw.TextStyle(fontSize: 9),
    );
  }

  // Invoice Table Builder
  pw.Widget _buildInvoiceItemsTable(Invoice invoice) {
    final headers = ['Item Name', 'HSN', 'Qty', 'Rate', 'Disc Amt', 'GST Rate', 'Total'];
    final data = invoice.invoiceItems.map((item) {
      return [
        item.itemName ?? 'N/A',
        item.hsnCode ?? 'N/A',
        item.quantity?.toStringAsFixed(0) ?? '0',
        '₹${item.rate?.toStringAsFixed(2) ?? "0.00"}',
        '₹${item.discount?.toStringAsFixed(2) ?? "0.00"}',
        '${item.gstRate?.toStringAsFixed(0) ?? "0"}%',
        '₹${item.totalAmount?.toStringAsFixed(2) ?? "0.00"}',
      ];
    }).toList();

    return pw.Table.fromTextArray(
      headers: headers,
      data: data,
      border: pw.TableBorder.all(color: PdfColors.grey300),
      headerStyle: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold),
      cellStyle: const pw.TextStyle(fontSize: 9),
    );
  }

  // Financial summary Builder
  pw.Widget _buildFinancialSummary({
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
        // Left - Amount in Words & Tax split
        pw.Expanded(
          flex: 3,
          child: pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text('Amount in Words:', style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold)),
              pw.Text(words, style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey800)),
              pw.SizedBox(height: 12),
              pw.Text('Tax Split Summary:', style: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold, color: PdfColors.grey700)),
              if (cgst > 0) pw.Text('CGST: ₹${cgst.toStringAsFixed(2)}', style: const pw.TextStyle(fontSize: 8)),
              if (sgst > 0) pw.Text('SGST: ₹${sgst.toStringAsFixed(2)}', style: const pw.TextStyle(fontSize: 8)),
              if (igst > 0) pw.Text('IGST: ₹${igst.toStringAsFixed(2)}', style: const pw.TextStyle(fontSize: 8)),
            ],
          ),
        ),
        // Right - Calculations summary
        pw.Expanded(
          flex: 2,
          child: pw.Container(
            padding: const pw.EdgeInsets.all(8),
            decoration: pw.BoxDecoration(
              border: pw.Border.all(color: PdfColors.grey300),
              borderRadius: const pw.BorderRadius.all(pw.Radius.circular(6)),
            ),
            child: pw.Column(
              children: [
                _buildSummaryRow('Subtotal:', '₹${subtotal.toStringAsFixed(2)}'),
                _buildSummaryRow('Discount:', '₹${discount.toStringAsFixed(2)}'),
                _buildSummaryRow('Tax (GST):', '₹${gst.toStringAsFixed(2)}'),
                _buildSummaryRow('Round Off:', '₹${roundOff.toStringAsFixed(2)}'),
                pw.Divider(color: PdfColors.grey400),
                _buildSummaryRow('GRAND TOTAL:', '₹${grandTotal.toStringAsFixed(2)}', isBold: true),
              ],
            ),
          ),
        ),
      ],
    );
  }

  pw.Widget _buildSummaryRow(String label, String value, {bool isBold = false}) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 2),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text(label, style: pw.TextStyle(fontSize: 9, fontWeight: isBold ? pw.FontWeight.bold : pw.FontWeight.normal)),
          pw.Text(value, style: pw.TextStyle(fontSize: 9, fontWeight: isBold ? pw.FontWeight.bold : pw.FontWeight.normal)),
        ],
      ),
    );
  }

  // Footer Builder
  pw.Widget _buildFooterSection(String remarks) {
    return pw.Row(
      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
      crossAxisAlignment: pw.CrossAxisAlignment.end,
      children: [
        pw.Expanded(
          child: pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text('Terms & Remarks:', style: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold)),
              pw.Text(remarks, style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey700)),
            ],
          ),
        ),
        pw.SizedBox(width: 40),
        pw.Column(
          children: [
            pw.Container(
              width: 100,
              decoration: const pw.BoxDecoration(
                border: pw.Border(bottom: pw.BorderSide(color: PdfColors.grey400, width: 1)),
              ),
            ),
            pw.SizedBox(height: 4),
            pw.Text('Authorized Signature', style: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold)),
          ],
        ),
      ],
    );
  }
}
