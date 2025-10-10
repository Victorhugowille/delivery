import 'package:flutter/material.dart';

// NOVA CLASSE ADICIONADA
class Company {
  final String id;
  final String name;
  final String slug;
  final String? imageUrl;
  final String? colorSite; // <-- NOME CORRIGIDO (sem o _)

  Company({
    required this.id,
    required this.name,
    required this.slug,
    this.imageUrl,
    this.colorSite, // <-- NOME CORRIGIDO
  });

  factory Company.fromJson(Map<String, dynamic> json) {
    return Company(
      id: json['id']?.toString() ?? '',
      name: json['name'] ?? 'Nome Inválido',
      slug: json['slug'] ?? '',
      imageUrl: json['image_url'],
      colorSite: json['color_site'], // <-- Lendo o nome da coluna do banco
    );
  }
}

class SavedReport {
  final String id;
  final String name;
  final DateTime createdAt;
  SavedReport({required this.id, required this.name, required this.createdAt});
  factory SavedReport.fromJson(Map<String, dynamic> json) {
    return SavedReport(
        id: json['id']?.toString() ?? '',
        name: json['name'] ?? 'Relatório Inválido',
        createdAt: DateTime.tryParse(json['created_at'] ?? '') ?? DateTime.now());
  }
}

class GrupoAdicional {
  final String id;
  final String name;
  final String produtoId;
  final String? imageUrl;
  List<Adicional> adicionais;
  final int displayOrder;

  GrupoAdicional(
      {required this.id,
      required this.name,
      required this.produtoId,
      this.imageUrl,
      this.adicionais = const [],
      required this.displayOrder});

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
        displayOrder: json['display_order'] ?? 0);
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

class Table {
  final String id;
  final int tableNumber;
  bool isOccupied;
  bool isPartiallyPaid;

  Table({
    required this.id,
    required this.tableNumber,
    required this.isOccupied,
    this.isPartiallyPaid = false,
  });

  factory Table.fromJson(Map<String, dynamic> jsonData) {
    return Table(
      id: jsonData['id']?.toString() ?? '',
      tableNumber: jsonData['numero'] ?? 0,
      isOccupied: jsonData['status'] == 'ocupada',
      isPartiallyPaid: false,
    );
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

  factory CartItem.fromJson(Map<String, dynamic> json) {
    return CartItem(
      id: json['id']?.toString() ?? '',
      product: Product.fromJson(json['produtos'] ?? {}),
      quantity: json['quantidade'] ?? 0,
      selectedAdicionais: (json['adicionais_selecionados'] as List? ?? [])
          .map((item) => CartItemAdicional.fromJson(item))
          .toList(),
      observacao: json['observacao'],
    );
  }

  CartItem copyWith({
    String? id,
    Product? product,
    int? quantity,
    List<CartItemAdicional>? selectedAdicionais,
    String? observacao,
  }) {
    return CartItem(
      id: id ?? this.id,
      product: product ?? this.product,
      quantity: quantity ?? this.quantity,
      selectedAdicionais: selectedAdicionais ?? this.selectedAdicionais,
      observacao: observacao ?? this.observacao,
    );
  }
}

class DeliveryInfo {
  final String id;
  final int pedidoId;
  final String nomeCliente;
  final String telefoneCliente;
  final String enderecoEntrega;

  DeliveryInfo({
    required this.id,
    required this.pedidoId,
    required this.nomeCliente,
    required this.telefoneCliente,
    required this.enderecoEntrega,
  });

  factory DeliveryInfo.fromJson(Map<String, dynamic> json) {
    return DeliveryInfo(
      id: json['id']?.toString() ?? '',
      pedidoId: json['pedido_id'] ?? 0,
      nomeCliente: json['nome_cliente'] ?? '',
      telefoneCliente: json['telefone_cliente'] ?? '',
      enderecoEntrega: json['endereco_entrega'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'pedido_id': pedidoId,
      'nome_cliente': nomeCliente,
      'telefone_cliente': telefoneCliente,
      'endereco_entrega': enderecoEntrega,
    };
  }
}

class Order {
  final int id;
  final List<CartItem> items;
  final DateTime timestamp;
  final String status;
  final String type;
  final int? tableNumber;
  final String? tableId;
  final DeliveryInfo? deliveryInfo;

  Order({
    required this.id,
    required this.items,
    required this.timestamp,
    required this.status,
    required this.type,
    this.tableNumber,
    this.tableId,
    this.deliveryInfo,
  });

