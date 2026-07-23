import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hortihub_new_app/data/models/hub_model.dart';
import 'package:hortihub_new_app/presentation/screens/change_password_screen.dart';
import 'package:hortihub_new_app/presentation/screens/colelction/collection_list_screen.dart';
import 'package:hortihub_new_app/presentation/screens/farmer/farmer_list_screen.dart';
import 'package:hortihub_new_app/presentation/screens/hub_detail_screen.dart';
import 'package:hortihub_new_app/presentation/screens/producion/production_list_screen.dart';
import 'package:hortihub_new_app/presentation/screens/reports/reports_screen.dart';
import 'package:hortihub_new_app/presentation/screens/splash_screen.dart';
import '../providers/auth_provider.dart';
import 'login_screen.dart';
import 'home_screen.dart';
import '../../widgets/drawer_widget.dart';
import 'sales/view_all_sales_screen.dart';
import '../screens/stock/stock_list_screen.dart';
import '../screens/rate/rate_list_screen.dart';

class MainScreen extends ConsumerStatefulWidget {
  const MainScreen({super.key});

  @override
  ConsumerState<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends ConsumerState<MainScreen> {
  String selectedScreen = '/home';
  String? appBarTitle;
  Map? parameters;

  Map<String, Widget> get screens => {
    '/home': const HomeScreen(),
    '/view_sales': ViewAllSalesScreen(),
    '/stock_availability': StockListScreen(),
    '/rates': RateListScreen(),
    '/production': ProductionListScreen(),
    '/collection': CollectionListScreen(),
    '/view_farmers': FarmerListScreen(),
    '/reports': const ReportsScreen(),
    '/settings': const ChangePasswordScreen(),
  };

  void changeScreen(String screen, String title, Map params) {
    setState(() {
      selectedScreen = screen;
      appBarTitle = title;
      parameters = params;
    });
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authStateProvider);

    if (authState.isLoading) {
      return const SplashScreen();
    }

    // Not logged in → show login screen
    if (authState.value == null) {
      return const LoginScreen();
    }

    // After login, if selectedScreen is still '/login' (happens after logout),
    // reset it to home safely
    if (selectedScreen == '/login') {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          setState(() {
            selectedScreen = '/home';
            appBarTitle = 'MEG Horticulture Hub';
            parameters = null;
          });
        }
      });
    }

    // Logged in → show the main scaffold
    return Scaffold(
      backgroundColor: const Color(0xFFF4F6F8),
      appBar: AppBar(
        elevation: 0,
        centerTitle: true,
        title: Text(
          appBarTitle ?? 'MEG Horticulture Hub',
          style: const TextStyle(fontSize: 19, fontWeight: FontWeight.w700, letterSpacing: 0.4, color: Colors.white),
        ),
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [const Color(0xFF6D4C41), const Color(0xFF388E3C)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
        backgroundColor: Colors.transparent,
        foregroundColor: Colors.white,
        shadowColor: Colors.black26,
      ),
      drawer: DrawerWidget(hubs: const [], onScreenChanged: changeScreen),
      body: SafeArea(
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 250),
          child: screens[selectedScreen] ??
              const Center(
                child: Text(
                  'Screen not found',
                  style: TextStyle(fontSize: 15, color: Colors.black54),
                ),
              ),
        ),
      ),
    );
  }
}