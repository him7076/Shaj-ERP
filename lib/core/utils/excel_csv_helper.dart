import 'dart:io';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:business_sahaj_erp/data/local/collections/party_collection.dart';

class ExcelCsvHelper {
  /// Parses a CSV string and returns a mapped list of fields: Name, GST, Mobile, Address.
  static List<Map<String, String>> parseCsv(String csvContent) {
    final List<Map<String, String>> results = [];
    final lines = csvContent.split('\n');
    if (lines.isEmpty) return results;

    // Header extraction
    final headerLine = lines.first.trim();
    final headers = headerLine.split(',').map((h) => h.trim().toLowerCase()).toList();

    for (int i = 1; i < lines.length; i++) {
      final line = lines[i].trim();
      if (line.isEmpty) continue;

      final values = line.split(',').map((v) => v.trim()).toList();
      final Map<String, String> row = {};

      for (int j = 0; j < headers.length; j++) {
        if (j < values.length) {
          row[headers[j]] = values[j];
        }
      }

      // Check minimum fields required
      if (row.containsKey('name') && row['name']!.isNotEmpty) {
        results.add({
          'name': row['name'] ?? '',
          'gst': row['gst'] ?? row['gstnumber'] ?? '',
          'mobile': row['mobile'] ?? row['mobilenumber'] ?? '',
          'address': row['address'] ?? row['addressline1'] ?? '',
          'city': row['city'] ?? '',
          'state': row['state'] ?? '',
          'type': row['type'] ?? row['partytype'] ?? 'Customer',
        });
      }
    }
    return results;
  }

  /// Converts tabular list rows into a CSV string
  static String generateCsv(List<String> headers, List<List<dynamic>> rows) {
    final StringBuffer buffer = StringBuffer();
    
    // Write headers
    buffer.writeln(headers.join(','));
    
    // Write rows
    for (var row in rows) {
      final formattedRow = row.map((val) {
        if (val == null) return '';
        final strVal = val.toString();
        // Escape commas and double quotes
        if (strVal.contains(',') || strVal.contains('"') || strVal.contains('\n')) {
          return '"${strVal.replaceAll('"', '""')}"';
        }
        return strVal;
      }).join(',');
      buffer.writeln(formattedRow);
    }
    
    return buffer.toString();
  }

  /// Exports the Party list to a PDF document and opens the OS print review panel
  static Future<void> exportPartiesToPdf(List<Party> parties) async {
    final pdf = pw.Document();

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        build: (pw.Context context) {
          return [
            pw.Header(
              level: 0,
              child: pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text('Business Sahaj ERP - Parties Directory', style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold)),
                  pw.Text('Date: ${DateTime.now().toString().split(' ')[0]}', style: const pw.TextStyle(fontSize: 10)),
                ],
              ),
            ),
            pw.SizedBox(height: 16),
            
            // Styled PDF table
            pw.TableHelper.fromTextArray(
              headers: ['Code', 'Party Name', 'Type', 'Mobile', 'City', 'GST Number', 'Outstanding'],
              data: List<List<dynamic>>.generate(
                parties.length,
                (index) {
                  final party = parties[index];
                  return [
                    party.partyCode ?? '',
                    party.partyName ?? '',
                    party.partyType ?? '',
                    party.mobileNumber ?? '',
                    party.city ?? '',
                    party.gstNumber ?? 'N/A',
                    'Dr ₹${(party.openingBalance ?? 0.0).toStringAsFixed(2)}', // Placeholder balance
                  ];
                },
              ),
              headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold, color: PdfColors.white),
              headerDecoration: const pw.BoxDecoration(color: PdfColors.blue800),
              rowDecoration: const pw.BoxDecoration(border: pw.Border(bottom: pw.BorderSide(color: PdfColors.grey300, width: 0.5))),
              cellAlignment: pw.Alignment.centerLeft,
              cellPadding: const pw.EdgeInsets.all(6),
            ),
          ];
        },
      ),
    );

    // Displays the print preview UI dialog natively in Flutter
    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => pdf.save(),
      name: 'Sahaj_ERP_Parties_List',
    );
  }
}