  factory Order.fromJson(Map<String, dynamic> json) {
    var itemsList = <CartItem>[];
    if (json['itens_pedido'] is List) {
      itemsList = (json['itens_pedido'] as List)
          .map((itemJson) => CartItem.fromJson(itemJson))
          .toList();
    }

    int? tableNum;
    if (json['table_number'] != null) {
      tableNum = (json['table_number'] as num?)?.toInt();
    } else if (json['mesas'] is Map) {
      tableNum = (json['mesas']['numero'] as num?)?.toInt();
    }

    DeliveryInfo? deliveryData;
    if (json['delivery'] is List && (json['delivery'] as List).isNotEmpty) {
      deliveryData = DeliveryInfo.fromJson((json['delivery'] as List).first);
    } else if (json['delivery'] is Map) {
      deliveryData = DeliveryInfo.fromJson(json['delivery']);
    }

    return Order(
      id: json['id'] ?? 0,
      items: itemsList,
      timestamp:
          DateTime.tryParse(json['created_at'] ?? '') ?? DateTime.now(),
      status: json['status'] ?? 'production',
      type: json['type'] ?? 'mesa',
      tableNumber: tableNum,
      tableId: (json['mesas'] is Map)
          ? json['mesas']['id'].toString()
          : json['mesa_id']?.toString(),
      deliveryInfo: deliveryData,
    );
  }

  double get total => items.fold(0.0, (sum, item) => sum + item.totalPrice);
}

class Transaction {
  final String id;
  final int tableNumber;
  final double totalAmount;
  final DateTime timestamp;
  final String paymentMethod;
  final double discount;
  final double surcharge;

  Transaction({
    required this.id,
    required this.tableNumber,
    required this.totalAmount,
    required this.timestamp,
    required this.paymentMethod,
    required this.discount,
    required this.surcharge,
  });

  factory Transaction.fromJson(Map<String, dynamic> jsonData) {
    return Transaction(
      id: jsonData['id']?.toString() ?? '',
      tableNumber: jsonData['table_number'] ?? 0,
      totalAmount: (jsonData['total_amount'] as num?)?.toDouble() ?? 0.0,
      timestamp:
          DateTime.tryParse(jsonData['created_at'] ?? '') ?? DateTime.now(),
      paymentMethod: jsonData['payment_method'] ?? 'N/A',
      discount: (jsonData['discount'] as num?)?.toDouble() ?? 0.0,
      surcharge: (jsonData['surcharge'] as num?)?.toDouble() ?? 0.0,
    );
  }
}

class CustomSpreadsheet {
  final String? id;
  final String name;
  final List<List<String>> sheetData;
  final DateTime createdAt;

  CustomSpreadsheet({
    this.id,
    required this.name,
    required this.sheetData,
    required this.createdAt,
  });

  factory CustomSpreadsheet.fromJson(Map<String, dynamic> json) {
    List<List<String>> data = [];
    if (json['sheet_data'] is List) {
      data = (json['sheet_data'] as List)
          .map((row) => (row as List).map((cell) => cell.toString()).toList())
          .toList();
    }

    return CustomSpreadsheet(
      id: json['id'],
      name: json['name'] ?? '',
      sheetData: data,
      createdAt: DateTime.tryParse(json['created_at'] ?? '') ?? DateTime.now(),
    );
  }
}

class Estabelecimento {
  final String? id;
  final String nomeFantasia;
  final String cnpj;
  final String telefone;
  final String rua;
  final String numero;
  final String bairro;
  final String cidade;
  final String estado;

  Estabelecimento({
    this.id,
    required this.nomeFantasia,
    required this.cnpj,
    required this.telefone,
    required this.rua,
    required this.numero,
    required this.bairro,
    required this.cidade,
    required this.estado,
  });

  factory Estabelecimento.fromJson(Map<String, dynamic> json) {
    return Estabelecimento(
      id: json['id'],
      nomeFantasia: json['nome_fantasia'] ?? '',
      cnpj: json['cnpj'] ?? '',
      telefone: json['telefone'] ?? '',
      rua: json['rua'] ?? '',
      numero: json['numero'] ?? '',
      bairro: json['bairro'] ?? '',
      cidade: json['cidade'] ?? '',
      estado: json['estado'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id,
      'nome_fantasia': nomeFantasia,
      'cnpj': cnpj,
      'telefone': telefone,
      'rua': rua,
      'numero': numero,
      'bairro': bairro,
      'cidade': cidade,
      'estado': estado,
    };
  }
}