import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:business_sahaj_erp/core/utils/web_download_stub.dart'
    if (dart.library.html) 'package:business_sahaj_erp/core/utils/web_download_html.dart';

class ExcelDownloadHelper {
  static Future<String?> downloadExcel(List<int> bytes, String filename) async {
    if (kIsWeb) {
      triggerWebDownload(Uint8List.fromList(bytes), filename);
      return filename;
    } else {
      try {
        Directory? dir;
        if (Platform.isAndroid) {
          dir = Directory('/storage/emulated/0/Download');
          if (!await dir.exists()) {
            dir = await getExternalStorageDirectory();
          }
        } else {
          dir = await getDownloadsDirectory() ?? await getApplicationDocumentsDirectory();
        }
        dir ??= await getApplicationDocumentsDirectory();

        final file = File('${dir.path}/$filename');
        await file.writeAsBytes(bytes, flush: true);
        return file.path;
      } catch (e) {
        try {
          final fallbackDir = await getApplicationDocumentsDirectory();
          final file = File('${fallbackDir.path}/$filename');
          await file.writeAsBytes(bytes, flush: true);
          return file.path;
        } catch (_) {}
      }
    }
    return null;
  }
}
