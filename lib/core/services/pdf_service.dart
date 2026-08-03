import 'dart:typed_data';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:business_sahaj_erp/data/local/collections/order_collection.dart';
import 'package:business_sahaj_erp/data/local/collections/invoice_collection.dart';
import 'package:business_sahaj_erp/data/local/collections/invoice_item_collection.dart';
import 'package:business_sahaj_erp/core/models/firm_info.dart';
import 'package:business_sahaj_erp/core/services/amount_to_words_service.dart';
import 'package:business_sahaj_erp/core/errors/exceptions.dart';

class PdfService {
  final AmountToWordsService _amountToWordsService = AmountToWordsService();

  // Executive SaaS Color Palette for PDF Documents
  static final PdfColor primaryIndigo = PdfColor.fromHex('#6366F1');
  static final PdfColor obsidianDark = PdfColor.fromHex('#0F172A');
  static final PdfColor oceanCyan = PdfColor.fromHex('#0EA5E9');
  static final PdfColor emeraldGreen = PdfColor.fromHex('#10B981');
  static final PdfColor cardBgLight = PdfColor.fromHex('#F8FAFC');
  static final PdfColor tableHeaderBg = PdfColor.fromHex('#0F172A');
  static final PdfColor borderColor = PdfColor.fromHex('#E2E8F0');
  static final PdfColor textMuted = PdfColor.fromHex('#64748B');

