import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:open_file/open_file.dart';

/// Desktop implementation using dart:io
Future<bool> saveCsvAndOpen(String filename, String csvContent) async {
  try {
    final dir = await getApplicationDocumentsDirectory();
    final filePath = '${dir.path}/$filename';
    final file = File(filePath);
    await file.writeAsString(csvContent);

    debugPrint('📄 CSV saved to: $filePath');

    // Open the file
    final result = await OpenFile.open(filePath);
    return result.type == ResultType.done;
  } catch (e) {
    debugPrint('❌ Error saving CSV: $e');
    return false;
  }
}
