import 'package:flutter/material.dart';
import 'package:padidja_expense_app/screens/add_expense_screen.dart';
import 'package:padidja_expense_app/screens/add_transaction_screen.dart';
import 'package:padidja_expense_app/screens/add_users_screen.dart';
import 'package:padidja_expense_app/screens/add_wallet_screen.dart';
import 'package:padidja_expense_app/screens/auth_screen.dart';
import 'package:padidja_expense_app/screens/history_screen.dart';
import 'package:padidja_expense_app/screens/home_screen.dart';
import 'package:padidja_expense_app/screens/home_wallet_screen.dart';
import 'package:padidja_expense_app/screens/setting_screen.dart';
import 'package:padidja_expense_app/screens/spend_line_screen.dart';
import 'package:padidja_expense_app/screens/splash_screen.dart';
import 'package:padidja_expense_app/screens/stats_screen.dart';
import 'package:padidja_expense_app/screens/user_page_screen.dart';
import 'package:padidja_expense_app/screens/verify_wallet_screen.dart';
import 'package:padidja_expense_app/models/user_model.dart';
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
    // Placeholder user data (replace with actual user data from authentication)
    final placeholderUser = Utilisateur(
      id: 1,
      nom: 'Yennefer Doe',
      email: 'yennefer.doe@email.com',
      motDePasse: 'password123',
      role: 'user',
    );

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
      initialRoute: '/login', // Start with login, then navigate to verification
      routes: {
        '/': (context) => const SplashScreen(),
        '/login': (context) => const AuthScreen(),
        '/home': (context) => const HomeScreen(),
        '/add': (context) => const AddExpenseScreen(),
        '/stats': (context) => const StatsScreen(),
        '/history': (context) => const HistoryScreen(),
        '/adduser': (context) => UserFormPage(),
        '/userpage': (context) => UserListPage(),
        '/spendline': (context) => const SpendLinePage(),
        '/settings': (context) => SettingsPage(utilisateur: placeholderUser),
        '/addwallet': (context) => const AddWalletScreen(),
        '/addTransaction': (context) => const AddTransactionScreen(),
        '/wallets': (context) => const WalletHomeScreen(),
        '/verifyWallet': (context) => const WalletVerificationScreen(
              currentTotalBalance: 0.0,
              globalWalletLimit: double.infinity,
            ),
      },
    );
  }
}