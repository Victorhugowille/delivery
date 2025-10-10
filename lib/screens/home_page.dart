import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/models.dart';
import '../services/theme_service.dart'; // Importe o serviço de tema

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
    themeService.resetToDefault(); // <-- Redefine o tema para o padrão
    _companiesFuture = _fetchCompanies();
  }

  Future<List<Company>> _fetchCompanies() async {
    final response = await Supabase.instance.client.from('companies').select();
    return response.map((item) => Company.fromJson(item)).toList();
  }

  // ... (o método build permanece o mesmo)
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Selecione um Estabelecimento'),
        centerTitle: true,
      ),
      body: FutureBuilder<List<Company>>(
        future: _companiesFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(
                child:
                    Text('Erro ao carregar empresas: ${snapshot.error}'));
          }
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(
                child: Text('Nenhum estabelecimento encontrado.'));
          }

          final companies = snapshot.data!;

          return ListView.builder(
            padding: const EdgeInsets.all(16.0),
            itemCount: companies.length,
            itemBuilder: (context, index) {
              final company = companies[index];
              return Card(
                elevation: 4.0,
                margin: const EdgeInsets.symmetric(vertical: 8.0),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12.0),
                ),
                child: ListTile(
                  contentPadding: const EdgeInsets.all(16.0),
                  title: Text(
                    company.name,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                    ),
                  ),
                  trailing: const Icon(Icons.keyboard_arrow_right),
                  onTap: () {
                    context.go('/${company.slug}');
                  },
                ),
              );
            },
          );
        },
      ),
    );
  }
}