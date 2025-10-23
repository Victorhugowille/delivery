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
  final String clientName; 
  final String clientPhone; 

  const CheckoutScreen({
    super.key,
    required this.companyName,
    required this.clientName, 
    required this.clientPhone, 
  });

  @override
  State<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends State<CheckoutScreen> {
  final _formKeyAddress = GlobalKey<FormState>(); 

  bool _isLoading = false;
  bool _isMapLoading = true;
  bool _isSearchingAddress = false;
  String? _locationLink;

  Timer? _mapDebounce;
  Timer? _searchDebounce;

  final _complementController = TextEditingController();
  final _streetController = TextEditingController();
  final _numberController = TextEditingController();
  final _neighborhoodController = TextEditingController();
  final _cityController = TextEditingController();

  final MapController _mapController = MapController();
  LatLng? _mapCenter;

  List<dynamic> _addressSuggestions = [];

  @override
  void initState() {
    super.initState();
    _streetController.addListener(_onAddressChanged);
    _cityController.addListener(_onAddressChanged);
    _determinePositionAndLoadMap();
  }

  // --- Funções de Localização e Mapa ---

  Future<void> _determinePositionAndLoadMap() async {
    try {
      Position position = await _getCurrentPosition();
      if (!mounted) return;
      setState(() {
        _mapCenter = LatLng(position.latitude, position.longitude);
        _isMapLoading = false;
      });
      // A primeira chamada já define um _locationLink inicial
      _getAddressFromLatLng(_mapCenter!, isInitializing: true);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _mapCenter = const LatLng(-25.3857, -54.0825); // Fallback padrão
        _isMapLoading = false;
      });
      // Garante que o locationLink não seja nulo mesmo no fallback
      _updateLocationLink(_mapCenter!);
    }
  }

  Future<Position> _getCurrentPosition() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      return Future.error('Serviços de localização desativados.');
    }

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        return Future.error('Permissão negada.');
      }
    }
    if (permission == LocationPermission.deniedForever) {
      return Future.error('Permissão negada permanentemente.');
    }

    return await Geolocator.getCurrentPosition();
  }

  // --- Funções de Geocodificação (Endereço <-> Coordenadas) ---

  void _onAddressChanged() {
    if (_searchDebounce?.isActive ?? false) _searchDebounce!.cancel();
    _searchDebounce = Timer(const Duration(milliseconds: 750), _searchAddress);
  }

  Future<void> _searchAddress() async {
    final query =
        '${_streetController.text}, ${_numberController.text}, ${_cityController.text}';
    if (query.trim().length < 5) {
      setState(() {
        _addressSuggestions = [];
      });
      return;
    }

    setState(() {
      _isSearchingAddress = true;
    });

    final url = Uri.parse(
        'https://nominatim.openstreetmap.org/search?q=${Uri.encodeComponent(query)}&format=json&addressdetails=1&limit=5&countrycodes=br');

    try {
      final response = await http
          .get(url, headers: {'User-Agent': 'SeuAppDelivery/1.0'});

      if (response.statusCode == 200) {
        final data = json.decode(response.body) as List;
        setState(() {
          _addressSuggestions = data;
        });
      }
    } catch (e) {
      // Handle error
    } finally {
      if (mounted) {
        setState(() {
          _isSearchingAddress = false;
        });
      }
    }
  }

  void _onSuggestionSelected(dynamic suggestion) {
    final dynamic latData = suggestion['lat'];
    final dynamic lonData = suggestion['lon'];
    final dynamic addressData = suggestion['address'];

    if (latData == null || lonData == null || addressData == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Erro ao selecionar endereço. Tente novamente.')),
      );
      return; 
    }

    final double? lat = double.tryParse(latData.toString());
    final double? lon = double.tryParse(lonData.toString());
    
    if (lat == null || lon == null || addressData is! Map) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Dados de endereço inválidos.')),
      );
      return; 
    }
    
    final address = addressData as Map; 

    _removeAddressListeners();

    final String currentNumber = _numberController.text;
    final String currentNeighborhood = _neighborhoodController.text;

    setState(() {
      _mapCenter = LatLng(lat, lon); 

      _streetController.text = (address['road'] as String?) ?? _streetController.text;
      _numberController.text = (address['house_number'] as String?) ?? currentNumber;
      _neighborhoodController.text = (address['suburb'] as String?) ?? currentNeighborhood;
      _cityController.text = ((address['city'] as String?) ?? (address['town'] as String?)) ?? _cityController.text;

      _addressSuggestions = []; 
      _updateLocationLink(_mapCenter!); 
    });

    _mapController.move(_mapCenter!, 17.0);
    _addAddressListeners();
  }

  Future<void> _getAddressFromLatLng(LatLng position, {bool isInitializing = false}) async {
    _updateLocationLink(position); // Atualiza o link

    final url = Uri.parse(
        'https://nominatim.openstreetmap.org/reverse?format=json&lat=${position.latitude}&lon=${position.longitude}');

    try {
      final response = await http
          .get(url, headers: {'User-Agent': 'SeuAppDelivery/1.0'});

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['address'] != null && !isInitializing) { 
          final address = data['address'];

          _removeAddressListeners();

          setState(() {
            if (address['road'] != null) {
              _streetController.text = address['road'];
            }
            if (address['house_number'] != null) {
              _numberController.text = address['house_number'];
            }
            if (address['suburb'] != null) {
              _neighborhoodController.text = address['suburb'];
            }
            if (address['city'] != null || address['town'] != null) {
              _cityController.text = address['city'] ?? address['town'] ?? '';
            }
          });

          _addAddressListeners();
        }
      }
    } catch (e) {
      // Handle error
    }
  }

  //
  // =======================================================================
  // CORREÇÃO 1: Sintaxe da URL
  // =======================================================================
  //
  void _updateLocationLink(LatLng position) {
     setState(() {
      // A sintaxe correta é ${expressão}
      _locationLink =
          'https://www.google.com/maps/search/?api=1&query=${position.latitude},${position.longitude}';
    });
  }
  // =======================================================================
  // FIM DA CORREÇÃO 1
  // =======================================================================
  //

  // --- Funções de Navegação e Submissão ---

  void _goToPayment() {
    if (!_formKeyAddress.currentState!.validate()) return;
    if (_mapCenter == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Localização no mapa não encontrada.')),
      );
      return;
    }

    //
    // =======================================================================
    // CORREÇÃO 2: Sintaxe da URL (no fallback)
    // =======================================================================
    //
    final String locationLink = _locationLink ?? 
         'https://www.google.com/maps/search/?api=1&query=${_mapCenter!.latitude},${_mapCenter!.longitude}';
    // =======================================================================
    // FIM DA CORREÇÃO 2
    // =======================================================================
    //

    final clientData = {
      'name': widget.clientName, 
      'phone': widget.clientPhone,
      'address_street': _streetController.text,
      'address_number': _numberController.text,
      'address_neighborhood': _neighborhoodController.text,
      'address_city': _cityController.text,
      'address_complement': _complementController.text,
    };

    context.go(
      '/${widget.companyName}/payment',
      extra: {
        'clientData': clientData,
        'locationLink': locationLink, // Passando a versão segura (não nula)
        'clientLocation': _mapCenter,
      },
    );
  }

  // --- Funções Auxiliares (Listeners e Dispose) ---

  void _removeAddressListeners() {
    _streetController.removeListener(_onAddressChanged);
    _cityController.removeListener(_onAddressChanged);
  }

  void _addAddressListeners() {
    _streetController.addListener(_onAddressChanged);
    _cityController.addListener(_onAddressChanged);
  }

  @override
  void dispose() {
    _mapDebounce?.cancel();
    _searchDebounce?.cancel();
    _removeAddressListeners();
    _complementController.dispose();
    _streetController.dispose();
    _numberController.dispose();
    _neighborhoodController.dispose();
    _cityController.dispose();
    super.dispose();
  }

  // --- Widgets de Build ---

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Confirmar Endereço de Entrega')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKeyAddress,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text('Endereço de Entrega',
                  style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 16),

              // Campos de Endereço (Rua, Número, Bairro, Cidade)
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

              // Lista de Sugestões de Endereço
              if (_isSearchingAddress)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 8.0),
                  child: Center(child: CircularProgressIndicator()),
                )
              else if (_addressSuggestions.isNotEmpty)
                _buildSuggestionsList(),

              const SizedBox(height: 16),
              
              Container(
                padding: const EdgeInsets.all(12.0),
                decoration: BoxDecoration(
                  color: Theme.of(context).primaryColor.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(8.0),
                  border: Border.all(
                      color: Theme.of(context).primaryColor.withOpacity(0.3)),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(Icons.touch_app_outlined,
                        color: Theme.of(context).primaryColor, size: 32),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Ajuste o pino no mapa!',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Theme.of(context).primaryColorDark,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Arraste o mapa para centralizar o pino na localização exata da sua casa.',
                            style: TextStyle(
                              fontSize: 14,
                              color: Theme.of(context).textTheme.bodyMedium?.color,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              
              // Mapa
              AspectRatio( 
                aspectRatio: 1.0,
                child: _isMapLoading
                    ? const Center(child: CircularProgressIndicator())
                    : ClipRRect( 
                        borderRadius: BorderRadius.circular(12.0),
                        child: Stack(
                          children: [
                            FlutterMap(
                              mapController: _mapController,
                              options: MapOptions(
                                initialCenter: _mapCenter!,
                                initialZoom: 17.0,
                                onPositionChanged: (position, hasGesture) {
                                  if (_mapDebounce?.isActive ?? false) {
                                    _mapDebounce!.cancel();
                                  }
                                  _mapDebounce = Timer(
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
              ),
              const SizedBox(height: 16),

              // Complemento
              TextFormField(
                controller: _complementController,
                decoration: const InputDecoration(
                    labelText: 'Complemento (Apto, casa, ponto de referência)',
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

  Widget _buildSuggestionsList() {
    return Container(
      height: 150,
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        border: Border.all(color: Colors.grey.shade300),
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 5,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ListView.builder(
        itemCount: _addressSuggestions.length,
        itemBuilder: (context, index) {
          final suggestion = _addressSuggestions[index];
          final displayName = (suggestion['display_name'] as String?) ?? 'Endereço inválido';

          return ListTile(
            title: Text(displayName, style: const TextStyle(fontSize: 14)),
            dense: true,
            onTap: () {
              _onSuggestionSelected(suggestion);
            },
          );
        },
      ),
    );
  }
}