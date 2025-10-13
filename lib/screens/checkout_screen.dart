import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../services/cart_service.dart';

class CheckoutScreen extends StatefulWidget {
  final String companyName;
  const CheckoutScreen({super.key, required this.companyName});

  @override
  State<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends State<CheckoutScreen> {
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;
  bool _isMapLoading = true;
  String? _locationLink;
  Timer? _debounce;

  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _complementController = TextEditingController();

  // Controladores para os campos de endereço que agora são visíveis
  final _streetController = TextEditingController();
  final _numberController = TextEditingController();
  final _neighborhoodController = TextEditingController();
  final _cityController = TextEditingController();

  final MapController _mapController = MapController();
  LatLng? _mapCenter;

  @override
  void initState() {
    super.initState();
    _determinePositionAndLoadMap();
  }

  Future<void> _determinePositionAndLoadMap() async {
    try {
      Position position = await _getCurrentPosition();
      setState(() {
        _mapCenter = LatLng(position.latitude, position.longitude);
        _isMapLoading = false;
      });
      _getAddressFromLatLng(_mapCenter!);
    } catch (e) {
      setState(() {
        _mapCenter = const LatLng(-25.3857, -54.0825); // Fallback Medianeira
        _isMapLoading = false;
      });
    }
  }

  Future<Position> _getCurrentPosition() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) return Future.error('Serviços de localização desativados.');

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) return Future.error('Permissão negada.');
    }
    if (permission == LocationPermission.deniedForever) return Future.error('Permissão negada permanentemente.');
    
    return await Geolocator.getCurrentPosition();
  }

  Future<void> _getAddressFromLatLng(LatLng position) async {
    setState(() {
      _locationLink = 'https://www.google.com/maps/search/?api=1&query=${position.latitude},${position.longitude}';
    });
    
    final url = Uri.parse(
        'https://nominatim.openstreetmap.org/reverse?format=json&lat=${position.latitude}&lon=${position.longitude}');

    try {
      final response = await http.get(url, headers: {
        'User-Agent': 'SeuAppDelivery/1.0 (contato@seusite.com)'
      });

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['address'] != null) {
          final address = data['address'];
          
          // A MUDANÇA PRINCIPAL ESTÁ AQUI:
          // Preenchemos os controladores dos campos de texto em vez de uma variável separada.
          setState(() {
            _streetController.text = address['road'] ?? '';
            _numberController.text = address['house_number'] ?? '';
            _neighborhoodController.text = address['suburb'] ?? '';
            _cityController.text = address['city'] ?? address['town'] ?? '';
          });
        }
      }
    } catch (e) {
      // Handle error
    }
  }

  Future<void> _placeOrder() async {
    if (!_formKey.currentState!.validate()) return;
    
    setState(() => _isLoading = true);

    try {
      // Os dados são lidos diretamente dos controladores,
      // garantindo que qualquer edição manual do usuário seja salva.
      final clientData = {
        'name': _nameController.text,
        'phone': _phoneController.text,
        'address_street': _streetController.text,
        'address_number': _numberController.text,
        'address_neighborhood': _neighborhoodController.text,
        'address_city': _cityController.text,
        'address_complement': _complementController.text,
      };

      final cartItemsData = cartService.cartNotifier.value.map((item) {
        return {
          'productId': item.product.id,
          'quantity': item.quantity,
          'selectedAdicionais': item.selectedAdicionais.map((ad) {
            return {'adicional': {'id': ad.adicional.id, 'name': ad.adicional.name, 'price': ad.adicional.price}, 'quantity': ad.quantity,};
          }).toList(),
        };
      }).toList();

      await Supabase.instance.client.rpc('create_delivery_order', params: {
        'company_slug_param': widget.companyName,
        'client_data': clientData,
        'cart_items': cartItemsData,
        'location_link_param': _locationLink,
      });

      cartService.clearCart();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Pedido realizado com sucesso!'), backgroundColor: Colors.green,));
        context.go('/${widget.companyName}');
      }
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Erro ao finalizar o pedido: ${error.toString()}'), backgroundColor: Colors.red));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _nameController.dispose();
    _phoneController.dispose();
    _complementController.dispose();
    _streetController.dispose();
    _numberController.dispose();
    _neighborhoodController.dispose();
    _cityController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Confirmar Endereço de Entrega')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text('Contato', style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 16),
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(labelText: 'Nome Completo', border: OutlineInputBorder()),
                validator: (value) => (value?.isEmpty ?? true) ? 'Campo obrigatório' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _phoneController,
                decoration: const InputDecoration(labelText: 'Telefone (WhatsApp)', border: OutlineInputBorder()),
                keyboardType: TextInputType.phone,
                validator: (value) => (value?.isEmpty ?? true) ? 'Campo obrigatório' : null,
              ),
              const SizedBox(height: 24),
              Text('Endereço de Entrega', style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 16),
              // O MAPA AGORA É MENOR
              SizedBox(
                height: 200,
                child: _isMapLoading
                    ? const Center(child: CircularProgressIndicator())
                    : Stack(
                        children: [
                          FlutterMap(
                            mapController: _mapController,
                            options: MapOptions(
                              initialCenter: _mapCenter!,
                              initialZoom: 17.0,
                              onPositionChanged: (position, hasGesture) {
                                if (_debounce?.isActive ?? false) _debounce!.cancel();
                                _debounce = Timer(const Duration(milliseconds: 500), () {
                                  if (position.center != null) {
                                     _getAddressFromLatLng(position.center!);
                                  }
                                });
                              },
                            ),
                            children: [
                              TileLayer(
                                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                                userAgentPackageName: 'com.example.app',
                              ),
                            ],
                          ),
                          const Center(
                            child: Icon(Icons.location_pin, size: 50, color: Colors.red),
                          ),
                        ],
                      ),
              ),
              const SizedBox(height: 16),
              
              // CAMPOS DE ENDEREÇO ESTÃO DE VOLTA
              TextFormField(
                controller: _streetController,
                decoration: const InputDecoration(labelText: 'Rua / Avenida', border: OutlineInputBorder()),
                validator: (value) => (value?.isEmpty ?? true) ? 'Campo obrigatório' : null,
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _numberController,
                      decoration: const InputDecoration(labelText: 'Número', border: OutlineInputBorder()),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextFormField(
                      controller: _neighborhoodController,
                      decoration: const InputDecoration(labelText: 'Bairro', border: OutlineInputBorder()),
                       validator: (value) => (value?.isEmpty ?? true) ? 'Campo obrigatório' : null,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _cityController,
                decoration: const InputDecoration(labelText: 'Cidade', border: OutlineInputBorder()),
                 validator: (value) => (value?.isEmpty ?? true) ? 'Campo obrigatório' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _complementController,
                decoration: const InputDecoration(labelText: 'Complemento (Apto, casa, etc.)', border: OutlineInputBorder()),
              ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.all(16.0),
        child: ElevatedButton(
          style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 8)),
          onPressed: _isLoading ? null : _placeOrder,
          child: _isLoading ? const CircularProgressIndicator(color: Colors.white) : const Text('Finalizar Pedido', style: TextStyle(fontSize: 18)),
        ),
      ),
    );
  }
}