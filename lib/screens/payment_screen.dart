import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:geolocator/geolocator.dart';
import 'package:go_router/go_router.dart';
import 'package:latlong2/latlong.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/models.dart' as model;
import '../services/cart_service.dart';

class PaymentScreen extends StatefulWidget {
  final String companyName;
  final Map<String, dynamic> clientData;
  final String locationLink;
  final LatLng clientLocation;

  const PaymentScreen({
    super.key,
    required this.companyName,
    required this.clientData,
    required this.locationLink,
    required this.clientLocation,
  });

  @override
  State<PaymentScreen> createState() => _PaymentScreenState();
}

enum PaymentMethod { money, card, pix }

class _PaymentScreenState extends State<PaymentScreen> {
  bool _isLoading = true;
  double _deliveryFee = 0.0;
  String _deliveryZoneName = "Calculando...";
  PaymentMethod? _selectedPaymentMethod;
  final _changeForController = TextEditingController();
  double _changeAmount = 0.0;

  @override
  void initState() {
    super.initState();
    _calculateDeliveryFee();
    _changeForController.addListener(_calculateChange);
  }

  Future<void> _calculateDeliveryFee() async {
    try {
      final companyRes = await Supabase.instance.client
          .from('companies')
          .select('id, latitude, longitude')
          .eq('slug', widget.companyName)
          .single();

      final companyId = companyRes['id'] as String?;
      final companyLat = (companyRes['latitude'] as num?)?.toDouble();
      final companyLon = (companyRes['longitude'] as num?)?.toDouble();

      if (companyId == null) {
        throw Exception('Empresa não encontrada.');
      }
      if (companyLat == null || companyLon == null) {
        throw Exception('Localização da empresa não configurada.');
      }

      final zonesRes = await Supabase.instance.client
          .from('delivery_zones')
          .select()
          .eq('company_id', companyId)
          .order('radius_meters', ascending: true);

      final zones =
          zonesRes.map((data) => model.DeliveryZone.fromJson(data)).toList();

      if (zones.isEmpty) {
        throw Exception('Nenhuma zona de entrega configurada para esta empresa.');
      }
      
      final distanceInMeters = Geolocator.distanceBetween(
        companyLat,
        companyLon,
        widget.clientLocation.latitude,
        widget.clientLocation.longitude,
      );

      model.DeliveryZone? selectedZone;
      for (final zone in zones) {
        if (distanceInMeters <= zone.radiusMeters) {
          selectedZone = zone;
          break;
        }
      }

      if (selectedZone != null) {
        setState(() {
          _deliveryFee = selectedZone!.fee;
          _deliveryZoneName = selectedZone.name;
        });
      } else {
        setState(() {
          _deliveryFee = 0;
          _deliveryZoneName = "Fora da área de entrega";
        });
      }
    } catch (e) {
      debugPrint("Erro ao calcular taxa: $e");
      setState(() {
         _deliveryFee = 0;
         _deliveryZoneName = "Erro ao calcular";
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _calculateChange() {
    final total = cartService.totalCartPrice + _deliveryFee;
    final changeFor = double.tryParse(_changeForController.text.replaceAll(',', '.')) ?? 0;
    setState(() {
      _changeAmount = (changeFor > total) ? changeFor - total : 0.0;
    });
  }
  
  Future<void> _placeOrder() async {
    if (_selectedPaymentMethod == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Por favor, selecione uma forma de pagamento.'),
        backgroundColor: Colors.orange,
      ));
      return;
    }

    setState(() => _isLoading = true);

    try {
      final cartItemsData = cartService.cartNotifier.value.map((item) {
        return {
          // CORREÇÃO DA CHAVE JSON PARA GARANTIR CONSISTÊNCIA
          'product_id': item.product.id, 
          'quantidade': item.quantity,
          'observacao': item.observacao,
          'adicionais_selecionados': item.selectedAdicionais.map((ad) {
            return {
              'adicional': {
                'id': ad.adicional.id,
                'name': ad.adicional.name,
                'price': ad.adicional.price
              },
              'quantity': ad.quantity,
            };
          }).toList(),
        };
      }).toList();
      
      String? trocoObservacao;
      if (_selectedPaymentMethod == PaymentMethod.money && (double.tryParse(_changeForController.text.replaceAll(',', '.')) ?? 0) > 0) {
        trocoObservacao = "Troco para R\$ ${_changeForController.text}";
      }

      final paymentInfo = {
        'method': _selectedPaymentMethod.toString().split('.').last, // 'money', 'card', 'pix'
        'change_for': trocoObservacao
      };
      
      await Supabase.instance.client.rpc('create_delivery_order', params: {
        'company_slug_param': widget.companyName,
        'client_data': widget.clientData,
        'cart_items': cartItemsData,
        'location_link_param': widget.locationLink,
        'payment_data': paymentInfo, 
        'delivery_fee_param': _deliveryFee 
      });

      cartService.clearCart();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Pedido realizado com sucesso!'),
          backgroundColor: Colors.green,
        ));
        context.go('/${widget.companyName}');
      }
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Erro ao finalizar o pedido: ${error.toString()}'),
          backgroundColor: Colors.red,
        ));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  void dispose() {
    _changeForController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final subtotal = cartService.totalCartPrice;
    final total = subtotal + _deliveryFee;

    return Scaffold(
      appBar: AppBar(title: const Text('Pagamento')),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Resumo do Pedido',
                      style: Theme.of(context).textTheme.headlineSmall),
                  const Divider(height: 24),
                  _buildSummaryRow('Subtotal dos Itens:',
                      'R\$ ${subtotal.toStringAsFixed(2)}'),
                  const SizedBox(height: 8),
                  _buildSummaryRow(
                      'Taxa de Entrega ($_deliveryZoneName):', 'R\$ ${_deliveryFee.toStringAsFixed(2)}'),
                  const Divider(height: 24),
                  _buildSummaryRow('Total a Pagar:', 'R\$ ${total.toStringAsFixed(2)}',
                      isTotal: true),
                  const SizedBox(height: 32),
                  Text('Forma de Pagamento',
                      style: Theme.of(context).textTheme.headlineSmall),
                  const Divider(height: 24),
                  _buildPaymentOptions(),
                  if (_selectedPaymentMethod == PaymentMethod.money)
                    _buildChangeSection(total),
                ],
              ),
            ),
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.all(16.0),
        child: ElevatedButton(
          style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16)),
          onPressed: _isLoading ? null : _placeOrder,
          child: _isLoading
              ? const CircularProgressIndicator(color: Colors.white)
              : const Text('Confirmar Pedido', style: TextStyle(fontSize: 18)),
        ),
      ),
    );
  }

  Widget _buildSummaryRow(String title, String value, {bool isTotal = false}) {
    final style = isTotal
        ? Theme.of(context)
            .textTheme
            .titleLarge
            ?.copyWith(fontWeight: FontWeight.bold)
        : Theme.of(context).textTheme.titleMedium;
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(title, style: style),
        Text(value, style: style),
      ],
    );
  }

  Widget _buildPaymentOptions() {
    return Column(
      children: [
        RadioListTile<PaymentMethod>(
          title: const Text('Dinheiro'),
          value: PaymentMethod.money,
          groupValue: _selectedPaymentMethod,
          onChanged: (value) => setState(() => _selectedPaymentMethod = value),
        ),
        RadioListTile<PaymentMethod>(
          title: const Text('Cartão (Maquininha)'),
          value: PaymentMethod.card,
          groupValue: _selectedPaymentMethod,
          onChanged: (value) => setState(() => _selectedPaymentMethod = value),
        ),
        RadioListTile<PaymentMethod>(
          title: const Text('PIX'),
          value: PaymentMethod.pix,
          groupValue: _selectedPaymentMethod,
          onChanged: (value) => setState(() => _selectedPaymentMethod = value),
        ),
      ],
    );
  }

  Widget _buildChangeSection(double total) {
    return Padding(
      padding: const EdgeInsets.only(top: 24.0, left: 16, right: 16),
      child: Column(
        children: [
          TextFormField(
            controller: _changeForController,
            decoration: const InputDecoration(
              labelText: 'Precisa de troco para quanto?',
              prefixText: 'R\$ ',
              border: OutlineInputBorder(),
            ),
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            inputFormatters: [
              FilteringTextInputFormatter.allow(RegExp(r'^\d+[,.]?\d{0,2}')),
            ],
          ),
          const SizedBox(height: 16),
          if (_changeAmount > 0)
            Text(
              'Seu troco será de R\$ ${_changeAmount.toStringAsFixed(2)}',
              style: Theme.of(context)
                  .textTheme
                  .titleMedium
                  ?.copyWith(color: Theme.of(context).primaryColor, fontWeight: FontWeight.bold),
            )
        ],
      ),
    );
  }
}