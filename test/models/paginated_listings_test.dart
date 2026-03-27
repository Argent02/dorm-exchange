import 'package:dormexchange/models/listing.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('PaginatedListings.fromJson parses pagination and listing list', () {
    final paginated = PaginatedListings.fromJson({
      'listings': [
        {
          'id': 'l1',
          'title': 'Notebook',
          'description': null,
          'imageUrl': null,
          'price': 2,
          'isFree': false,
          'category': 'school',
          'status': 'active',
          'createdBy': 'u1',
          'createdAt': '2026-02-15T00:00:00.000Z',
          'updatedAt': '2026-02-15T00:00:00.000Z',
          'isSaved': true,
        },
      ],
      'pagination': {
        'page': 1,
        'limit': 20,
        'total': 1,
        'totalPages': 1,
      },
    });

    expect(paginated.page, 1);
    expect(paginated.limit, 20);
    expect(paginated.total, 1);
    expect(paginated.totalPages, 1);
    expect(paginated.listings, hasLength(1));
    expect(paginated.listings.first.isSaved, isTrue);
  });
}

