import 'dart:typed_data';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:excel/excel.dart';
import 'package:path_provider/path_provider.dart';
import 'package:business_sahaj_erp/core/errors/exceptions.dart';
import 'package:business_sahaj_erp/core/services/logger_service.dart';
import 'dart:io' if (dart.library.html) 'dart:html';

class ExportService {
  /// Generates a professional multi-page PDF report and initiates the native share dialog.
  Future<String> exportToPDF({
    required String title,
    required List<String> headers,
    required List<List<String>> rows,
    List<String>? totals,
    String? subtitle,
  }) async {
    try {
      logger.info('Generating PDF export for report: $title');
      final pdf = pw.Document();

      // Executive Styling Palette
      final primaryIndigo = PdfColor.fromHex('#6366F1');
      final darkNavy = PdfColor.fromHex('#0F172A');
      final textMuted = PdfColor.fromHex('#64748B');
      final rowColorOdd = PdfColor.fromHex('#F8FAFC');
      final rowColorEven = PdfColor.fromHex('#FFFFFF');
      final borderColor = PdfColor.fromHex('#E2E8F0');

      pdf.addPage(
        pw.MultiPage(
          pageFormat: PdfPageFormat.a4,
          margin: const pw.EdgeInsets.all(28),
          header: (context) => pw.Container(
            padding: const pw.EdgeInsets.only(bottom: 8),
            decoration: pw.BoxDecoration(
              border: pw.Border(bottom: pw.BorderSide(color: primaryIndigo, width: 1.5)),
            ),
            child: pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Row(
                  children: [
                    pw.Container(
                      width: 22,
                      height: 22,
                      decoration: pw.BoxDecoration(
                        color: primaryIndigo,
                        borderRadius: const pw.BorderRadius.all(pw.Radius.circular(5)),
                      ),
                      child: pw.Center(
                        child: pw.Text('S', style: pw.TextStyle(color: PdfColors.white, fontWeight: pw.FontWeight.bold, fontSize: 13)),
                      ),
                    ),
                    pw.SizedBox(width: 8),
                    pw.Text(
                      'BUSINESS SAHAJ ERP',
                      style: pw.TextStyle(
                        fontSize: 14,
                        fontWeight: pw.FontWeight.bold,
                        color: darkNavy,
                      ),
                    ),
                  ],
                ),
                pw.Text(
                  title.toUpperCase(),
                  style: pw.TextStyle(
                    fontSize: 12,
                    fontWeight: pw.FontWeight.bold,
                    color: primaryIndigo,
                  ),
                ),
              ],
            ),
          ),
          footer: (context) => pw.Container(
            padding: const pw.EdgeInsets.only(top: 8),
            decoration: pw.BoxDecoration(
              border: pw.Border(top: pw.BorderSide(color: borderColor, width: 0.5)),
            ),
            child: pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Text('Generated on: ${DateTime.now().toIso8601String().substring(0, 10)}', style: pw.TextStyle(fontSize: 8, color: textMuted)),
                pw.Text('Page ${context.pageNumber} of ${context.pagesCount}', style: pw.TextStyle(fontSize: 8, color: textMuted, fontWeight: pw.FontWeight.bold)),
              ],
            ),
          ),
          build: (context) => [
            pw.SizedBox(height: 12),
            if (subtitle != null) ...[
              pw.Container(
                width: double.infinity,
                padding: const pw.EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: pw.BoxDecoration(
                  color: rowColorOdd,
                  borderRadius: const pw.BorderRadius.all(pw.Radius.circular(6)),
                  border: pw.Border.all(color: borderColor, width: 0.5),
                ),
                child: pw.Text(
                  subtitle,
                  style: pw.TextStyle(fontSize: 9, color: textMuted, fontWeight: pw.FontWeight.bold),
                ),
              ),
              pw.SizedBox(height: 14),
            ],

            // Tabular Grid
            pw.Table.fromTextArray(
              headers: headers,
              data: rows,
              border: pw.TableBorder.all(color: borderColor, width: 0.5),
              headerStyle: pw.TextStyle(
                color: PdfColors.white,
                fontWeight: pw.FontWeight.bold,
                fontSize: 8.5,
              ),
              headerDecoration: pw.BoxDecoration(
                color: darkNavy,
              ),
              rowDecoration: pw.BoxDecoration(color: rowColorEven),
              cellAlignment: pw.Alignment.centerLeft,
              cellStyle: pw.TextStyle(fontSize: 8, color: darkNavy),
              oddRowDecoration: pw.BoxDecoration(color: rowColorOdd),
              cellHeight: 22,
              cellPadding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            ),

            // Totals Bar if provided
            if (totals != null && totals.isNotEmpty) ...[
              pw.SizedBox(height: 12),
              pw.Container(
                alignment: pw.Alignment.centerRight,
                padding: const pw.EdgeInsets.all(10),
                decoration: pw.BoxDecoration(
                  color: primaryIndigo,
                  borderRadius: const pw.BorderRadius.all(pw.Radius.circular(6)),
                ),
                child: pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.end,
                  children: totals.map((totalText) {
                    return pw.Padding(
                      padding: const pw.EdgeInsets.only(left: 16),
                      child: pw.Text(
                        totalText,
                        style: pw.TextStyle(
                          fontWeight: pw.FontWeight.bold,
                          fontSize: 9.5,
                          color: PdfColors.white,
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),
            ],
          ],
        ),
      );

      final pdfBytes = await pdf.save();
      final filename = 'Report_${title.replaceAll(' ', '_')}.pdf';

      if (kIsWeb) {
        await Printing.sharePdf(
          bytes: pdfBytes,
          filename: filename,
        );
        logger.info('PDF generated and shared on Web successfully');
        return filename;
      }

      final tempDir = await getTemporaryDirectory();
      final pdfFile = File('${tempDir.path}/Report_${DateTime.now().millisecondsSinceEpoch}.pdf');
      await pdfFile.writeAsBytes(pdfBytes);

      // Open print/share dialog using printing package
      await Printing.sharePdf(
        bytes: pdfBytes,
        filename: filename,
      );

      logger.info('PDF generated and shared successfully at: ${pdfFile.path}');
      return pdfFile.path;
    } catch (e, stackTrace) {
      logger.error('Failed to export PDF report', e, stackTrace);
      throw ExportException('Failed to export PDF report: $e');
    }
  }

  /// Generates a formatted Excel XLSX document and returns the saved file path.
  Future<String> exportToExcel({
    required String title,
    required List<String> headers,
    required List<List<dynamic>> rows,
  }) async {
    try {
      logger.info('Generating Excel sheet for report: $title');
      var excel = Excel.createExcel();
      
      final sheetName = title.length > 30 ? title.substring(0, 30) : title;
      final sheet = excel[sheetName];
      excel.delete('Sheet1'); // Remove the default empty sheet

      // Add report header row
      sheet.appendRow([TextCellValue('BUSINESS SAHAJ ERP - ${title.toUpperCase()}')]);
      sheet.appendRow([TextCellValue('Export Date: ${DateTime.now().toIso8601String().substring(0, 10)}')]);
      sheet.appendRow([]); // empty spacing

      // Add columns header row
      final headerCells = headers.map((h) => TextCellValue(h)).toList();
      sheet.appendRow(headerCells);

      // Set header formatting
      final headerRowIndex = 3;
      for (var col = 0; col < headers.length; col++) {
        final cell = sheet.cell(CellIndex.indexByColumnRow(columnIndex: col, rowIndex: headerRowIndex));
        cell.cellStyle = CellStyle(
          bold: true,
          fontColorHex: ExcelColor.blue,
          backgroundColorHex: ExcelColor.lightBlue,
        );
      }

      // Add data rows
      for (var rowData in rows) {
        final cellsList = rowData.map((val) {
          if (val is double) {
            return DoubleCellValue(val);
          } else if (val is int) {
            return IntCellValue(val);
          } else if (val is bool) {
            return BoolCellValue(val);
          } else {
            return TextCellValue(val?.toString() ?? '');
          }
        }).toList();
        sheet.appendRow(cellsList);
      }

      // Save XLSX document
      final fileBytes = excel.encode();
      if (fileBytes == null) {
        throw const ExportException('Failed to encode Excel file.');
      }

      final fileName = 'Report_${title.replaceAll(' ', '_')}_${DateTime.now().millisecondsSinceEpoch}.xlsx';

      if (kIsWeb) {
        await Printing.sharePdf(
          bytes: Uint8List.fromList(fileBytes),
          filename: fileName,
        );
        logger.info('Excel sheet exported on Web successfully');
        return fileName;
      }

      final directory = await getApplicationDocumentsDirectory();
      final reportsDir = Directory('${directory.path}/exports');
      if (!await reportsDir.exists()) {
        await reportsDir.create(recursive: true);
      }

      final file = File('${reportsDir.path}/$fileName');
      await file.writeAsBytes(fileBytes, flush: true);

      logger.info('Excel sheet exported successfully at: ${file.path}');
      return file.path;
    } catch (e, stackTrace) {
      logger.error('Failed to export Excel report', e, stackTrace);
      throw ExportException('Failed to export Excel report: $e');
    }
  }
}
