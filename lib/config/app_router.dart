import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../models/models.dart';
import '../screens/cart_screen.dart';
import '../screens/company_menu_screen.dart';
import '../screens/home_page.dart';
import '../screens/not_found_screen.dart';
import '../screens/product_detail_screen.dart';

class AppRouter {
  static final router = GoRouter(
    initialLocation: '/',
    errorBuilder: (context, state) => const NotFoundScreen(),
    // Adicionando um log para depuração. Verifique o console quando navegar.
    observers: [DebugObserver()],
    routes: [
      GoRoute(
        path: '/',
        builder: (context, state) {
          debugPrint("Navegando para: / (HomePage)");
          return const HomePage();
        },
      ),
      GoRoute(
        path: '/:companyName',
        builder: (context, state) {
          final companyName = state.pathParameters['companyName'];
          debugPrint("Navegando para Rota de Companhia: /$companyName");
          if (companyName != null) {
            return CompanyMenuScreen(companyName: companyName);
          }
          // Se o nome for nulo, vai para a página de erro
          return const NotFoundScreen();
        },
      ),
      GoRoute(
        path: '/:companyName/cart',
        builder: (context, state) {
          final companyName = state.pathParameters['companyName'];
           debugPrint("Navegando para Carrinho: /$companyName/cart");
          return const CartScreen();
        },
      ),
      GoRoute(
        path: '/:companyName/:productId',
        builder: (context, state) {
          final companyName = state.pathParameters['companyName'];
          final productId = state.pathParameters['productId'];
          debugPrint("Navegando para Produto: /$companyName/$productId");
          if (productId != null) {
            return ProductDetailScreen(productId: productId);
          }
          return const NotFoundScreen();
        },
      ),
    ],
  );
}

// Classe auxiliar para imprimir logs de navegação no console
class DebugObserver extends NavigatorObserver {
  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) {
    debugPrint('GoRouter didPush: ${route.settings.name}');
  }
   @override
  void didPop(Route<dynamic> route, Route<dynamic>? previousRoute) {
    debugPrint('GoRouter didPop: ${route.settings.name}');
  }
}