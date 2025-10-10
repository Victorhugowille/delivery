import 'package:flutter/material.dart';
import '../models/models.dart';
import '../services/cart_service.dart';

class CartScreen extends StatelessWidget {
  const CartScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Meu Carrinho'),
        centerTitle: true,
      ),
      body: ValueListenableBuilder<List<CartItem>>(
        valueListenable: cartService.cartNotifier,
        builder: (context, cartItems, child) {
          if (cartItems.isEmpty) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.shopping_cart_outlined, size: 80, color: Colors.grey),
                  SizedBox(height: 16),
                  Text(
                    'Seu carrinho está vazio.',
                    style: TextStyle(fontSize: 18, color: Colors.grey),
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(8.0),
            itemCount: cartItems.length,
            itemBuilder: (context, index) {
              final item = cartItems[index];
              return _buildCartItemCard(context, item);
            },
          );
        },
      ),
      bottomNavigationBar: _buildBottomBar(),
    );
  }

  Widget _buildCartItemCard(BuildContext context, CartItem item) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 4.0),
      elevation: 3,
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (item.product.imageUrl != null && item.product.imageUrl!.isNotEmpty)
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8.0),
                    child: Image.network(
                      item.product.imageUrl!,
                      width: 70,
                      height: 70,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) =>
                          const Icon(Icons.image_not_supported, size: 70),
                    ),
                  )
                else
                  Container(
                    width: 70,
                    height: 70,
                    decoration: BoxDecoration(
                      color: Colors.grey[200],
                      borderRadius: BorderRadius.circular(8.0),
                    ),
                    child: const Icon(Icons.fastfood, size: 40, color: Colors.grey),
                  ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.product.name,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'R\$ ${item.totalPrice.toStringAsFixed(2)}',
                        style: TextStyle(
                          fontSize: 16,
                          color: Theme.of(context).primaryColor,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      if (item.selectedAdicionais.isNotEmpty) ...[
                        const SizedBox(height: 6),
                        Text(
                          item.selectedAdicionais
                              .map((e) => '+ ${e.adicional.name}')
                              .join('\n'),
                          style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                        ),
                      ]
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.delete_outline, color: Colors.red),
                  onPressed: () => cartService.removeItem(item.id),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                IconButton(
                  icon: const Icon(Icons.remove_circle_outline),
                  onPressed: () {
                    if (item.quantity > 1) {
                      cartService.updateItemQuantity(item.id, item.quantity - 1);
                    } else {
                      cartService.removeItem(item.id);
                    }
                  },
                ),
                Text(
                  '${item.quantity}',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                IconButton(
                  icon: const Icon(Icons.add_circle_outline),
                  onPressed: () => cartService.updateItemQuantity(item.id, item.quantity + 1),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomBar() {
    return ValueListenableBuilder<List<CartItem>>(
      valueListenable: cartService.cartNotifier,
      builder: (context, cartItems, child) {
        if (cartItems.isEmpty) {
          return const SizedBox.shrink();
        }

        return Container(
          padding: const EdgeInsets.all(16.0).copyWith(bottom: 24.0),
          decoration: BoxDecoration(
            color: Colors.white,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 10,
                spreadRadius: 2,
              ),
            ],
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(20),
              topRight: Radius.circular(20),
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Total:',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  Text(
                    'R\$ ${cartService.totalCartPrice.toStringAsFixed(2)}',
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.green,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  onPressed: () {
                  },
                  child: const Text(
                    'Finalizar Pedido',
                    style: TextStyle(fontSize: 18),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}