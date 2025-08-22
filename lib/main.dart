import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'screens/home_screen.dart';
import 'screens/login_screen.dart';
import 'services/db_service.dart';
import 'services/sync_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize database service
  final dbService = DatabaseService();
  
  // Initialize sync service
  final syncService = SyncService(dbService);
  
  runApp(MyApp(dbService: dbService, syncService: syncService));
}

class MyApp extends StatelessWidget {
  final DatabaseService dbService;
  final SyncService syncService;

  const MyApp({
    super.key,
    required this.dbService,
    required this.syncService,
  });

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: dbService),
        ChangeNotifierProvider.value(value: syncService),
      ],
      child: MaterialApp(
        title: 'e-MTC TC',
        theme: ThemeData(
          // Textiles Committee Color Palette
          primarySwatch: Colors.deepOrange,
          primaryColor: const Color(0xFFD84315), // Deep Orange 800
          primaryColorLight: const Color(0xFFFF8A65), // Deep Orange 300
          primaryColorDark: const Color(0xFFBF360C), // Deep Orange 900
          
          // Secondary colors for textile industry
                        colorScheme: ColorScheme.fromSeed(
                seedColor: const Color(0xFFD84315),
                brightness: Brightness.light,
                secondary: const Color(0xFF795548), // Brown 600
                tertiary: const Color(0xFF8D6E63), // Brown 400
                surface: const Color(0xFFFAFAFA), // Grey 50
              ),
          
          useMaterial3: true,
          
          // App Bar Theme
          appBarTheme: const AppBarTheme(
            backgroundColor: Color(0xFFD84315), // Deep Orange 800
            foregroundColor: Colors.white,
            elevation: 2,
            centerTitle: true,
            titleTextStyle: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
          ),
          
          // Elevated Button Theme
          elevatedButtonTheme: ElevatedButtonThemeData(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFD84315),
              foregroundColor: Colors.white,
              elevation: 2,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
          
          // Floating Action Button Theme
          floatingActionButtonTheme: const FloatingActionButtonThemeData(
            backgroundColor: Color(0xFFD84315),
            foregroundColor: Colors.white,
          ),
          
          // Card Theme
          cardTheme: CardTheme(
            elevation: 2,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            color: Colors.white,
          ),
          
          // Input Decoration Theme
          inputDecorationTheme: InputDecorationTheme(
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: Color(0xFFD84315)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: Color(0xFFD84315), width: 2),
            ),
            labelStyle: const TextStyle(color: Color(0xFFD84315)),
          ),
        ),
        home: const AuthWrapper(),
        debugShowCheckedModeBanner: false,
      ),
    );
  }
}

class AuthWrapper extends StatefulWidget {
  const AuthWrapper({super.key});

  @override
  State<AuthWrapper> createState() => _AuthWrapperState();
}

class _AuthWrapperState extends State<AuthWrapper> {
  bool _isLoading = true;
  bool _isLoggedIn = false;

  @override
  void initState() {
    super.initState();
    _checkLoginStatus();
  }

  Future<void> _checkLoginStatus() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final loPhone = prefs.getString('lo_phone');
      
      setState(() {
        _isLoggedIn = loPhone != null && loPhone.isNotEmpty;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoggedIn = false;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    return _isLoggedIn ? const HomeScreen() : const LoginScreen();
  }
} 