// ignore: avoid_web_libraries_in_flutter
import 'dart:html' as html;
import 'dart:convert';
import 'package:flutter/foundation.dart';

/// Web implementation using browser download
Future<bool> saveCsvAndOpen(String filename, String csvContent) async {
  try {
    // Create a blob with the CSV content
    final bytes = utf8.encode(csvContent);
    final blob = html.Blob([bytes], 'text/csv');

    // Create download link
    final url = html.Url.createObjectUrlFromBlob(blob);
    final anchor = html.AnchorElement(href: url)
      ..setAttribute('download', filename)
      ..style.display = 'none';

    // Add to document, click, and remove
    html.document.body?.append(anchor);
    anchor.click();
    anchor.remove();

    // Cleanup
    html.Url.revokeObjectUrl(url);

    debugPrint('📄 CSV downloaded: $filename');
    return true;
  } catch (e) {
    debugPrint('❌ Error downloading CSV: $e');
    return false;
  }
}
