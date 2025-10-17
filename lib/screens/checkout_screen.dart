import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

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
        _mapCenter = const LatLng(-25.3857, -54.0825); // Fallback
        _isMapLoading = false;
      });
    }
  }

  Future<Position> _getCurrentPosition() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled)
      return Future.error('Serviços de localização desativados.');

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied)
        return Future.error('Permissão negada.');
    }
    if (permission == LocationPermission.deniedForever)
      return Future.error('Permissão negada permanentemente.');

    return await Geolocator.getCurrentPosition();
  }

  Future<void> _getAddressFromLatLng(LatLng position) async {
    setState(() {
      _locationLink =
          'https://www.google.com/maps?q=${position.latitude},${position.longitude}';
    });

    final url = Uri.parse(
        'https://nominatim.openstreetmap.org/reverse?format=json&lat=${position.latitude}&lon=${position.longitude}');

    try {
      final response = await http
          .get(url, headers: {'User-Agent': 'SeuAppDelivery/1.0'});

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['address'] != null) {
          final address = data['address'];
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

  // MUDANÇA AQUI: Esta função agora navega para a tela de pagamento
  void _goToPayment() {
    if (!_formKey.currentState!.validate()) return;
    if (_mapCenter == null) return;

    final clientData = {
      'name': _nameController.text,
      'phone': _phoneController.text,
      'address_street': _streetController.text,
      'address_number': _numberController.text,
      'address_neighborhood': _neighborhoodController.text,
      'address_city': _cityController.text,
      'address_complement': _complementController.text,
    };
    
    // Navega para a nova tela de pagamento, passando os dados
    context.go(
      '/${widget.companyName}/payment',
      extra: {
        'clientData': clientData,
        'locationLink': _locationLink,
        'clientLocation': _mapCenter,
      },
    );
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
                decoration: const InputDecoration(
                    labelText: 'Nome Completo', border: OutlineInputBorder()),
                validator: (value) =>
                    (value?.isEmpty ?? true) ? 'Campo obrigatório' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _phoneController,
                decoration: const InputDecoration(
                    labelText: 'Telefone (WhatsApp)',
                    border: OutlineInputBorder()),
                keyboardType: TextInputType.phone,
                validator: (value) =>
                    (value?.isEmpty ?? true) ? 'Campo obrigatório' : null,
              ),
              const SizedBox(height: 24),
              Text('Endereço de Entrega',
                  style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 16),
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
                                if (_debounce?.isActive ?? false)
                                  _debounce!.cancel();
                                _debounce = Timer(
                                    const Duration(milliseconds: 500), () {
                                  if (position.center != null) {
                                    setState(() {
                                      _mapCenter = position.center!;
                                    });
                                    _getAddressFromLatLng(position.center!);
                                  }
                                });
                              },
                            ),
                            children: [
                              TileLayer(
                                urlTemplate:
                                    'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                                userAgentPackageName: 'com.example.app',
                              ),
                            ],
                          ),
                          const Center(
                            child: Icon(Icons.location_pin,
                                size: 50, color: Colors.red),
                          ),
                        ],
                      ),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _streetController,
                decoration: const InputDecoration(
                    labelText: 'Rua / Avenida', border: OutlineInputBorder()),
                validator: (value) =>
                    (value?.isEmpty ?? true) ? 'Campo obrigatório' : null,
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _numberController,
                      decoration: const InputDecoration(
                          labelText: 'Número', border: OutlineInputBorder()),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextFormField(
                      controller: _neighborhoodController,
                      decoration: const InputDecoration(
                          labelText: 'Bairro', border: OutlineInputBorder()),
                      validator: (value) =>
                          (value?.isEmpty ?? true) ? 'Campo obrigatório' : null,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _cityController,
                decoration: const InputDecoration(
                    labelText: 'Cidade', border: OutlineInputBorder()),
                validator: (value) =>
                    (value?.isEmpty ?? true) ? 'Campo obrigatório' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _complementController,
                decoration: const InputDecoration(
                    labelText: 'Complemento (Apto, casa, etc.)',
                    border: OutlineInputBorder()),
              ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.all(16.0),
        child: ElevatedButton(
          style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16)),
          onPressed: _isLoading ? null : _goToPayment,
          child: _isLoading
              ? const CircularProgressIndicator(color: Colors.white)
              : const Text('Ir para Pagamento', style: TextStyle(fontSize: 18)),
        ),
      ),
    );
  }
}