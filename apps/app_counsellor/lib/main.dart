import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:common/api/api_client.dart';
import 'package:common/utils/app_logger.dart';
import 'screens/counselor_dashboard.dart';
import 'screens/login_screen.dart';

// Global logger instance for app_counsellor
final appLogger = AppLogger('COUNSELLOR_APP');

void main() {
  appLogger.info('=== COUNSELLOR APP STARTING ===');
  appLogger.debug('Initializing Counsellor App...');
  WidgetsFlutterBinding.ensureInitialized();

  // Force portrait orientation for mobile
  SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  runApp(const CounselorApp());
}

class CounselorApp extends StatelessWidget {
  const CounselorApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Counselor Portal',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF6C63FF),
          brightness: Brightness.light,
        ),
        useMaterial3: true,
        cardTheme: CardThemeData(elevation: 2),
        // Mobile-optimized theme
        appBarTheme: const AppBarTheme(centerTitle: false, elevation: 0),
        // Optimize touch targets for mobile
        materialTapTargetSize: MaterialTapTargetSize.padded,
      ),
      home: const AuthWrapper(),
    );
  }
}

class AuthWrapper extends StatefulWidget {
  const AuthWrapper({super.key});

  @override
  State<AuthWrapper> createState() => _AuthWrapperState();
}

class _AuthWrapperState extends State<AuthWrapper> {
  final ApiClient _api = ApiClient();
  bool _checking = true;
  bool _isAuthenticated = false;

  @override
  void initState() {
    super.initState();
    _checkAuth();
  }

  Future<void> _checkAuth() async {
    try {
      // Check if user is logged in and is a counselor
      final profile = await _api.getCounsellorProfile();
      if (mounted) {
        setState(() {
          // Profile is a Map, so check if it's not empty
          _isAuthenticated = profile.isNotEmpty;
          _checking = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _isAuthenticated = false;
          _checking = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_checking) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }
    return _isAuthenticated 
        ? const CounselorDashboard() 
        : const LoginScreen();
  }
}
