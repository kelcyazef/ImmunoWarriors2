import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'screens/auth/login_screen.dart';
import 'screens/home/home_screen.dart';
import 'providers/auth_providers.dart';

import 'services/data_sync_service.dart';
import 'services/game_state_storage.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize Firebase
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  
  // Initialize Hive for local storage
  await GameStateStorage.initialize();
  
  runApp(const ProviderScope(child: ImmunoWarriorsApp()));
}

class ImmunoWarriorsApp extends ConsumerWidget {
  const ImmunoWarriorsApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Updated color scheme with white as primary background
    const navyBlue = Color(0xFF0A2342); // Navy blue for accents/tabs
    const secondaryColor = Color(0xFF42A5F5); // Light blue accent
    const accentTeal = Color(0xFF26C6DA); // Teal accent for edit buttons

    final lightColorScheme = ColorScheme.light(
      // Use white as primary background
      primary: Colors.white,
      // Navy blue as accent color
      secondary: navyBlue,
      tertiary: accentTeal,
      surface: Colors.white,
      background: Colors.white,
      error: Colors.red[700]!,
      onPrimary: Colors.black87, // Text on white background
      onSecondary: Colors.white, // Text on navy blue
      onSurface: Colors.black87,
      onBackground: Colors.black87,
      onError: Colors.white,
    );

    final darkColorScheme = ColorScheme.dark(
      primary: navyBlue,
      secondary: secondaryColor, 
      tertiary: accentTeal,
      surface: const Color(0xFF1A2030),
      background: const Color(0xFF0F1623),
      error: Colors.red[700]!,
      onPrimary: Colors.white,
      onSecondary: Colors.black,
      onSurface: Colors.white,
      onBackground: Colors.white,
      onError: Colors.black,
    );

    return MaterialApp(
      title: 'ImmunoWarriors',
      theme: ThemeData(
        colorScheme: lightColorScheme,
        useMaterial3: true,
        scaffoldBackgroundColor: lightColorScheme.primary,
        appBarTheme: AppBarTheme(
          backgroundColor: lightColorScheme.primary,
          foregroundColor: lightColorScheme.onPrimary,
          elevation: 0,
          centerTitle: true,
        ),
        cardTheme: CardTheme(
          color: Colors.white,
          elevation: 5,
          shadowColor: Colors.black.withOpacity(0.2),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
          margin: const EdgeInsets.symmetric(vertical: 8),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: Colors.white,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(32),
            borderSide: BorderSide.none,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(32),
            borderSide: BorderSide.none,
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(32),
            borderSide: BorderSide.none,
          ),
          contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: lightColorScheme.primary,
            foregroundColor: Colors.white,
            elevation: 0,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(32)),
            padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 20),
            minimumSize: const Size(double.infinity, 48),
          ),
        ),
        textButtonTheme: TextButtonThemeData(
          style: TextButton.styleFrom(
            foregroundColor: lightColorScheme.secondary,
            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
          ),
        ),
      ),
      darkTheme: ThemeData(
        colorScheme: darkColorScheme,
        useMaterial3: true,
        scaffoldBackgroundColor: darkColorScheme.primary,
        appBarTheme: AppBarTheme(
          backgroundColor: darkColorScheme.primary,
          foregroundColor: darkColorScheme.onPrimary,
          elevation: 0,
          centerTitle: true,
        ),
        cardTheme: CardTheme(
          color: darkColorScheme.surface,
          elevation: 5,
          shadowColor: Colors.black.withOpacity(0.3),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
          margin: const EdgeInsets.symmetric(vertical: 8),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: darkColorScheme.surface,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(32),
            borderSide: BorderSide.none,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(32),
            borderSide: BorderSide.none,
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(32),
            borderSide: BorderSide.none,
          ),
          contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: darkColorScheme.primary,
            foregroundColor: Colors.white,
            elevation: 0,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(32)),
            padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 20),
            minimumSize: const Size(double.infinity, 48),
          ),
        ),
        textButtonTheme: TextButtonThemeData(
          style: TextButton.styleFrom(
            foregroundColor: darkColorScheme.secondary,
            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
          ),
        ),
      ),
      themeMode: ThemeMode.system,
      home: const AuthGate(),
    );
  }
}

class AuthGate extends ConsumerStatefulWidget {
  const AuthGate({super.key});

  @override
  ConsumerState<AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends ConsumerState<AuthGate> {
  @override
  void initState() {
    super.initState();
    // Initialize data sync when app starts
    _initializeDataSync();
  }
  
  Future<void> _initializeDataSync() async {
    // Get data sync service
    final dataSyncService = ref.read(dataSyncServiceProvider);
    
    // Load from local storage immediately
    await dataSyncService.loadFromLocalStorage();
    
    // Listen to auth state changes for syncing with Firestore
    ref.listen(authStateProvider, (previous, next) {
      next.whenData((user) {
        if (user != null) {
          // User is logged in, perform full sync
          _syncUserData();
        }
      });
    });
  }
  
  Future<void> _syncUserData() async {
    final dataSyncService = ref.read(dataSyncServiceProvider);
    await dataSyncService.performFullSync();
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authStateProvider);

    return authState.when(
      data: (user) => user != null ? const HomeScreen() : const LoginScreen(),
      loading: () => const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      ),
      error: (error, stackTrace) => Scaffold(
        body: Center(
          child: Text('Error: $error'),
        ),
      ),
    );
  }
}
