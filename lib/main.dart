import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'screens/home_screen.dart';
import 'services/db_service.dart';
import 'services/sync_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize database
  final dbService = DatabaseService();
  await dbService.initDatabase();
  
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
        title: 'eMTC - Electronic Market for Textiles and Clothing (TC, GoI)',
        theme: ThemeData(
          primarySwatch: Colors.blue,
          useMaterial3: true,
          appBarTheme: const AppBarTheme(
            backgroundColor: Colors.blue,
            foregroundColor: Colors.white,
            elevation: 2,
          ),
        ),
        home: const HomeScreen(),
        debugShowCheckedModeBanner: false,
      ),
    );
  }
} 