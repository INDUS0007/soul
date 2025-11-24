import 'package:flutter/material.dart';
import 'package:common/utils/app_logger.dart';

import 'screens/splash_screen.dart';

// Global logger instance for app_user
final appLogger = AppLogger('USER_APP');

void main() {
  appLogger.info('=== USER APP STARTING ===');
  appLogger.debug('Initializing User App...');
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Auth Demo',
      theme: ThemeData(
        useMaterial3: true,
        colorSchemeSeed: Colors.blue,
      ),
      home: const SplashScreen(),
    );
  }
}

