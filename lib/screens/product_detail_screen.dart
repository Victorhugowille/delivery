import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:go_router/go_router.dart';

import '../models/models.dart';
import '../services/cart_service.dart';

class ProductDetailScreen extends StatefulWidget {
  final String productId;
  const ProductDetailScreen({super.key, required this.productId});

  @override
  State<ProductDetailScreen> createState() => _ProductDetailScreenState();
}

class _ProductDetailScreenState extends State<ProductDetailScreen> {
  late final Future<Product> _productFuture;
  late final Future<List<GrupoAdicional>> _gruposFuture;

  int _quantity = 1;
  final Set<Adicional> _selectedAdicionais = {};

  @override
  void initState() {
    super.initState();
    _productFuture = _fetchProductDetails();
    _gruposFuture = _fetchGruposAdicionais();
  }

  Future<Product> _fetchProductDetails() async {
    final response = await Supabase.instance.client
        .from('produtos')
        .select('*, categorias(name)')
        .eq('id', widget.productId)
        .single();
    return Product.fromJson(response);
  }

  Future<List<GrupoAdicional>> _fetchGruposAdicionais() async {
    // CORREÇÃO DE ORDENAÇÃO AQUI
    final response = await Supabase.instance.client
        .from('grupos_adicionais')
        .select('*, adicionais(*)')
        .eq('produto_id', widget.productId)
        .order('display_order', ascending: true); // Garante a ordenação dos grupos

    return response.map((item) => GrupoAdicional.fromJson(item)).toList();
  }

  // MUDANÇA 1: FUNÇÃO DE VALIDAÇÃO
  String? _validateSelections(List<GrupoAdicional> grupos) {
    for (final grupo in grupos) {
      final selectedCountInGroup = _selectedAdicionais
          .where((adicional) => adicional.grupoId == grupo.id)
          .length;

      if (selectedCountInGroup < grupo.minQuantity) {
        return 'Para o grupo "${grupo.name}", você precisa selecionar pelo menos ${grupo.minQuantity} item(ns).';
      }

      if (grupo.maxQuantity != null &&
          selectedCountInGroup > grupo.maxQuantity!) {
        return 'O limite para o grupo "${grupo.name}" é de ${grupo.maxQuantity} item(ns).';
      }
    }
    return null; // Tudo certo
  }

  void _handleAddToCart(Product product, List<GrupoAdicional> grupos, {required bool goToCart}) {
    final validationError = _validateSelections(grupos);

    if (validationError != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(validationError),
          backgroundColor: Colors.red.shade700,
        ),
      );
      return;
    }

    cartService.addToCart(product, _quantity, _selectedAdicionais);
    
    final companyName = GoRouterState.of(context).pathParameters['companyName'];

    if (goToCart && companyName != null) {
      context.go('/$companyName/cart');
    } else {
      context.pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Product>(
      future: _productFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
              body: Center(child: CircularProgressIndicator()));
        }
        if (snapshot.hasError || !snapshot.hasData) {
          return Scaffold(
              appBar: AppBar(),
              body: Center(
                  child: Text(
                      'Não foi possível carregar o produto: ${snapshot.error}')));
        }

        final product = snapshot.data!;
        final screenHeight = MediaQuery.of(context).size.height;

        return Scaffold(
          appBar: AppBar(title: Text(product.name)),
          body: Column(
            children: [
              SizedBox(
                height: screenHeight / 3,
                width: double.infinity,
                child: product.imageUrl != null && product.imageUrl!.isNotEmpty
                    ? Image.network(
                        product.imageUrl!,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) =>
                            const Icon(Icons.photo,
                                size: 80, color: Colors.grey),
                      )
                    : Container(
                        color: Colors.grey[200],
                        child: const Icon(Icons.photo,
                            size: 80, color: Colors.grey)),
              ),
              Expanded(
                child: FutureBuilder<List<GrupoAdicional>>(
                  future: _gruposFuture,
                  builder: (context, snapshotGrupos) {
                    if (snapshotGrupos.connectionState ==
                        ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    if (snapshotGrupos.hasError) {
                      return const Center(
                          child: Text('Erro ao carregar adicionais.'));
                    }

                    final grupos = snapshotGrupos.data ?? [];

                    return Column(
                      children: [
                        Expanded(
                          child: ListView(
                            padding: const EdgeInsets.all(16.0),
                            children: [
                              Text(product.name,
                                  style: Theme.of(context)
                                      .textTheme
                                      .headlineSmall
                                      ?.copyWith(fontWeight: FontWeight.bold)),
                              const SizedBox(height: 8),
                              Text('R\$ ${product.price.toStringAsFixed(2)}',
                                  style: Theme.of(context)
                                      .textTheme
                                      .titleLarge
                                      ?.copyWith(
                                          color: Theme.of(context).primaryColor,
                                          fontWeight: FontWeight.bold)),
                              if (grupos.isNotEmpty) ...[
                                const Divider(height: 32, thickness: 1),
                                ...grupos
                                    .map((grupo) => _buildGrupoAdicional(grupo))
                                    .toList(),
                              ]
                            ],
                          ),
                        ),
                        // MUDANÇA 2: Passa a lista de grupos para o BottomBar
                        _buildBottomBar(product, grupos),
                      ],
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildGrupoAdicional(GrupoAdicional grupo) {
    // MUDANÇA 3: Exibe a regra na tela
    String ruleText = 'Obrigatório: ${grupo.minQuantity}';
    if (grupo.maxQuantity != null) {
      ruleText += ' / Máximo: ${grupo.maxQuantity}';
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        RichText(
          text: TextSpan(
            style: Theme.of(context)
                .textTheme
                .titleMedium
                ?.copyWith(fontWeight: FontWeight.bold),
            children: [
              TextSpan(text: grupo.name),
              TextSpan(
                text: ' ($ruleText)',
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.normal,
                  fontStyle: FontStyle.italic,
                  color: Colors.grey,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        ...grupo.adicionais.map((adicional) {
          return CheckboxListTile(
            title: Text(adicional.name),
            subtitle: Text('+ R\$ ${adicional.price.toStringAsFixed(2)}'),
            value: _selectedAdicionais.contains(adicional),
            onChanged: (isSelected) {
              setState(() {
                if (isSelected == true) {
                  _selectedAdicionais.add(adicional);
                } else {
                  _selectedAdicionais.remove(adicional);
                }
              });
            },
          );
        }).toList(),
        const SizedBox(height: 16),
      ],
    );
  }

  // MUDANÇA 4: Recebe a lista de grupos para poder validar
  Widget _buildBottomBar(Product product, List<GrupoAdicional> grupos) {
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
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              IconButton(
                icon: const Icon(Icons.remove_circle_outline),
                onPressed: () {
                  if (_quantity > 1) setState(() => _quantity--);
                },
              ),
              Text('$_quantity', style: Theme.of(context).textTheme.titleLarge),
              IconButton(
                icon: const Icon(Icons.add_circle_outline),
                onPressed: () => setState(() => _quantity++),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // MUDANÇA 5: Chama a função de validação no clique
          SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton(
              onPressed: () => _handleAddToCart(product, grupos, goToCart: true),
              child: const Text('Adicionar ao Carrinho'),
            ),
          ),
        ],
      ),
    );
  }
}