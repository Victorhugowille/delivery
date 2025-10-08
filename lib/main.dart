import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_web_plugins/url_strategy.dart';

// Importa as novas telas
import 'screens/home_screen.dart';
import 'screens/company_menu_screen.dart';
import 'screens/not_found_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  usePathUrlStrategy();

  await Supabase.initialize(
    url: 'https://fhbxegpnztkzqxpkbgkx.supabase.co',
    anonKey:
        'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImZoYnhlZ3BuenRrenF4cGtiZ2t4Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3NTgyODU4OTMsImV4cCI6MjA3Mzg2MTg5M30.SIEamzBeh_NcOIes-ULqU0RjGV1u3w8NCdgKTACoLjI',
  );
  runApp(const MyApp());
}

final supabase = Supabase.instance.client;

final _router = GoRouter(
  errorBuilder: (context, state) => const NotFoundScreen(),
  routes: [
    GoRoute(
      path: '/',
      builder: (context, state) => const HomePage(),
    ),
    GoRoute(
      path: '/:companyName',
      builder: (context, state) {
        final companyName = state.pathParameters['companyName'] ?? 'desconhecida';
        return CompanyMenuScreen(companyName: companyName);
      },
    ),
  ],
);

class MyApp extends StatelessWidget {
  const MyApp({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      debugShowCheckedModeBanner: false,
      routerConfig: _router,
      title: 'Delivery App',
      theme: ThemeData(
        primarySwatch: Colors.deepPurple,
        scaffoldBackgroundColor: const Color(0xFFF5F5F5),
      ),
    );
  }
}