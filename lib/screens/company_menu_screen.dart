import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/models.dart';

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

    final results = await Future.wait([categoriesFuture, productsFuture]);

    final categoryList = (results[0] as List)
        .map<Category>((item) => Category.fromJson(item))
        .toList();

    final productList = (results[1] as List)
        .map<Product>((item) => Product.fromJson(item))
        .toList();

    return MenuData(categories: categoryList, products: productList);
  }

  Widget _buildCategoryList(List<Category> categories, BuildContext context) {
    return SizedBox(
      height: 50,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 4.0),
        itemCount: categories.length + 1,
        itemBuilder: (context, index) {
          final isAllSelected = _selectedCategoryId == null;
          if (index == 0) {
            return Padding(
              padding: const EdgeInsets.only(right: 8.0),
              child: ChoiceChip(
                label: const Text('Todos'),
                selected: isAllSelected,
                selectedColor: Theme.of(context).primaryColor,
                labelStyle: TextStyle(
                  color: isAllSelected ? Colors.white : Colors.black,
                  fontWeight: FontWeight.bold,
                ),
                onSelected: (selected) {
                  if (selected) setState(() => _selectedCategoryId = null);
                },
              ),
            );
          }
          
          final category = categories[index - 1];
          final isSelected = _selectedCategoryId == category.id;
          return Padding(
            padding: const EdgeInsets.only(right: 8.0),
            child: ChoiceChip(
              label: Text(category.name),
              selected: isSelected,
              selectedColor: Theme.of(context).primaryColor,
              labelStyle: TextStyle(
                color: isSelected ? Colors.white : Colors.black,
                fontWeight: FontWeight.bold,
              ),
              onSelected: (selected) {
                if (selected) setState(() => _selectedCategoryId = category.id);
              },
            ),
          );
        },
      ),
    );
  }

  Widget _buildProductGrid(List<Product> allProducts) {
    final filteredProducts = _selectedCategoryId == null
      ? allProducts
      : allProducts.where((p) => p.categoryId == _selectedCategoryId).toList();

    if (filteredProducts.isEmpty) {
      return const Expanded(
        child: Center(
          child: Text("Nenhum produto encontrado nesta categoria.", style: TextStyle(fontSize: 16))
        )
      );
    }

    return Expanded(
      child: GridView.builder(
        padding: const EdgeInsets.all(16.0),
        gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
          maxCrossAxisExtent: 220,
          mainAxisSpacing: 20,
          crossAxisSpacing: 20,
          childAspectRatio: 2 / 2.9,
        ),
        itemCount: filteredProducts.length,
        itemBuilder: (context, index) {
          final product = filteredProducts[index];
          return Card(
            elevation: 5.0,
            shadowColor: Colors.black26,
            clipBehavior: Clip.antiAlias,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(15.0),
            ),
            child: InkWell(
              onTap: () {
                // NAVEGAÇÃO IMPLEMENTADA AQUI
                context.go('/${widget.companyName}/${product.id}', extra: product);
              },
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Expanded(
                    child: product.imageUrl != null && product.imageUrl!.isNotEmpty
                        ? Image.network(
                            product.imageUrl!,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) {
                              return Container(alignment: Alignment.center, color: Colors.grey[200], child: const Icon(Icons.fastfood, size: 50, color: Colors.grey));
                            },
                          )
                        : Container(
                            alignment: Alignment.center,
                            color: Colors.grey[200],
                            child: const Icon(Icons.fastfood, size: 50, color: Colors.grey),
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
                          product.categoryName,
                          style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 8),
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
                      color: Colors.redAccent.withOpacity(0.85),
                      child: const Text(
                        'ESGOTADO',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12),
                      ),
                    ),
                ],
              ),
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
          if (!snapshot.hasData || snapshot.data!.categories.isEmpty) {
            return const Center(child: Text("Nenhuma categoria encontrada para esta empresa."));
          }

          final menuData = snapshot.data!;
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.only(left: 16.0, top: 16.0, bottom: 8.0),
                child: Text(
                  'Categorias',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                ),
              ),
              _buildCategoryList(menuData.categories, context),
              _buildProductGrid(menuData.products),
            ],
          );
        },
      ),
    );
  }
}