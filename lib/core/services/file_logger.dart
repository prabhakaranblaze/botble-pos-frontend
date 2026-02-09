import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:intl/intl.dart';

/// File-based logger for production debugging.
/// Writes logs to Documents/SeychellesPostPOS/logs/app_YYYY-MM-DD.log
/// Automatically rotates daily and cleans up logs older than 7 days.
class FileLogger {
  static FileLogger? _instance;
  static FileLogger get instance => _instance ??= FileLogger._();
  FileLogger._();

  File? _logFile;
  bool _initialized = false;
  final _dateFormat = DateFormat('yyyy-MM-dd HH:mm:ss.SSS');
  final _fileDateFormat = DateFormat('yyyy-MM-dd');

  /// Initialize the logger. Safe to call multiple times.
  Future<void> init() async {
    if (_initialized) return;
    if (kIsWeb) return; // No file logging on web

    try {
      final docsDir = await getApplicationDocumentsDirectory();
      final logDir = Directory('${docsDir.path}/SeychellesPostPOS/logs');
      if (!await logDir.exists()) {
        await logDir.create(recursive: true);
      }

      final today = _fileDateFormat.format(DateTime.now());
      _logFile = File('${logDir.path}/app_$today.log');
      _initialized = true;

      // Clean up old logs (fire and forget)
      _cleanOldLogs(logDir);

      await _write('INFO', 'Logger initialized. Log file: ${_logFile!.path}');
    } catch (e) {
      debugPrint('FileLogger init failed: $e');
    }
  }

  /// Log path for user to find the file
  Future<String?> get logFilePath async {
    if (_logFile != null) return _logFile!.path;
    try {
      final docsDir = await getApplicationDocumentsDirectory();
      final today = _fileDateFormat.format(DateTime.now());
      return '${docsDir.path}/SeychellesPostPOS/logs/app_$today.log';
    } catch (_) {
      return null;
    }
  }

  Future<void> info(String message) => _write('INFO', message);
  Future<void> warn(String message) => _write('WARN', message);
  Future<void> error(String message, [Object? err, StackTrace? stack]) async {
    await _write('ERROR', message);
    if (err != null) await _write('ERROR', '  Exception: $err');
    if (stack != null) await _write('ERROR', '  Stack: $stack');
  }

  Future<void> _write(String level, String message) async {
    if (!_initialized || _logFile == null) return;
    try {
      // Check if we need to rotate (new day)
      final today = _fileDateFormat.format(DateTime.now());
      if (!_logFile!.path.contains(today)) {
        final parent = _logFile!.parent;
        _logFile = File('${parent.path}/app_$today.log');
      }

      final timestamp = _dateFormat.format(DateTime.now());
      final line = '[$timestamp] [$level] $message\n';
      await _logFile!.writeAsString(line, mode: FileMode.append);
    } catch (_) {
      // Silently fail - don't let logging break the app
    }
  }

  /// Delete log files older than 7 days
  Future<void> _cleanOldLogs(Directory logDir) async {
    try {
      final cutoff = DateTime.now().subtract(const Duration(days: 7));
      await for (final entity in logDir.list()) {
        if (entity is File && entity.path.endsWith('.log')) {
          final stat = await entity.stat();
          if (stat.modified.isBefore(cutoff)) {
            await entity.delete();
          }
        }
      }
    } catch (_) {}
  }
}
