import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_web_plugins/url_strategy.dart';

// Modelo de Produto
class Product {
  final String id;
  final String name;
  final double price;
  final String categoryName;

  Product({
    required this.id,
    required this.name,
    required this.price,
    required this.categoryName,
  });

  factory Product.fromJson(Map<String, dynamic> json) {
    return Product(
      id: json['id']?.toString() ?? '',
      name: json['name'] ?? 'Produto Inválido',
      price: (json['price'] as num?)?.toDouble() ?? 0.0,
      categoryName: json['categorias']?['name'] ?? 'Sem Categoria',
    );
  }
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Garante que o go_router use a URL limpa (ex: /teds)
  usePathUrlStrategy();

  await Supabase.initialize(
    url: 'https://fhbxegpnztkzqxpkbgkx.supabase.co',
    anonKey:
        'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImZoYnhlZ3BuenRrenF4cGtiZ2t4Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3NTgyODU4OTMsImV4cCI6MjA3Mzg2MTg5M30.SIEamzBeh_NcOIes-ULqU0RjGV1u3w8NCdgKTACoLjI',
  );
  runApp(const MyApp());
}

final supabase = Supabase.instance.client;

final _router = GoRouter(
  errorBuilder: (context, state) => const NotFoundScreen(),
  routes: [
    GoRoute(
      path: '/',
      builder: (context, state) => const HomePage(),
    ),
    GoRoute(
      path: '/:companyName',
      builder: (context, state) {
        final companyName = state.pathParameters['companyName'] ?? 'desconhecida';
        return CompanyMenuScreen(companyName: companyName);
      },
    ),
  ],
);

class MyApp extends StatelessWidget {
  const MyApp({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      routerConfig: _router,
      title: 'Delivery App',
      theme: ThemeData(primarySwatch: Colors.deepPurple),
    );
  }
}

class HomePage extends StatelessWidget {
  const HomePage({super.key});
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Delivery Villa')),
      body: const Center(
        child: Text('Página inicial. Use a URL /nome-da-empresa para ver um cardápio.'),
      ),
    );
  }
}

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
        .ilike('name', widget.companyName) // Usando ilike para ignorar maiúsculas/minúsculas
        .single();
        
    final companyId = companyResponse['id'];

    if (companyId == null) {
      throw 'Empresa não encontrada: ${widget.companyName}';
    }

    final productsResponse = await supabase
        .from('produtos')
        .select()
        .eq('company_id', companyId);

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

          return ListView.builder(
            itemCount: products.length,
            itemBuilder: (context, index) {
              final product = products[index];
              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: ListTile(
                  title: Text(product.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                  trailing: Text('R\$ ${product.price.toStringAsFixed(2)}'),
                ),
              );
            },
          );
        },
      ),
    );
  }
}

class NotFoundScreen extends StatelessWidget {
  const NotFoundScreen({super.key});
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Página não encontrada')),
      body: Center(
        child: ElevatedButton(
          onPressed: () => context.go('/'),
          child: const Text('Voltar para a página inicial'),
        ),
      ),
    );
  }
}