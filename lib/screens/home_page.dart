import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/models.dart';
import '../services/theme_service.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  late final Future<List<Company>> _companiesFuture;

  @override
  void initState() {
    super.initState();
    themeService.resetToDefault();
    _companiesFuture = _fetchCompanies();
  }

  Future<List<Company>> _fetchCompanies() async {
    final response =
        await Supabase.instance.client.from('companies').select();
    return response.map((item) => Company.fromJson(item)).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Theme.of(context).colorScheme.surface,
              Theme.of(context).colorScheme.surface.withOpacity(0.8),
            ],
          ),
        ),
        child: CustomScrollView(
          slivers: [
            SliverAppBar(
              backgroundColor: Colors.transparent,
              elevation: 0,
              centerTitle: true,
              pinned: true,
              expandedHeight: 150.0,
              flexibleSpace: FlexibleSpaceBar(
                centerTitle: true,
                title: Text(
                  'Bem-vindo!',
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.onSurface,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                background: Container(
                  color: Theme.of(context).primaryColor.withOpacity(0.1),
                ),
              ),
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                child: Text(
                  'Selecione um estabelecimento',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
              ),
            ),
            _buildCompaniesGrid(),
          ],
        ),
      ),
    );
  }

  Widget _buildCompaniesGrid() {
    return FutureBuilder<List<Company>>(
      future: _companiesFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const SliverFillRemaining(
            child: Center(child: CircularProgressIndicator()),
          );
        }
        if (snapshot.hasError) {
          return SliverFillRemaining(
            child: Center(
              child: Text('Erro ao carregar empresas: ${snapshot.error}'),
            ),
          );
        }
        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return const SliverFillRemaining(
            child: Center(child: Text('Nenhum estabelecimento encontrado.')),
          );
        }

        final companies = snapshot.data!;
        return SliverPadding(
          padding: const EdgeInsets.all(16.0),
          sliver: SliverGrid(
            gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
              maxCrossAxisExtent: 350,
              mainAxisSpacing: 20,
              crossAxisSpacing: 20,
              childAspectRatio: 16 / 9,
            ),
            delegate: SliverChildBuilderDelegate(
              (context, index) {
                final company = companies[index];
                return CompanyCard(company: company);
              },
              childCount: companies.length,
            ),
          ),
        );
      },
    );
  }
}

class CompanyCard extends StatelessWidget {
  const CompanyCard({super.key, required this.company});

  final Company company;

  @override
  Widget build(BuildContext context) {
    return Card(
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15.0)),
      elevation: 5.0,
      shadowColor: Colors.black38,
      child: InkWell(
        onTap: () => context.go('/${company.slug}'),
        child: Stack(
          fit: StackFit.expand,
          children: [
            // MUDANÇA AQUI: usando company.logoUrl
            if (company.logoUrl != null && company.logoUrl!.isNotEmpty)
              Image.network(
                company.logoUrl!,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) =>
                    _buildPlaceholder(),
              )
            else
              _buildPlaceholder(),

            DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.bottomCenter,
                  end: Alignment.center,
                  colors: [Colors.black.withOpacity(0.8), Colors.transparent],
                ),
              ),
            ),
            Positioned(
              bottom: 16,
              left: 16,
              right: 16,
              child: Text(
                company.name,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  shadows: [
                    Shadow(blurRadius: 2.0, color: Colors.black54),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPlaceholder() {
    return Container(
      color: Colors.grey.shade300,
      child: Icon(
        Icons.storefront,
        size: 60,
        color: Colors.grey.shade600,
      ),
    );
  }
}