import 'package:flutter/material.dart';

// NOVA CLASSE PARA AS ZONAS DE ENTREGA
class DeliveryZone {
  final String id;
  final String name;
  final int radiusMeters;
  final double fee;

  DeliveryZone({
    required this.id,
    required this.name,
    required this.radiusMeters,
    required this.fee,
  });

  factory DeliveryZone.fromJson(Map<String, dynamic> json) {
    return DeliveryZone(
      id: json['id'] ?? '',
      name: json['name'] ?? 'Zona desconhecida',
      radiusMeters: json['radius_meters'] ?? 0,
      fee: (json['fee'] as num?)?.toDouble() ?? 0.0,
    );
  }
}

// ### NOVA CLASSE ADICIONADA AQUI ###
class DestaqueSite {
  final int id;
  final String companyId;
  final String imageUrl;
  final int slotNumber;

  DestaqueSite({
    required this.id,
    required this.companyId,
    required this.imageUrl,
    required this.slotNumber,
  });

  factory DestaqueSite.fromJson(Map<String, dynamic> json) {
    return DestaqueSite(
      id: json['id'],
      companyId: json['company_id'],
      imageUrl: json['image_url'],
      slotNumber: json['slot_number'],
    );
  }
}

class ClienteDelivery {
  final int? id;
  final String name;
  final String phone;
  final String addressStreet;
  final String? addressNumber;
  final String? addressNeighborhood;
  final String? addressCity;
  final String? addressState;
  final String? addressZipCode;
  final String? addressComplement;
  final String? userId;

  ClienteDelivery({
    this.id,
    required this.name,
    required this.phone,
    required this.addressStreet,
    this.addressNumber,
    this.addressNeighborhood,
    this.addressCity,
    this.addressState,
    this.addressZipCode,
    this.addressComplement,
    this.userId,
  });

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'phone': phone,
      'address_street': addressStreet,
      'address_number': addressNumber,
      'address_neighborhood': addressNeighborhood,
      'address_city': addressCity,
      'address_state': addressState,
      'address_zip_code': addressZipCode,
      'address_complement': addressComplement,
      'user_id': userId,
    };
  }
}

class Company {
  final String id;
  final String name;
  final String slug;
  final String? logoUrl; // MUDANÇA: de imageUrl para logoUrl
  final String? colorSite;
  final double? latitude;
  final double? longitude;

  Company({
    required this.id,
    required this.name,
    required this.slug,
    this.logoUrl, // MUDANÇA
    this.colorSite,
    this.latitude,
    this.longitude,
  });

  factory Company.fromJson(Map<String, dynamic> json) {
    return Company(
      id: json['id']?.toString() ?? '',
      name: json['name'] ?? 'Nome Inválido',
      slug: json['slug'] ?? '',
      logoUrl: json['logo_url'], // MUDANÇA: Mapeando do banco de dados
      colorSite: json['color_site'],
      latitude: (json['latitude'] as num?)?.toDouble(),
      longitude: (json['longitude'] as num?)?.toDouble(),
    );
  }
}

// ... O resto do seu arquivo de modelos continua igual ...
// (GrupoAdicional, Adicional, Category, Product, etc.)

class GrupoAdicional {
  final String id;
  final String name;
  final String produtoId;
  final String? imageUrl;
  List<Adicional> adicionais;
  final int displayOrder;
  final int minQuantity;
  final int? maxQuantity;

  GrupoAdicional(
      {required this.id,
      required this.name,
      required this.produtoId,
      this.imageUrl,
      this.adicionais = const [],
      required this.displayOrder,
      required this.minQuantity,
      this.maxQuantity});

  factory GrupoAdicional.fromJson(Map<String, dynamic> json) {
    List<Adicional> items = [];
    if (json['adicionais'] is List) {
      items = (json['adicionais'] as List)
          .map((item) => Adicional.fromJson(item))
          .toList();
      items.sort((a, b) => a.displayOrder.compareTo(b.displayOrder));
    }
    return GrupoAdicional(
        id: json['id']?.toString() ?? '',
        name: json['name'] ?? 'Grupo Inválido',
        produtoId: json['produto_id']?.toString() ?? '',
        imageUrl: json['image_url'],
        adicionais: items,
        displayOrder: json['display_order'] ?? 0,
        minQuantity: json['min_quantity'] ?? 0,
        maxQuantity: json['max_quantity']);
  }
}

