class Exchange {
  final String id;
  final String listingId;
  final String sellerId;
  final String buyerId;
  final String status;
  final DateTime createdAt;
  final DateTime? completedAt;
  final ExchangeListing? listing;
  final ExchangeUser? seller;
  final ExchangeUser? buyer;

  Exchange({
    required this.id,
    required this.listingId,
    required this.sellerId,
    required this.buyerId,
    required this.status,
    required this.createdAt,
    this.completedAt,
    this.listing,
    this.seller,
    this.buyer,
  });

  factory Exchange.fromJson(Map<String, dynamic> json) {
    return Exchange(
      id: json['id'] as String,
      listingId: json['listingId'] as String,
      sellerId: json['sellerId'] as String,
      buyerId: json['buyerId'] as String,
      status: json['status'] as String,
      createdAt: DateTime.parse(json['createdAt'] as String),
      completedAt: json['completedAt'] != null ? DateTime.parse(json['completedAt'] as String) : null,
      listing: json['listing'] != null ? ExchangeListing.fromJson(json['listing'] as Map<String, dynamic>) : null,
      seller: json['seller'] != null ? ExchangeUser.fromJson(json['seller'] as Map<String, dynamic>) : null,
      buyer: json['buyer'] != null ? ExchangeUser.fromJson(json['buyer'] as Map<String, dynamic>) : null,
    );
  }
}

class ExchangeListing {
  final String id;
  final String title;
  final String? imageUrl;
  final bool isFree;
  final double? price;
  final String? status;

  ExchangeListing({
    required this.id,
    required this.title,
    this.imageUrl,
    required this.isFree,
    this.price,
    this.status,
  });

  factory ExchangeListing.fromJson(Map<String, dynamic> json) {
    return ExchangeListing(
      id: json['id'] as String,
      title: json['title'] as String,
      imageUrl: json['imageUrl'] as String?,
      isFree: json['isFree'] as bool,
      price: json['price'] != null
          ? (json['price'] is String ? double.tryParse(json['price'] as String) : (json['price'] as num).toDouble())
          : null,
      status: json['status'] as String?,
    );
  }
}

class ExchangeUser {
  final String id;
  final String? name;
  final String email;

  ExchangeUser({
    required this.id,
    this.name,
    required this.email,
  });

  factory ExchangeUser.fromJson(Map<String, dynamic> json) {
    return ExchangeUser(
      id: json['id'] as String,
      name: json['name'] as String?,
      email: json['email'] as String,
    );
  }
}
