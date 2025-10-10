import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';
import '../models/models.dart';

class CartService {
  final ValueNotifier<List<CartItem>> cartNotifier = ValueNotifier([]);
  final Uuid _uuid = const Uuid();

  void addToCart(Product product, int quantity, Set<Adicional> selectedAdicionais) {
    final List<CartItem> currentCart = List.from(cartNotifier.value);

    final List<CartItemAdicional> adicionaisList = selectedAdicionais
        .map((ad) => CartItemAdicional(adicional: ad, quantity: 1))
        .toList();

    adicionaisList.sort((a, b) => a.adicional.id.compareTo(b.adicional.id));

    final String newItemSignature = _generateItemSignature(product.id, adicionaisList);

    int existingItemIndex = currentCart.indexWhere(
        (item) => _generateItemSignature(item.product.id, item.selectedAdicionais) == newItemSignature);

    if (existingItemIndex != -1) {
      final existingItem = currentCart[existingItemIndex];
      existingItem.quantity += quantity;
    } else {
      currentCart.add(
        CartItem(
          id: _uuid.v4(),
          product: product,
          quantity: quantity,
          selectedAdicionais: adicionaisList,
        ),
      );
    }
    cartNotifier.value = currentCart;
  }

  void updateItemQuantity(String cartItemId, int newQuantity) {
    final List<CartItem> currentCart = List.from(cartNotifier.value);
    int itemIndex = currentCart.indexWhere((item) => item.id == cartItemId);

    if (itemIndex != -1) {
      if (newQuantity > 0) {
        currentCart[itemIndex].quantity = newQuantity;
      } else {
        currentCart.removeAt(itemIndex);
      }
      cartNotifier.value = currentCart;
    }
  }

  void removeItem(String cartItemId) {
    final List<CartItem> currentCart = List.from(cartNotifier.value);
    currentCart.removeWhere((item) => item.id == cartItemId);
    cartNotifier.value = currentCart;
  }

  void clearCart() {
    cartNotifier.value = [];
  }

  double get totalCartPrice {
    return cartNotifier.value.fold(0.0, (sum, item) => sum + item.totalPrice);
  }

  int get totalItemCount {
    return cartNotifier.value.fold(0, (sum, item) => sum + item.quantity);
  }

  String _generateItemSignature(String productId, List<CartItemAdicional> adicionais) {
    final adicionalIds = adicionais.map((e) => e.adicional.id).toList()..sort();
    return '$productId-${adicionalIds.join(',')}';
  }
}

final cartService = CartService();