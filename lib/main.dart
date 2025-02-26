import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'pages/login_page.dart';
import 'pages/admin/admin_page.dart';
import 'pages/kasir/kasir_page.dart';
import 'pages/owner/owner_page.dart';

Future<void> main() async {
  // Ensure Flutter is initialized
  WidgetsFlutterBinding.ensureInitialized();

  // Reset license registry
  LicenseRegistry.reset();

  // Disable debug prints in release mode
  if (kReleaseMode) {
    debugPrint = (String? message, {int? wrapWidth}) {};
  }

  // Initialize Supabase
  await Supabase.initialize(
    url: 'https://kezbhomtssacupotsbmj.supabase.co',
    anonKey:
        'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImtlemJob210c3NhY3Vwb3RzYm1qIiwicm9sZSI6ImFub24iLCJpYXQiOjE3MzY0NzEwOTEsImV4cCI6MjA1MjA0NzA5MX0.gCLOBWTVU3jFHGTTDWFy_vzJxGdGKx_Crq4LzKdoKNY',
  );

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'InStay',
      // Remove debug banner and other debug elements
      debugShowCheckedModeBanner: false,
      checkerboardRasterCacheImages: false,
      checkerboardOffscreenLayers: false,
      showPerformanceOverlay: false,
      showSemanticsDebugger: false,

      // Theme configuration
      theme: ThemeData(
        primarySwatch: Colors.blue,
        // Add more theme customization here
        scaffoldBackgroundColor: Colors.white,
        appBarTheme: const AppBarTheme(
          elevation: 0,
          backgroundColor: Colors.white,
          iconTheme: IconThemeData(color: Colors.black),
          titleTextStyle: TextStyle(
            color: Colors.black,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            elevation: 0,
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        ),
      ),

      // Route configuration
      initialRoute: '/',
      routes: {
        '/': (context) => const LoginPage(),
        '/admin': (context) => const AdminPage(),
        '/kasir': (context) => const KasirPage(),
        '/owner': (context) => const OwnerPage(),
      },
    );
  }
}

// Create a global Supabase client instance for easy access
class SupabaseClient {
  static final client = Supabase.instance.client;
}
