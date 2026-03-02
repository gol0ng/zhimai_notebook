import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';

enum LogLevel {
  debug,
  info,
  warning,
  error,
}

class LogService {
  static final LogService instance = LogService._internal();
  LogService._internal();

  final List<LogEntry> _logs = [];
  final int _maxLogs = 500;

  List<LogEntry> get logs => List.unmodifiable(_logs);

  void _addLog(LogLevel level, String message, [Object? error, StackTrace? stackTrace]) {
    final entry = LogEntry(
      level: level,
      message: message,
      error: error?.toString(),
      stackTrace: stackTrace?.toString(),
      timestamp: DateTime.now(),
    );
    _logs.add(entry);

    if (_logs.length > _maxLogs) {
      _logs.removeAt(0);
    }

    // Print to console in debug mode
    if (kDebugMode) {
      final color = _getLevelColor(level);
      debugPrint('[${level.name.toUpperCase()}] $message');
      if (error != null) {
        debugPrint('Error: $error');
      }
    }
  }

  Color _getLevelColor(LogLevel level) {
    switch (level) {
      case LogLevel.debug:
        return Colors.grey;
      case LogLevel.info:
        return Colors.blue;
      case LogLevel.warning:
        return Colors.orange;
      case LogLevel.error:
        return Colors.red;
    }
  }

  void debug(String message) => _addLog(LogLevel.debug, message);

  void info(String message) => _addLog(LogLevel.info, message);

  void warning(String message, [Object? error, StackTrace? stackTrace]) =>
      _addLog(LogLevel.warning, message, error, stackTrace);

  void error(String message, [Object? error, StackTrace? stackTrace]) =>
      _addLog(LogLevel.error, message, error, stackTrace);

  void clear() {
    _logs.clear();
  }

  String getLogsAsString() {
    final buffer = StringBuffer();
    for (final log in _logs) {
      buffer.writeln('[${log.timestamp.toIso8601String()}] [${log.level.name.toUpperCase()}] ${log.message}');
      if (log.error != null) {
        buffer.writeln('  Error: ${log.error}');
      }
    }
    return buffer.toString();
  }
}

class LogEntry {
  final LogLevel level;
  final String message;
  final String? error;
  final String? stackTrace;
  final DateTime timestamp;

  LogEntry({
    required this.level,
    required this.message,
    this.error,
    this.stackTrace,
    required this.timestamp,
  });
}
