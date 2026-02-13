class ListingCreator {
  final String id;
  final String? name;
  final String email;

  ListingCreator({
    required this.id,
    this.name,
    required this.email,
  });

  factory ListingCreator.fromJson(Map<String, dynamic> json) {
    return ListingCreator(
      id: json['id'] as String,
      name: json['name'] as String?,
      email: json['email'] as String,
    );
  }
}

class Listing {
  final String id;
  final String title;
  final String? description;
  final String? imageUrl;
  final double? price;
  final bool isFree;
  final String? category;
  final String status;
  final String createdBy;
  final DateTime createdAt;
  final DateTime updatedAt;
  final ListingCreator? creator;

  Listing({
    required this.id,
    required this.title,
    this.description,
    this.imageUrl,
    this.price,
    required this.isFree,
    this.category,
    required this.status,
    required this.createdBy,
    required this.createdAt,
    required this.updatedAt,
    this.creator,
  });

  factory Listing.fromJson(Map<String, dynamic> json) {
    return Listing(
      id: json['id'] as String,
      title: json['title'] as String,
      description: json['description'] as String?,
      imageUrl: json['imageUrl'] as String?,
      price: json['price'] != null
          ? (json['price'] is String
              ? double.tryParse(json['price'] as String)
              : (json['price'] as num).toDouble())
          : null,
      isFree: json['isFree'] as bool,
      category: json['category'] as String?,
      status: json['status'] as String,
      createdBy: json['createdBy'] as String,
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
      creator: json['creator'] != null
          ? ListingCreator.fromJson(json['creator'] as Map<String, dynamic>)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'title': title,
      'description': description,
      'imageUrl': imageUrl,
      'price': price,
      'isFree': isFree,
      'category': category,
    };
  }
}

class PaginatedListings {
  final List<Listing> listings;
  final int page;
  final int limit;
  final int total;
  final int totalPages;

  PaginatedListings({
    required this.listings,
    required this.page,
    required this.limit,
    required this.total,
    required this.totalPages,
  });

  factory PaginatedListings.fromJson(Map<String, dynamic> json) {
    final pagination = json['pagination'] as Map<String, dynamic>;
    return PaginatedListings(
      listings: (json['listings'] as List<dynamic>)
          .map((e) => Listing.fromJson(e as Map<String, dynamic>))
          .toList(),
      page: pagination['page'] as int,
      limit: pagination['limit'] as int,
      total: pagination['total'] as int,
      totalPages: pagination['totalPages'] as int,
    );
  }
}
