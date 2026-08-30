import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:bitsdojo_window/bitsdojo_window.dart';
import 'package:window_manager/window_manager.dart';
import 'screens/splash_screen.dart';
import 'providers/app_provider.dart';
import 'theme/app_theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Set up window for Windows desktop
  if (await windowManager.isWindowExists()) {
    await windowManager.setMinimumSize(const Size(1200, 800));
    await windowManager.setTitle('Moon Cosmetics & Beauty Shop POS');
    await windowManager.setPreventClose(true);
  }
  
  // Set window decorations
  doWhenWindowReady(() {
    appWindow.minSize = const Size(1200, 800);
    appWindow.title = 'Moon Cosmetics & Beauty Shop POS';
    appWindow.alignment = Alignment.center;
    appWindow.show();
  });
  
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => AppProvider(),
      child: MaterialApp(
        title: 'Moon Cosmetics & Beauty Shop POS',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.lightTheme,
        darkTheme: AppTheme.darkTheme,
        themeMode: ThemeMode.light,
        home: const SplashScreen(),
        routes: {
          '/pos': (context) => const PosScreen(),
          '/products': (context) => const ProductsScreen(),
          '/categories': (context) => const CategoriesScreen(),
          '/purchases': (context) => const PurchasesScreen(),
          '/customers': (context) => const CustomersScreen(),
          '/suppliers': (context) => const SuppliersScreen(),
          '/expenses': (context) => const ExpensesScreen(),
          '/accounts': (context) => const AccountsScreen(),
          '/reports': (context) => const ReportsScreen(),
          '/settings': (context) => const SettingsScreen(),
        },
      ),
    );
  }
}