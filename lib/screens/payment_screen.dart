import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:geolocator/geolocator.dart';
import 'package:go_router/go_router.dart';
import 'package:latlong2/latlong.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/models.dart' as model; // Importa os modelos
import '../services/cart_service.dart'; // Importa o cartService

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
  bool _isSubmitting = false; 
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

    if (_deliveryFee == 0 && _deliveryZoneName == "Fora da área de entrega") {
       ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Seu endereço está fora da nossa área de entrega.'),
        backgroundColor: Colors.red,
      ));
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      final cartItemsData = cartService.cartNotifier.value.map((item) {
        return {
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
      if (mounted) setState(() => _isSubmitting = false);
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
      appBar: AppBar(
        title: const Text('Pagamento'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            if (context.canPop()) {
              context.pop();
            }
          },
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // --- Detalhes da Entrega ---
                  _buildSectionTitle(
                    context,
                    icon: Icons.person_pin_circle_outlined,
                    title: 'Detalhes da Entrega',
                  ),
                  Card(
                    elevation: 1,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                      side: BorderSide(color: Colors.grey.shade300)
                    ),
                    child: Column(
                      children: [
                        ListTile(
                          leading: Icon(Icons.person_outline, color: Theme.of(context).primaryColor),
                          title: Text(widget.clientData['name'] ?? 'Nome não informado'),
                          subtitle: Text(widget.clientData['phone'] ?? 'Telefone não informado'),
                        ),
                        const Divider(height: 1, indent: 16, endIndent: 16),
                        ListTile(
                          leading: Icon(Icons.location_on_outlined, color: Theme.of(context).primaryColor),
                          title: Text("${widget.clientData['address_street'] ?? ''}, ${widget.clientData['address_number'] ?? 'S/N'}"),
                          subtitle: Text("${widget.clientData['address_neighborhood'] ?? ''}, ${widget.clientData['address_city'] ?? ''}"),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  // --- Itens do Pedido ---
                  _buildSectionTitle(
                    context,
                    icon: Icons.receipt_long_outlined,
                    title: 'Itens do Pedido',
                  ),
                  Card(
                    elevation: 1,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                      side: BorderSide(color: Colors.grey.shade300)
                    ),
                    child: ListView.separated(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: cartService.cartNotifier.value.length,
                      itemBuilder: (context, index) {
                        final item = cartService.cartNotifier.value[index];
                        return _buildCartItemRow(item);
                      },
                      separatorBuilder: (context, index) => const Divider(height: 1, indent: 16, endIndent: 16),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // --- Resumo do Pedido ---
                   _buildSectionTitle(
                    context,
                    icon: Icons.calculate_outlined,
                    title: 'Resumo do Pedido',
                  ),
                  Card(
                    elevation: 1,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                      side: BorderSide(color: Colors.grey.shade300)
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        children: [
                          _buildSummaryRow('Subtotal dos Itens:',
                              'R\$ ${subtotal.toStringAsFixed(2)}'),
                          const SizedBox(height: 8),
                          _buildSummaryRow(
                              'Taxa ($_deliveryZoneName):', 'R\$ ${_deliveryFee.toStringAsFixed(2)}'),
                          const Padding(
                            padding: EdgeInsets.symmetric(vertical: 12.0),
                            child: Divider(height: 1),
                          ),
                          _buildSummaryRow('Total a Pagar:', 'R\$ ${total.toStringAsFixed(2)}',
                              isTotal: true),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // --- Forma de Pagamento ---
                   _buildSectionTitle(
                    context,
                    icon: Icons.payment_outlined,
                    title: 'Forma de Pagamento',
                  ),
                  
                  _buildPaymentOptionTile(
                    icon: Icons.local_atm_outlined,
                    title: 'Dinheiro',
                    value: PaymentMethod.money,
                  ),
                  _buildPaymentOptionTile(
                    icon: Icons.credit_card_outlined,
                    title: 'Cartão (na entrega)',
                    value: PaymentMethod.card,
                  ),
                  _buildPaymentOptionTile(
                    icon: Icons.pix,
                    title: 'PIX (na entrega)',
                    value: PaymentMethod.pix,
                  ),
                  
                  // --- Seção de Troco ---
                  AnimatedSize(
                    duration: const Duration(milliseconds: 300),
                    curve: Curves.easeInOut,
                    child: _selectedPaymentMethod == PaymentMethod.money
                        ? _buildChangeSection(total)
                        : const SizedBox.shrink(),
                  ),
                ],
              ),
            ),
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.all(16.0),
        child: ElevatedButton(
          style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
          ),
          onPressed: _isSubmitting ? null : _placeOrder,
          child: _isSubmitting
              ? const CircularProgressIndicator(color: Colors.white)
              : const Text('Confirmar Pedido', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        ),
      ),
    );
  }

  //
  // =======================================================================
  // NOVO WIDGET ADICIONADO: _buildSectionTitle
  // =======================================================================
  //
  /// Constrói um título de seção padronizado com ícone e linha
  Widget _buildSectionTitle(BuildContext context, {required IconData icon, required String title}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0, top: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Icon(icon, color: Theme.of(context).primaryColor, size: 28),
          const SizedBox(width: 8),
          Text(
            title,
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(width: 8),
          // Linha que preenche o espaço restante
          const Expanded(
            child: Divider(
              height: 2,
              thickness: 1,
              color: Colors.black12,
            ),
          ),
        ],
      ),
    );
  }
  // =======================================================================
  // FIM DO NOVO WIDGET
  // =======================================================================
  //

  /// Constrói uma linha para cada item do carrinho
  Widget _buildCartItemRow(model.CartItem item) {
    // Formata a lista de adicionais
    final adicionaisText = item.selectedAdicionais
        .map((ad) => '+ ${ad.adicional.name} (R\$ ${ad.adicional.price.toStringAsFixed(2)})') 
        .join('\n');

    return ListTile(
      title: Text(
        '${item.quantity}x ${item.product.name}',
        style: const TextStyle(fontWeight: FontWeight.bold),
      ),
      trailing: Text(
        'R\$ ${item.totalPrice.toStringAsFixed(2)}',
        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
      ),
      subtitle: adicionaisText.isNotEmpty
          ? Padding(
              padding: const EdgeInsets.only(top: 4.0),
              child: Text(
                adicionaisText,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey.shade700,
                  fontStyle: FontStyle.italic,
                  height: 1.4
                ),
              ),
            )
          : null,
      isThreeLine: adicionaisText.isNotEmpty,
      contentPadding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
    );
  }

  Widget _buildSummaryRow(String title, String value, {bool isTotal = false}) {
    final style = isTotal
        ? Theme.of(context)
            .textTheme
            .titleLarge
            ?.copyWith(fontWeight: FontWeight.bold, color: Theme.of(context).primaryColor)
        : Theme.of(context).textTheme.titleMedium?.copyWith(color: Colors.grey.shade700);
    
    final valueStyle = isTotal
        ? Theme.of(context)
            .textTheme
            .titleLarge
            ?.copyWith(fontWeight: FontWeight.bold, color: Theme.of(context).primaryColor)
        : Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold);

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(title, style: style),
        Text(value, style: valueStyle),
      ],
    );
  }

  Widget _buildPaymentOptionTile({
    required IconData icon,
    required String title,
    required PaymentMethod value,
  }) {
    final bool isSelected = _selectedPaymentMethod == value;
    final Color? primaryColor = isSelected ? Theme.of(context).primaryColor : null;
    final Color borderColor = isSelected ? primaryColor! : Colors.grey.shade300;

    return Card(
      elevation: isSelected ? 1 : 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: borderColor, width: isSelected ? 2 : 1),
      ),
      margin: const EdgeInsets.symmetric(vertical: 6.0),
      child: InkWell(
        onTap: () => setState(() => _selectedPaymentMethod = value),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            children: [
              Icon(icon, color: primaryColor ?? Colors.grey.shade700, size: 28),
              const SizedBox(width: 16),
              Text(title, style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                color: primaryColor ?? Colors.black87,
              )),
              if (isSelected) ...[
                const Spacer(),
                Icon(Icons.check_circle, color: primaryColor),
              ]
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildChangeSection(double total) {
    return Container(
      padding: const EdgeInsets.only(top: 16.0),
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
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Theme.of(context).primaryColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                   Icon(Icons.change_circle_outlined, color: Theme.of(context).primaryColor),
                   const SizedBox(width: 8),
                   Text(
                    'Seu troco será de R\$ ${_changeAmount.toStringAsFixed(2)}',
                    style: Theme.of(context)
                        .textTheme
                        .titleMedium
                        ?.copyWith(color: Theme.of(context).primaryColorDark, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            )
        ],
      ),
    );
  }
}