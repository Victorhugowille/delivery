import 'package:carousel_slider/carousel_slider.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/models.dart' as model;
import '../services/cart_service.dart';
import '../services/theme_service.dart';

class CompanyPageData {
  final model.Company company;
  final List<model.DestaqueSite> destaques;
  final List<model.Category> categories;
  final List<model.Product> products;
  CompanyPageData(
      {required this.company,
      required this.destaques,
      required this.categories,
      required this.products});
}

final supabase = Supabase.instance.client;

class CompanyMenuScreen extends StatefulWidget {
  final String companyName;
  const CompanyMenuScreen({super.key, required this.companyName});

  @override
  State<CompanyMenuScreen> createState() => _CompanyMenuScreenState();
}

class _CompanyMenuScreenState extends State<CompanyMenuScreen> {
  late final Future<CompanyPageData> _pageDataFuture;
  String? _selectedCategoryId;

  @override
  void initState() {
    super.initState();
    _pageDataFuture = _fetchPageData();
  }

  Future<CompanyPageData> _fetchPageData() async {
    final companyResponse = await supabase
        .from('companies')
        .select()
        .ilike('slug', widget.companyName)
        .single();

    final company = model.Company.fromJson(companyResponse);
    themeService.updateTheme(company.colorSite);
    final companyId = company.id;

    if (companyId.isEmpty) {
      throw 'Empresa não encontrada: ${widget.companyName}';
    }

    final results = await Future.wait([
      supabase
          .from('destaque_site')
          .select()
          .eq('company_id', companyId)
          .order('slot_number', ascending: true),
      supabase
          .from('categorias')
          .select()
          .eq('company_id', companyId)
          .order('display_order', ascending: true),
      supabase
          .from('produtos')
          .select('*, categorias(name)')
          .eq('company_id', companyId)
          .order('display_order', ascending: true),
    ]);

    final destaquesList = (results[0] as List)
        .map<model.DestaqueSite>((item) => model.DestaqueSite.fromJson(item))
        .toList();

    final categoryList = (results[1] as List)
        .map<model.Category>((item) => model.Category.fromJson(item))
        .toList();

    final productList = (results[2] as List)
        .map<model.Product>((item) => model.Product.fromJson(item))
        .toList();

    return CompanyPageData(
        company: company,
        destaques: destaquesList,
        categories: categoryList,
        products: productList);
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<CompanyPageData>(
      future: _pageDataFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(body: Center(child: CircularProgressIndicator()));
        }
        if (snapshot.hasError) {
          return Scaffold(
              appBar: AppBar(title: const Text("Erro")),
              body: Center(
                  child:
                      Text("Erro ao carregar o cardápio: ${snapshot.error}")));
        }
        if (!snapshot.hasData) {
          return const Scaffold(
              body: Center(child: Text("Nenhum dado encontrado.")));
        }

        final pageData = snapshot.data!;
        final company = pageData.company;

        return Scaffold(
          appBar: PreferredSize(
            preferredSize: const Size.fromHeight(kToolbarHeight),
            child: ValueListenableBuilder<Color>(
              valueListenable: themeService.colorNotifier,
              builder: (context, color, child) {
                return AppBar(
                  title: Row(
                    children: [
                      // ### WIDGET DA LOGO OTIMIZADO ###
                      if (company.logoUrl != null && company.logoUrl!.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(right: 12.0),
                          // Usamos ClipOval para garantir o formato circular
                          child: ClipOval(
                            child: Container(
                              width: 40, // Tamanho do círculo
                              height: 40,
                              color: Colors.white, // Fundo branco caso a imagem demore a carregar
                              child: Image.network(
                                company.logoUrl!,
                                fit: BoxFit.cover,
                                // Melhora a qualidade da imagem ao redimensionar
                                filterQuality: FilterQuality.high,
                                // Mostra um ícone enquanto carrega
                                loadingBuilder: (context, child, progress) {
                                  if (progress == null) return child;
                                  return const Center(child: SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.grey)));
                                },
                                // Mostra um ícone de erro se falhar
                                errorBuilder: (context, error, stack) => const Icon(Icons.store, color: Colors.grey),
                              ),
                            ),
                          ),
                        ),
                      Text(company.name.toUpperCase()),
                    ],
                  ),
                  backgroundColor: color,
                  foregroundColor: Colors.white,
                  surfaceTintColor: color,
                  elevation: 1,
                  shadowColor: Colors.black26,
                );
              },
            ),
          ),
          body: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHighlightsCarousel(pageData.destaques),
              _buildCategoryList(pageData.categories, context),
              _buildProductList(pageData.products),
            ],
          ),
          floatingActionButton: ValueListenableBuilder<List<model.CartItem>>(
            valueListenable: cartService.cartNotifier,
            builder: (context, cartItems, child) {
              if (cartItems.isEmpty) {
                return const SizedBox.shrink();
              }
              return FloatingActionButton.extended(
                onPressed: () => context.go('/${widget.companyName}/cart'),
                label: Text('Ver Carrinho (${cartService.totalItemCount})'),
                icon: const Icon(Icons.shopping_cart),
              );
            },
          ),
        );
      },
    );
  }

  Widget _buildHighlightsCarousel(List<model.DestaqueSite> destaques) {
    if (destaques.isEmpty) {
      return const SizedBox.shrink();
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 20.0),
      child: CarouselSlider.builder(
        itemCount: destaques.length,
        itemBuilder: (context, index, realIndex) {
          final destaque = destaques[index];
          return ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Image.network(
              destaque.imageUrl,
              fit: BoxFit.cover,
              width: 1000,
            ),
          );
        },
        options: CarouselOptions(
          height: 200.0,
          autoPlay: true,
          autoPlayInterval: const Duration(seconds: 8),
          enlargeCenterPage: true,
          viewportFraction: 0.8,
        ),
      ),
    );
  }

  Widget _buildCategoryList(List<model.Category> categories, BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12.0),
      decoration: BoxDecoration(
          color: Colors.white,
          border: Border(bottom: BorderSide(color: Colors.grey.shade200))),
      child: SizedBox(
        height: 40,
        child: ListView.builder(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          itemCount: categories.length,
          itemBuilder: (context, index) {
            final category = categories[index];
            final isSelected = _selectedCategoryId == category.id;
            return Padding(
              padding: const EdgeInsets.only(right: 8.0),
              child: ChoiceChip(
                label: Text(category.name),
                selected: isSelected,
                onSelected: (selected) {
                  if (selected) setState(() => _selectedCategoryId = category.id);
                },
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildProductList(List<model.Product> allProducts) {
    final filteredProducts = _selectedCategoryId == null
        ? allProducts
        : allProducts.where((p) => p.categoryId == _selectedCategoryId).toList();

    if (filteredProducts.isEmpty) {
      return const Expanded(
          child: Center(
              child: Text("Nenhum produto encontrado nesta categoria.",
                  style: TextStyle(fontSize: 16))));
    }

    return Expanded(
      child: ListView.builder(
        padding: const EdgeInsets.fromLTRB(8, 16, 8, 96),
        itemCount: filteredProducts.length,
        itemBuilder: (context, index) {
          final product = filteredProducts[index];
          return _ProductListItem(
            product: product,
            onTap: () => context.go('/${widget.companyName}/${product.id}'),
          );
        },
      ),
    );
  }
}

class _ProductListItem extends StatelessWidget {
  final model.Product product;
  final VoidCallback onTap;

  const _ProductListItem({required this.product, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: product.isSoldOut ? null : onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12.0),
          border: Border.all(color: Colors.grey.shade200, width: 1.5),
        ),
        child: Row(
          children: [
            SizedBox(
              width: 90,
              height: 90,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(10.0),
                child: product.imageUrl != null && product.imageUrl!.isNotEmpty
                    ? Image.network(
                        product.imageUrl!,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) =>
                            _buildPlaceholder(),
                      )
                    : _buildPlaceholder(),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    product.name,
                    style: const TextStyle(
                        fontWeight: FontWeight.bold, fontSize: 16),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    product.categoryName,
                    style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'R\$ ${product.price.toStringAsFixed(2)}',
                    style: TextStyle(
                      color: product.isSoldOut
                          ? Colors.grey
                          : Theme.of(context).colorScheme.primary,
                      fontWeight: FontWeight.w600,
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            if (product.isSoldOut)
              const Text(
                'Esgotado',
                style:
                    TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
              )
            else
              const Icon(Icons.keyboard_arrow_right, color: Colors.grey),
          ],
        ),
      ),
    );
  }

  Widget _buildPlaceholder() {
    return Container(
      color: Colors.grey.shade100,
      child: const Icon(Icons.fastfood, size: 40, color: Colors.grey),
    );
  }
}