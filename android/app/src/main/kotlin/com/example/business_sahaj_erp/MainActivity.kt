package com.example.business_sahaj_erp

import android.net.Uri
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.io.ByteArrayOutputStream

class MainActivity : FlutterActivity() {
    private val CHANNEL = "com.example.business_sahaj_erp/content_reader"

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler { call, result ->
            if (call.method == "readContentUriBytes") {
                val uriString = call.argument<String>("uri")
                if (uriString != null) {
                    try {
                        val uri = Uri.parse(uriString)
                        val inputStream = contentResolver.openInputStream(uri)
                        if (inputStream != null) {
                            val buffer = ByteArrayOutputStream()
                            val data = ByteArray(16384)
                            var nRead: Int
                            while (inputStream.read(data, 0, data.size).also { nRead = it } != -1) {
                                buffer.write(data, 0, nRead)
                            }
                            buffer.flush()
                            inputStream.close()
                            result.success(buffer.toByteArray())
                        } else {
                            result.error("NULL_STREAM", "Could not open input stream for URI", null)
                        }
                    } catch (e: Exception) {
                        result.error("READ_ERROR", e.localizedMessage, null)
                    }
                } else {
                    result.error("INVALID_ARGUMENT", "URI parameter is null", null)
                }
            } else {
                result.notImplemented()
            }
        }
    }
}