class Adicional {
  final String id;
  final String name;
  final double price;
  final String? grupoId;
  final String? imageUrl;
  final int displayOrder;

  Adicional(
      {required this.id,
      required this.name,
      required this.price,
      this.grupoId,
      this.imageUrl,
      required this.displayOrder});

  factory Adicional.fromJson(Map<String, dynamic> json) {
    return Adicional(
        id: json['id']?.toString() ?? '',
        name: json['name'] ?? 'Adicional Inválido',
        price: (json['price'] as num?)?.toDouble() ?? 0.0,
        grupoId: json['grupo_id']?.toString(),
        imageUrl: json['image_url'],
        displayOrder: json['display_order'] ?? 0);
  }
}

class Category {
  final String id;
  final String name;
  final IconData icon;
  final int displayOrder;

  Category(
      {required this.id,
      required this.name,
      required this.icon,
      required this.displayOrder});

  factory Category.fromJson(Map<String, dynamic> jsonData) {
    return Category(
      id: jsonData['id']?.toString() ?? '',
      name: jsonData['name'] ?? 'Categoria Inválida',
      icon: IconData(jsonData['icon_code_point'] ?? 0xe1de,
          fontFamily: jsonData['icon_font_family']),
      displayOrder: jsonData['display_order'] ?? 0,
    );
  }
}

class Product {
  final String id;
  final String name;
  final double price;
  final String? categoryId;
  final String categoryName;
  final int displayOrder;
  final String? imageUrl;
  final bool isSoldOut;

  Product(
      {required this.id,
      required this.name,
      required this.price,
      required this.categoryId,
      required this.categoryName,
      required this.displayOrder,
      this.imageUrl,
      required this.isSoldOut});

  factory Product.fromJson(Map<String, dynamic> jsonData) {
    return Product(
        id: jsonData['id']?.toString() ?? '',
        name: jsonData['name'] ?? 'Produto Inválido',
        price: (jsonData['price'] as num?)?.toDouble() ?? 0.0,
        categoryId: jsonData['category_id']?.toString(),
        categoryName: (jsonData['categorias'] is Map)
            ? jsonData['categorias']['name'] ?? 'Sem Categoria'
            : 'Sem Categoria',
        displayOrder: jsonData['display_order'] ?? 0,
        imageUrl: jsonData['image_url'],
        isSoldOut: jsonData['is_sold_out'] ?? false);
  }
}

class CartItemAdicional {
  final Adicional adicional;
  final int quantity;

  CartItemAdicional({required this.adicional, required this.quantity});

  factory CartItemAdicional.fromJson(Map<String, dynamic> json) {
    return CartItemAdicional(
      adicional: Adicional.fromJson(json['adicional'] ?? {}),
      quantity: json['quantity'] ?? 1,
    );
  }
}

class CartItem {
  final String id;
  final Product product;
  int quantity;
  List<CartItemAdicional> selectedAdicionais;
  String? observacao;

  CartItem({
    required this.id,
    required this.product,
    required this.quantity,
    this.selectedAdicionais = const [],
    this.observacao,
  });

  double get totalPrice {
    final double adicionaisPrice = selectedAdicionais.fold(
        0.0, (sum, item) => sum + (item.adicional.price * item.quantity));
    return (product.price + adicionaisPrice) * quantity;
  }
}

class Delivery {
  final String id;
  final int pedidoId;
  final int clienteId;
  final String? locationLink;
  final String companyId;

  Delivery({
    required this.id,
    required this.pedidoId,
    required this.clienteId,
    this.locationLink,
    required this.companyId,
  });

  factory Delivery.fromJson(Map<String, dynamic> json) {
    return Delivery(
      id: json['id'] ?? '',
      pedidoId: json['pedido_id'] ?? 0,
      clienteId: json['cliente_id'] ?? 0,
      locationLink: json['location_link'],
      companyId: json['company_id'] ?? '',
    );
  }
}

class Order {
  final int id;
  final List<CartItem> items;
  final DateTime timestamp;
  final String status;
  final String type;
  final String? observacao;
  final String? userId;
  final int? mesaId;
  final Delivery? delivery;

  Order({
    required this.id,
    required this.items,
    required this.timestamp,
    required this.status,
    required this.type,
    this.observacao,
    this.userId,
    this.mesaId,
    this.delivery,
  });

  double get total => items.fold(0.0, (sum, item) => sum + item.totalPrice);
}