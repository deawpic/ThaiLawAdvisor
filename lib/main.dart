import 'package:flutter/material.dart';
import 'constants/theme.dart';
import 'services/database_service.dart';
import 'screens/home_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize Hive storage database
  await DatabaseService.init();
  
  runApp(const ThaiLawApp());
}

class ThaiLawApp extends StatelessWidget {
  const ThaiLawApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'วิเคราะห์กฎหมายไทย',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: ThemeMode.system, // Automatically matches system dark/light mode
      home: const HomeScreen(),
    );
  }
}
