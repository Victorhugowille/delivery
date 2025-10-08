import 'package.flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/models.dart';

// Helper class to hold both categories and products from our single fetch
class MenuData {
  final List<Category> categories;
  final List<Product> products;
  MenuData({required this.categories, required this.products});
}

final supabase = Supabase.instance.client;

class CompanyMenuScreen extends StatefulWidget {
  final String companyName;
  const CompanyMenuScreen({super.key, required this.companyName});

  @override
  State<CompanyMenuScreen> createState() => _CompanyMenuScreenState();
}

class _CompanyMenuScreenState extends State<CompanyMenuScreen> {
  late final Future<MenuData> _menuDataFuture;
  // State variable to store the ID of the selected category.
  // Null means "Todos".
  String? _selectedCategoryId;

  @override
  void initState() {
    super.initState();
    _menuDataFuture = _fetchMenuData();
  }

  Future<MenuData> _fetchMenuData() async {
    final companyResponse = await supabase
        .from('companies')
        .select('id')
        .ilike('name', widget.companyName)
        .single();
        
    final companyId = companyResponse['id'];

    if (companyId == null) {
      throw 'Empresa não encontrada: ${widget.companyName}';
    }

    // Create two separate futures for categories and products
    final categoriesFuture = supabase
        .from('categorias')
        .select()
        .eq('company_id', companyId)
        .order('display_order', ascending: true);

    final productsFuture = supabase
        .from('produtos')
        .select('*, categorias(name)')
        .eq('company_id', companyId)
        .order('display_order', ascending: true);

    // Wait for both to complete in parallel
    final results = await Future.wait([categoriesFuture, productsFuture]);

    // Parse the results
    final categoryList = (results[0] as List)
        .map<Category>((item) => Category.fromJson(item))
        .toList();

    final productList = (results[1] as List)
        .map<Product>((item) => Product.fromJson(item))
        .toList();

    return MenuData(categories: categoryList, products: productList);
  }

  // Helper method to build the category filter chips
  Widget _buildCategoryList(List<Category> categories) {
    return SizedBox(
      height: 50,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16.0),
        itemCount: categories.length + 1, // +1 for the "Todos" chip
        itemBuilder: (context, index) {
          if (index == 0) {
            // This is the "Todos" (All) chip
            return Padding(
              padding: const EdgeInsets.only(right: 8.0),
              child: ChoiceChip(
                label: const Text('Todos'),
                selected: _selectedCategoryId == null,
                onSelected: (selected) {
                  if (selected) {
                    setState(() {
                      _selectedCategoryId = null;
                    });
                  }
                },
              ),
            );
          }
          
          final category = categories[index - 1];
          return Padding(
            padding: const EdgeInsets.only(right: 8.0),
            child: ChoiceChip(
              label: Text(category.name),
              selected: _selectedCategoryId == category.id,
              onSelected: (selected) {
                if (selected) {
                  setState(() {
                    _selectedCategoryId = category.id;
                  });
                }
              },
            ),
          );
        },
      ),
    );
  }

  // Helper method to build the filtered product grid
  Widget _buildProductGrid(List<Product> allProducts) {
    final filteredProducts = _selectedCategoryId == null
      ? allProducts // If "Todos" is selected, show all products
      : allProducts.where((p) => p.categoryId == _selectedCategoryId).toList();

    if (filteredProducts.isEmpty) {
      return const Center(child: Text("Nenhum produto encontrado nesta categoria."));
    }

    return Expanded(
      child: GridView.builder(
        padding: const EdgeInsets.all(16.0),
        gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
          maxCrossAxisExtent: 250,
          mainAxisSpacing: 16,
          crossAxisSpacing: 16,
          childAspectRatio: 2 / 2.8,
        ),
        itemCount: filteredProducts.length,
        itemBuilder: (context, index) {
          final product = filteredProducts[index];
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
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'R\$ ${product.price.toStringAsFixed(2)}',
                        style: TextStyle(
                          color: Theme.of(context).primaryColorDark,
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
                    color: Colors.redAccent.withOpacity(0.8),
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
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Cardápio de ${widget.companyName.toUpperCase()}"),
      ),
      body: FutureBuilder<MenuData>(
        future: _menuDataFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text("Erro ao carregar o cardápio: ${snapshot.error}"));
          }
          if (!snapshot.hasData) {
            return const Center(child: Text("Nenhum dado encontrado para esta empresa."));
          }

          final menuData = snapshot.data!;
          final categories = menuData.categories;
          final products = menuData.products;

          return Column(
            children: [
              const SizedBox(height: 16),
              _buildCategoryList(categories),
              const Divider(),
              _buildProductGrid(products),
            ],
          );
        },
      ),
    );
  }
}