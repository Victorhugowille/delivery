import 'package:flutter/material.dart';
import '../models/models.dart';

class CartService {
  // ValueNotifier é uma forma simples de notificar a UI quando o carrinho muda.
  final ValueNotifier<List<CartItem>> items = ValueNotifier([]);

  void addToCart(Product product, int quantity, Set<Adicional> selectedAdicionais) {
    // Converte o Set<Adicional> para a lista de CartItemAdicional que o modelo espera
    final adicionaisDoItem = selectedAdicionais.map((adicional) {
      return CartItemAdicional(adicional: adicional, quantity: 1); // Assumindo quantidade 1 para adicionais
    }).toList();

    // Cria um novo item de carrinho
    final newItem = CartItem(
      // ID único para cada item no carrinho, pode ser melhorado depois
      id: DateTime.now().toIso8601String(),
      product: product,
      quantity: quantity,
      selectedAdicionais: adicionaisDoItem,
    );

    // Adiciona o novo item à lista e notifica os listeners
    items.value = [...items.value, newItem];
    
    // Imprime no console para vermos o que está no carrinho (para debug)
    debugPrint("Item adicionado! Itens no carrinho: ${items.value.length}");
    for (var item in items.value) {
      debugPrint("- ${item.product.name} (x${item.quantity})");
    }
  }
}

// Criamos uma instância global única do nosso serviço
final cartService = CartService();