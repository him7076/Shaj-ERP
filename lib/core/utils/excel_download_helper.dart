import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:printing/printing.dart';
import 'package:business_sahaj_erp/core/utils/web_download_stub.dart'
    if (dart.library.html) 'package:business_sahaj_erp/core/utils/web_download_html.dart';

class ExcelDownloadHelper {
  static Future<void> downloadExcel(List<int> bytes, String filename) async {
    if (kIsWeb) {
      downloadWebFile(bytes, filename);
    } else {
      try {
        final dir = await getApplicationDocumentsDirectory();
        final file = File('${dir.path}/$filename');
        await file.writeAsBytes(bytes, flush: true);

        await Printing.sharePdf(
          bytes: Uint8List.fromList(bytes),
          filename: filename,
        );
      } catch (_) {}
    }
  }
}
