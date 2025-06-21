import 'package:flutter/material.dart';
import 'package:padidja_expense_app/screens/add_expense_screen.dart';
import 'package:padidja_expense_app/screens/add_users_screen.dart';
import 'package:padidja_expense_app/screens/auth_screen.dart';
import 'package:padidja_expense_app/screens/history_screen.dart';
import 'package:padidja_expense_app/screens/home_screen.dart';
import 'package:padidja_expense_app/screens/spend_line_screen.dart';
import 'package:padidja_expense_app/screens/splash_screen.dart';
import 'package:padidja_expense_app/screens/stats_screen.dart';
import 'package:padidja_expense_app/screens/user_page_screen.dart';
import 'services/database_service.dart';



void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await DatabaseService.database;
  runApp(const PadidjaApp());
}

class PadidjaApp extends StatelessWidget {
  const PadidjaApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Padidja Dépenses',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.indigo,
        scaffoldBackgroundColor: Colors.white,
        inputDecorationTheme: const InputDecorationTheme(
          border: OutlineInputBorder(),
        ),
      ),

      // Ajoute ceci 👇
      initialRoute: '/',
      routes: {
        '/': (context) => const SplashScreen(),
        '/login': (context) => const AuthScreen(),
        '/home': (context) => const HomeScreen(),
        '/add': (context) => const AddExpenseScreen(),
        '/stats': (context) => const StatsScreen(),
        '/history': (context) =>  HistoryScreen(),
        '/adduser': (context) =>  UserFormPage(),
        '/userpage': (context) =>  UserListPage (),
        'spendline': (context) =>  SpendLinePage(),


      },
    );
  }
}