  /// Generates an executive GST Tax Invoice PDF using active FirmInfo
  Future<Uint8List> generateInvoicePdf(
    Invoice invoice, {
    List<InvoiceItem>? items,
    required FirmInfo firmInfo,
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
                firmInfo: firmInfo,
              ),
              pw.SizedBox(height: 14),

              _buildBillToSection(
                name: invoice.partyName ?? 'N/A',
                gst: invoice.gstNumber ?? '',
                phone: 'N/A',
                address: invoice.address ?? '',
              ),
              pw.SizedBox(height: 14),

              _buildInvoiceItemsTable(actualItems),
              pw.SizedBox(height: 14),

              _buildExecutiveSummary(
                subtotal: invoice.subtotal ?? 0.0,
                discount: invoice.discountAmount ?? 0.0,
                gst: invoice.totalGST ?? 0.0,
                roundOff: invoice.roundOff ?? 0.0,
                grandTotal: invoice.grandTotal ?? 0.0,
                cgst: invoice.cgstAmount ?? 0.0,
                sgst: invoice.sgstAmount ?? 0.0,
                igst: invoice.igstAmount ?? 0.0,
                firmInfo: firmInfo,
              ),
              pw.SizedBox(height: 20),

              _buildExecutiveFooter(
                remarks: invoice.remarks ?? 'Thank you for your business. Goods once sold will not be taken back.',
                firmName: firmInfo.name,
              ),
            ];
          },
        ),
      );

      return pdf.save();
    } catch (e) {
      throw PDFException('Failed to generate Invoice PDF: $e');
    }
  }

  /// Generates an executive PDF document for a Sales Order using active FirmInfo
  Future<Uint8List> generateOrderPdf(
    Order order, {
    required FirmInfo firmInfo,
  }) async {
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
                firmInfo: firmInfo,
              ),
              pw.SizedBox(height: 14),
              _buildBillToSection(
                name: order.partyName ?? 'N/A',
                gst: order.gstNumber ?? '',
                phone: order.mobileNumber ?? '',
                address: order.locationAddress ?? '',
              ),
              pw.SizedBox(height: 14),
              _buildOrderItemsTable(order),
              pw.SizedBox(height: 14),
              _buildExecutiveSummary(
                subtotal: order.subtotal ?? 0.0,
                discount: order.discountAmount ?? 0.0,
                gst: order.totalGST ?? 0.0,
                roundOff: order.roundOff ?? 0.0,
                grandTotal: order.grandTotal ?? 0.0,
                cgst: (order.totalGST ?? 0.0) / 2.0,
                sgst: (order.totalGST ?? 0.0) / 2.0,
                igst: 0.0,
                firmInfo: firmInfo,
              ),
              pw.SizedBox(height: 20),
              _buildExecutiveFooter(
                remarks: order.remarks ?? 'Thank you for your business order.',
                firmName: firmInfo.name,
              ),
            ];
          },
        ),
      );

      return pdf.save();
    } catch (e) {
      throw PDFException('Failed to generate Order PDF: $e');
    }
  }

  /// Helper to print PDF directly using printing package
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

  /// Shares PDF directly via native system share sheet
  Future<void> sharePdf(Uint8List pdfData, String filename) async {
    try {
      await Printing.sharePdf(
        bytes: pdfData,
        filename: filename,
      );
    } catch (e) {
      throw PDFException('Failed to share PDF: $e');
    }
  }

  // --- Executive Header Builder ---
  pw.Widget _buildExecutiveHeader({
    required String title,
    required String docNumber,
    required String dateStr,
    required FirmInfo firmInfo,
  }) {
    return pw.Container(
      decoration: pw.BoxDecoration(
        color: obsidianDark,
        borderRadius: const pw.BorderRadius.all(pw.Radius.circular(10)),
      ),
      padding: const pw.EdgeInsets.all(16),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        crossAxisAlignment: pw.CrossAxisAlignment.center,
        children: [
          pw.Expanded(
            child: pw.Row(
              children: [
                pw.Container(
                  width: 36,
                  height: 36,
                  decoration: pw.BoxDecoration(
                    color: primaryIndigo,
                    borderRadius: const pw.BorderRadius.all(pw.Radius.circular(8)),
                  ),
                  child: pw.Center(
                    child: pw.Text(
                      firmInfo.name.isNotEmpty ? firmInfo.name[0].toUpperCase() : 'S',
                      style: pw.TextStyle(color: PdfColors.white, fontWeight: pw.FontWeight.bold, fontSize: 20),
                    ),
                  ),
                ),
                pw.SizedBox(width: 12),
                pw.Expanded(
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text(
                        firmInfo.name.toUpperCase(),
                        style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold, color: PdfColors.white),
                        maxLines: 1,
                      ),
                      pw.SizedBox(height: 2),
                      pw.Text(
                        firmInfo.fullAddress,
                        style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey400),
                        maxLines: 2,
                      ),
                      pw.SizedBox(height: 2),
                      pw.Row(
                        children: [
                          if (firmInfo.gst.isNotEmpty)
                            pw.Text('GSTIN: ${firmInfo.gst}  ', style: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold, color: oceanCyan)),
                          if (firmInfo.phone.isNotEmpty)
                            pw.Text('| Phone: ${firmInfo.phone}', style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey300)),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          pw.SizedBox(width: 16),
          pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.end,
            children: [
              pw.Container(
                padding: const pw.EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                decoration: pw.BoxDecoration(
                  color: primaryIndigo,
                  borderRadius: const pw.BorderRadius.all(pw.Radius.circular(6)),
                ),
                child: pw.Text(title, style: pw.TextStyle(fontSize: 11, fontWeight: pw.FontWeight.bold, color: PdfColors.white)),
              ),
              pw.SizedBox(height: 6),
              pw.Text('Invoice No: #$docNumber', style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold, color: PdfColors.white)),
              pw.Text('Date: $dateStr', style: const pw.TextStyle(fontSize: 8.5, color: PdfColors.grey300)),
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
        color: cardBgLight,
        borderRadius: const pw.BorderRadius.all(pw.Radius.circular(8)),
        border: pw.Border.all(color: borderColor, width: 1),
      ),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text('BILLED TO CUSTOMER:', style: pw.TextStyle(fontSize: 7.5, color: primaryIndigo, fontWeight: pw.FontWeight.bold)),
              pw.SizedBox(height: 3),
              pw.Text(name, style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold, color: obsidianDark)),
              if (gst.isNotEmpty && gst != 'N/A') ...[
                pw.SizedBox(height: 2),
                pw.Text('GSTIN: $gst', style: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold, color: oceanCyan)),
              ],
            ],
          ),
          pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.end,
            children: [
              pw.Text('BILLING & SHIPPING ADDRESS:', style: pw.TextStyle(fontSize: 7.5, color: textMuted, fontWeight: pw.FontWeight.bold)),
              pw.SizedBox(height: 3),
              pw.Text(address.isNotEmpty ? address : 'Main Market Area', style: pw.TextStyle(fontSize: 8.5, color: obsidianDark, fontWeight: pw.FontWeight.bold)),
            ],
          ),
        ],
      ),
    );
  }

  // --- Invoice Items Table ---
  pw.Widget _buildInvoiceItemsTable(List<InvoiceItem> items) {
    final headers = ['S.NO', 'PRODUCT DESCRIPTION', 'HSN', 'QTY', 'RATE (Rs.)', 'DISC (Rs.)', 'TOTAL (Rs.)'];

    int index = 1;
    final data = items.map<List<dynamic>>((item) {
      final double qty = item.quantity ?? 0.0;
      return [
        '${index++}',
        item.itemName ?? 'Item',
        item.hsnCode ?? '-',
        '${qty % 1 == 0 ? qty.toInt() : qty} ${item.unit ?? "PCS"}',
        '${item.rate?.toStringAsFixed(2) ?? "0.00"}',
        '${item.discount?.toStringAsFixed(2) ?? "0.00"}',
        '${item.totalAmount?.toStringAsFixed(2) ?? "0.00"}',
      ];
    }).toList();

    return pw.Table.fromTextArray(
      headers: headers,
      data: data,
      border: pw.TableBorder.all(color: borderColor, width: 0.5),
      headerStyle: pw.TextStyle(fontSize: 8.5, fontWeight: pw.FontWeight.bold, color: PdfColors.white),
      headerDecoration: pw.BoxDecoration(color: tableHeaderBg),
      cellStyle: pw.TextStyle(fontSize: 8, color: obsidianDark),
      cellAlignment: pw.Alignment.centerLeft,
      rowDecoration: const pw.BoxDecoration(color: PdfColors.white),
      oddRowDecoration: pw.BoxDecoration(color: cardBgLight),
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
        '${item.rate?.toStringAsFixed(2) ?? "0.00"}',
        '${item.discountAmount?.toStringAsFixed(2) ?? "0.00"}',
        '${item.totalAmount?.toStringAsFixed(2) ?? "0.00"}',
      ];
    }).toList();

    return pw.Table.fromTextArray(
      headers: headers,
      data: data,
      border: pw.TableBorder.all(color: borderColor, width: 0.5),
      headerStyle: pw.TextStyle(fontSize: 8.5, fontWeight: pw.FontWeight.bold, color: PdfColors.white),
      headerDecoration: pw.BoxDecoration(color: tableHeaderBg),
      cellStyle: pw.TextStyle(fontSize: 8, color: obsidianDark),
      cellAlignment: pw.Alignment.centerLeft,
      rowDecoration: const pw.BoxDecoration(color: PdfColors.white),
      oddRowDecoration: pw.BoxDecoration(color: cardBgLight),
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
    required FirmInfo firmInfo,
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
              pw.Container(
                padding: const pw.EdgeInsets.all(8),
                decoration: pw.BoxDecoration(
                  color: cardBgLight,
                  borderRadius: const pw.BorderRadius.all(pw.Radius.circular(6)),
                  border: pw.Border.all(color: borderColor, width: 0.5),
                ),
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text('AMOUNT IN WORDS:', style: pw.TextStyle(fontSize: 7.5, fontWeight: pw.FontWeight.bold, color: primaryIndigo)),
                    pw.SizedBox(height: 2),
                    pw.Text(words, style: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold, color: obsidianDark)),
                  ],
                ),
              ),
              pw.SizedBox(height: 8),
              if (firmInfo.bankName.isNotEmpty || firmInfo.bankAcc.isNotEmpty || firmInfo.upi.isNotEmpty) ...[
                pw.Text('Payment & Banking Credentials:', style: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold, color: obsidianDark)),
                if (firmInfo.bankName.isNotEmpty)
                  pw.Text('Bank Name: ${firmInfo.bankName}', style: pw.TextStyle(fontSize: 7.5, color: textMuted)),
                if (firmInfo.bankAcc.isNotEmpty)
                  pw.Text('A/C No: ${firmInfo.bankAcc}', style: pw.TextStyle(fontSize: 7.5, color: textMuted)),
                if (firmInfo.ifsc.isNotEmpty)
                  pw.Text('IFSC Code: ${firmInfo.ifsc}', style: pw.TextStyle(fontSize: 7.5, color: textMuted)),
                if (firmInfo.upi.isNotEmpty)
                  pw.Text('UPI ID: ${firmInfo.upi}', style: pw.TextStyle(fontSize: 7.5, fontWeight: pw.FontWeight.bold, color: primaryIndigo)),
              ],
              if (cgst > 0 || sgst > 0 || igst > 0) ...[
                pw.SizedBox(height: 6),
                pw.Container(
                  padding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: pw.BoxDecoration(
                    color: cardBgLight,
                    borderRadius: const pw.BorderRadius.all(pw.Radius.circular(4)),
                    border: pw.Border.all(color: borderColor, width: 0.5),
                  ),
                  child: pw.Text('GST Tax Division: CGST: Rs. ${cgst.toStringAsFixed(2)} | SGST: Rs. ${sgst.toStringAsFixed(2)} | IGST: Rs. ${igst.toStringAsFixed(2)}', style: pw.TextStyle(fontSize: 7.5, fontWeight: pw.FontWeight.bold, color: primaryIndigo)),
                ),
              ],
            ],
          ),
        ),
        pw.SizedBox(width: 16),
        // Right Column: Summary Table + Solid Indigo Total Box
        pw.Expanded(
          flex: 2,
          child: pw.Column(
            children: [
              _buildSummaryRow('Subtotal (Taxable):', 'Rs. ${subtotal.toStringAsFixed(2)}'),
              _buildSummaryRow('Discount Total:', '-Rs. ${discount.toStringAsFixed(2)}'),
              _buildSummaryRow('Tax Amount (GST):', 'Rs. ${gst.toStringAsFixed(2)}'),
              _buildSummaryRow('Round Off:', 'Rs. ${roundOff.toStringAsFixed(2)}'),
              pw.SizedBox(height: 6),
              pw.Container(
                padding: const pw.EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: pw.BoxDecoration(
                  color: primaryIndigo,
                  borderRadius: const pw.BorderRadius.all(pw.Radius.circular(6)),
                ),
                child: pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Text('GRAND TOTAL:', style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold, color: PdfColors.white)),
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
          pw.Text(label, style: pw.TextStyle(fontSize: 8, color: textMuted)),
          pw.Text(value, style: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold, color: obsidianDark)),
        ],
      ),
    );
  }

  // --- Executive Footer Section ---
  pw.Widget _buildExecutiveFooter({required String remarks, required String firmName}) {
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
                  pw.Text('Terms & Conditions:', style: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold, color: obsidianDark)),
                  pw.SizedBox(height: 2),
                  pw.Text(remarks, style: pw.TextStyle(fontSize: 7.5, color: textMuted)),
                ],
              ),
            ),
            pw.SizedBox(width: 24),
            pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.center,
              children: [
                pw.Text('For $firmName', style: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold, color: obsidianDark)),
                pw.SizedBox(height: 24),
                pw.Container(
                  width: 130,
                  decoration: pw.BoxDecoration(
                    border: pw.Border(bottom: pw.BorderSide(color: borderColor, width: 1)),
                  ),
                ),
                pw.SizedBox(height: 4),
                pw.Text('Authorised Signatory', style: pw.TextStyle(fontSize: 7.5, fontWeight: pw.FontWeight.bold, color: textMuted)),
              ],
            ),
          ],
        ),
      ],
    );
  }
}
