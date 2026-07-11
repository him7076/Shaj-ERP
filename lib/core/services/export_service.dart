import 'dart:io';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:excel/excel.dart';
import 'package:path_provider/path_provider.dart';
import 'package:business_sahaj_erp/core/errors/exceptions.dart';
import 'package:business_sahaj_erp/core/services/logger_service.dart';

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

      // Define Material styling
      final primaryColor = PdfColor.fromHex('#1E3A8A'); // Blue
      final secondaryColor = PdfColor.fromHex('#4B5563'); // Grey
      final rowColorOdd = PdfColor.fromHex('#F9FAFB');
      final rowColorEven = PdfColor.fromHex('#FFFFFF');

      pdf.addPage(
        pw.MultiPage(
          pageFormat: PdfPageFormat.a4,
          margin: const pw.EdgeInsets.all(32),
          build: (context) => [
            // Company Header
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text(
                      'BUSINESS SAHAJ ERP',
                      style: pw.TextStyle(
                        fontSize: 20,
                        fontWeight: pw.FontWeight.bold,
                        color: primaryColor,
                      ),
                    ),
                    if (subtitle != null) ...[
                      pw.SizedBox(height: 4),
                      pw.Text(
                        subtitle,
                        style: pw.TextStyle(
                          fontSize: 10,
                          color: secondaryColor,
                        ),
                      ),
                    ],
                  ],
                ),
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.end,
                  children: [
                    pw.Text(
                      title.toUpperCase(),
                      style: pw.TextStyle(
                        fontSize: 14,
                        fontWeight: pw.FontWeight.bold,
                      ),
                    ),
                    pw.Text(
                      'Generated: ${DateTime.now().toIso8601String().substring(0, 10)}',
                      style: const pw.TextStyle(fontSize: 8),
                    ),
                  ],
                ),
              ],
            ),
            pw.Divider(thickness: 1.5, color: primaryColor),
            pw.SizedBox(height: 16),

            // Tabular Grid
            pw.Table.fromTextArray(
              headers: headers,
              data: rows,
              border: null,
              headerStyle: pw.TextStyle(
                color: PdfColors.white,
                fontWeight: pw.FontWeight.bold,
                fontSize: 9,
              ),
              headerDecoration: pw.BoxDecoration(
                color: primaryColor,
              ),
              rowDecoration: pw.BoxDecoration(color: rowColorEven),
              cellAlignment: pw.Alignment.centerLeft,
              cellStyle: const pw.TextStyle(fontSize: 8),
              oddRowDecoration: pw.BoxDecoration(color: rowColorOdd),
              cellHeight: 20,
              cellPadding: const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 4),
            ),

            // Totals Bar if provided
            if (totals != null && totals.isNotEmpty) ...[
              pw.SizedBox(height: 12),
              pw.Container(
                alignment: pw.Alignment.centerRight,
                padding: const pw.EdgeInsets.all(8),
                decoration: pw.BoxDecoration(
                  color: PdfColor.fromHex('#E5E7EB'),
                  borderRadius: const pw.BorderRadius.all(pw.Radius.circular(4)),
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
                          fontSize: 10,
                          color: primaryColor,
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

      final tempDir = await getTemporaryDirectory();
      final pdfFile = File('${tempDir.path}/Report_${DateTime.now().millisecondsSinceEpoch}.pdf');
      await pdfFile.writeAsBytes(await pdf.save());

      // Open print/share dialog using printing package
      await Printing.sharePdf(
        bytes: await pdfFile.readAsBytes(),
        filename: 'Report_${title.replaceAll(' ', '_')}.pdf',
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
      
      // Get the default sheet and rename it or add a custom sheet
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

      // Save XLSX document in documents directory
      final fileBytes = excel.encode();
      if (fileBytes == null) {
        throw const ExportException('Failed to encode Excel file.');
      }

      final directory = await getApplicationDocumentsDirectory();
      final reportsDir = Directory('${directory.path}/exports');
      if (!await reportsDir.exists()) {
        await reportsDir.create(recursive: true);
      }

      final fileName = 'Report_${title.replaceAll(' ', '_')}_${DateTime.now().millisecondsSinceEpoch}.xlsx';
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
