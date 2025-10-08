import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/models.dart';

final supabase = Supabase.instance.client;

class CompanyMenuScreen extends StatefulWidget {
  final String companyName;
  const CompanyMenuScreen({super.key, required this.companyName});

  @override
  State<CompanyMenuScreen> createState() => _CompanyMenuScreenState();
}

class _CompanyMenuScreenState extends State<CompanyMenuScreen> {
  late final Future<List<Product>> _productsFuture;

  @override
  void initState() {
    super.initState();
    _productsFuture = _fetchProducts();
  }

  Future<List<Product>> _fetchProducts() async {
    final companyResponse = await supabase
        .from('companies')
        .select('id')
        .ilike('name', widget.companyName)
        .single();
        
    final companyId = companyResponse['id'];

    if (companyId == null) {
      throw 'Empresa não encontrada: ${widget.companyName}';
    }

    // Faz a busca nos produtos e já une com a tabela de categorias
    final productsResponse = await supabase
        .from('produtos')
        .select('*, categorias(name)')
        .eq('company_id', companyId)
        .order('display_order', ascending: true);

    final productList = productsResponse.map<Product>((item) => Product.fromJson(item)).toList();
    return productList;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Cardápio de ${widget.companyName.toUpperCase()}"),
      ),
      body: FutureBuilder<List<Product>>(
        future: _productsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text("Erro ao carregar produtos: ${snapshot.error}"));
          }
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text("Nenhum produto encontrado para esta empresa."));
          }

          final products = snapshot.data!;

          return GridView.builder(
            padding: const EdgeInsets.all(16.0),
            gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
              maxCrossAxisExtent: 300,
              mainAxisSpacing: 16,
              crossAxisSpacing: 16,
              childAspectRatio: 2 / 2.5,
            ),
            itemCount: products.length,
            itemBuilder: (context, index) {
              final product = products[index];
              return Card(
                elevation: 4.0,
                clipBehavior: Clip.antiAlias,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(15.0),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Expanded(
                      child: product.imageUrl != null
                          ? Image.network(
                              product.imageUrl!,
                              fit: BoxFit.cover,
                              // Adiciona um ícone de erro caso a imagem não carregue
                              errorBuilder: (context, error, stackTrace) {
                                return const Icon(Icons.fastfood, size: 60, color: Colors.grey);
                              },
                            )
                          : Container(
                              alignment: Alignment.center,
                              color: Colors.grey[200],
                              child: const Icon(Icons.fastfood, size: 60, color: Colors.grey),
                            ),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(12.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                           Text(
                            product.name,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'R\$ ${product.price.toStringAsFixed(2)}',
                            style: TextStyle(
                              color: Theme.of(context).primaryColor,
                              fontWeight: FontWeight.bold,
                              fontSize: 18,
                            ),
                          ),
                        ],
                      ),
                    ),
                     if (product.isSoldOut)
                      Container(
                        padding: const EdgeInsets.symmetric(vertical: 4),
                        color: Colors.redAccent,
                        child: const Text(
                          'ESGOTADO',
                          textAlign: TextAlign.center,
                          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                        ),
                      ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }
}