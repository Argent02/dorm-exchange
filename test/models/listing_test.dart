import 'package:dormexchange/models/listing.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Listing parsing and helpers', () {
    test('parses price from string and num', () {
      final fromString = Listing.fromJson({
        'id': 'l1',
        'title': 'Chair',
        'description': null,
        'imageUrl': null,
        'price': '10.25',
        'isFree': false,
        'category': 'furniture',
        'status': 'active',
        'createdBy': 'u1',
        'createdAt': '2026-02-15T00:00:00.000Z',
        'updatedAt': '2026-02-15T00:00:00.000Z',
      });

      final fromNum = Listing.fromJson({
        'id': 'l2',
        'title': 'Table',
        'description': null,
        'imageUrl': null,
        'price': 15,
        'isFree': false,
        'category': 'furniture',
        'status': 'active',
        'createdBy': 'u1',
        'createdAt': '2026-02-15T00:00:00.000Z',
        'updatedAt': '2026-02-15T00:00:00.000Z',
      });

      expect(fromString.price, 10.25);
      expect(fromNum.price, 15.0);
    });

    test('copyWith only updates requested fields', () {
      final listing = Listing.fromJson({
        'id': 'l3',
        'title': 'Fan',
        'description': 'Box fan',
        'imageUrl': null,
        'price': null,
        'isFree': true,
        'category': 'appliances',
        'status': 'active',
        'createdBy': 'u2',
        'createdAt': '2026-02-15T00:00:00.000Z',
        'updatedAt': '2026-02-15T00:00:00.000Z',
        'isSaved': false,
      });

      final updated = listing.copyWith(isSaved: true);
      expect(updated.isSaved, isTrue);
      expect(updated.id, listing.id);
      expect(updated.title, listing.title);
    });
  });
}

