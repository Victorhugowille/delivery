import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:url_strategy/url_strategy.dart';
import 'config/app_router.dart';
import 'services/theme_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  setPathUrlStrategy();

  await Supabase.initialize(
    url: 'https://fhbxegpnztkzqxpkbgkx.supabase.co',
    anonKey:
        'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImZoYnhlZ3BuenRrenF4cGtiZ2t4Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3NTgyODU4OTMsImV4cCI6MjA3Mzg2MTg5M30.SIEamzBeh_NcOIes-ULqU0RjGV1u3w8NCdgKTACoLjI',
  );

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    // Escuta pelo 'Color' simples do notifier
    return ValueListenableBuilder<Color>(
      valueListenable: themeService.colorNotifier,
      builder: (_, color, __) {
        return MaterialApp.router(
          title: 'Delivery App',
          theme: ThemeData(
            useMaterial3: true,
            // Usa o 'Color' recebido diretamente como a semente do tema
            colorScheme: ColorScheme.fromSeed(seedColor: color),
            
            // O ColorScheme já cuida de aplicar a cor na maioria dos widgets.
            // Podemos adicionar personalizações extras se necessário.
            appBarTheme: AppBarTheme(
              backgroundColor: color, // Força a cor exata na AppBar
              foregroundColor: Colors.white,
            ),
             chipTheme: ChipThemeData(
              selectedColor: color, // Força a cor exata no Chip
              secondaryLabelStyle: const TextStyle(color: Colors.white), 
            ),
          ),
          routerConfig: AppRouter.router,
          debugShowCheckedModeBanner: false,
        );
      },
    );
  }
} 
