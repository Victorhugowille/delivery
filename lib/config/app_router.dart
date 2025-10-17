import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:latlong2/latlong.dart'; // <-- IMPORTAÇÃO ADICIONADA AQUI
import '../screens/cart_screen.dart';
import '../screens/checkout_screen.dart';
import '../screens/company_menu_screen.dart';
import '../screens/home_page.dart';
import '../screens/not_found_screen.dart';
// NOVO IMPORT
import '../screens/payment_screen.dart';
import '../screens/product_detail_screen.dart';

class AppRouter {
  static final router = GoRouter(
    initialLocation: '/',
    errorBuilder: (context, state) => const NotFoundScreen(),
    observers: [DebugObserver()],
    routes: [
      GoRoute(
        path: '/',
        builder: (context, state) {
          return const HomePage();
        },
      ),
      GoRoute(
        path: '/:companyName',
        builder: (context, state) {
          final companyName = state.pathParameters['companyName'];
          if (companyName != null) {
            return CompanyMenuScreen(companyName: companyName);
          }
          return const NotFoundScreen();
        },
      ),
      GoRoute(
        path: '/:companyName/cart',
        builder: (context, state) {
          final companyName = state.pathParameters['companyName'];
          if (companyName != null) {
            return CartScreen(companyName: companyName);
          }
          return const NotFoundScreen();
        },
      ),
      GoRoute(
        path: '/:companyName/checkout',
        builder: (context, state) {
          final companyName = state.pathParameters['companyName'];
          if (companyName != null) {
            return CheckoutScreen(companyName: companyName);
          }
          return const NotFoundScreen();
        },
      ),
      // NOVA ROTA DE PAGAMENTO
      GoRoute(
        path: '/:companyName/payment',
        builder: (context, state) {
          final companyName = state.pathParameters['companyName'];
          // Recebe os dados da tela anterior
          final extra = state.extra as Map<String, dynamic>?;

          if (companyName != null && extra != null) {
            return PaymentScreen(
              companyName: companyName,
              clientData: extra['clientData'] as Map<String, dynamic>,
              locationLink: extra['locationLink'] as String,
              clientLocation: extra['clientLocation'] as LatLng,
            );
          }
          return const NotFoundScreen();
        },
      ),
      GoRoute(
        path: '/:companyName/:productId',
        builder: (context, state) {
          final productId = state.pathParameters['productId'];
          if (productId != null) {
            return ProductDetailScreen(productId: productId);
          }
          return const NotFoundScreen();
        },
      ),
    ],
  );
}

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