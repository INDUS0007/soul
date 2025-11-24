import 'dart:developer' as developer;
import 'package:flutter/foundation.dart';

/// A logger utility that prefixes logs with the app name to distinguish
/// logs from different apps when running multiple Flutter apps.
/// Uses print() for terminal output and log() for DevTools.
class AppLogger {
  final String appName;
  
  const AppLogger(this.appName);
  
  /// Logs a debug message with app prefix
  void debug(String message, [Object? error, StackTrace? stackTrace]) {
    if (kDebugMode) {
      final prefix = '[$appName]';
      // Use print() for terminal output (always visible, auto-flushes)
      print('$prefix $message');
      // Also use log() for Flutter DevTools
      developer.log(message, name: appName, level: 800);
      
      if (error != null) {
        print('$prefix Error: $error');
        developer.log('Error: $error', name: appName, level: 900, error: error);
      }
      if (stackTrace != null) {
        print('$prefix StackTrace:');
        print(stackTrace);
        developer.log('StackTrace', name: appName, level: 1000, stackTrace: stackTrace);
      }
    }
  }
  
  /// Logs an info message with app prefix
  void info(String message) {
    if (kDebugMode) {
      print('[$appName] INFO: $message');
      developer.log(message, name: appName, level: 700);
    }
  }
  
  /// Logs a warning message with app prefix
  void warning(String message) {
    if (kDebugMode) {
      print('[$appName] WARNING: $message');
      developer.log(message, name: appName, level: 1000);
    }
  }
  
  /// Logs an error message with app prefix
  void error(String message, [Object? error, StackTrace? stackTrace]) {
    if (kDebugMode) {
      final prefix = '[$appName]';
      print('$prefix ERROR: $message');
      developer.log(message, name: appName, level: 1200, error: error, stackTrace: stackTrace);
      
      if (error != null) {
        print('$prefix Error details: $error');
      }
      if (stackTrace != null) {
        print('$prefix StackTrace:');
        print(stackTrace);
      }
    }
  }
}

