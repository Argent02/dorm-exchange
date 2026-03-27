import 'package:dormexchange/models/exchange.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Exchange parsing', () {
    test('Exchange.fromJson parses nested listing and users', () {
      final exchange = Exchange.fromJson({
        'id': 'e1',
        'listingId': 'l1',
        'sellerId': 's1',
        'buyerId': 'b1',
        'status': 'completed',
        'createdAt': '2026-02-15T00:00:00.000Z',
        'completedAt': '2026-02-15T01:00:00.000Z',
        'listing': {
          'id': 'l1',
          'title': 'Mini fridge',
          'imageUrl': null,
          'isFree': false,
          'price': '35.50',
          'status': 'sold',
        },
        'seller': {'id': 's1', 'name': 'Seller', 'email': 's@example.com'},
        'buyer': {'id': 'b1', 'name': 'Buyer', 'email': 'b@example.com'},
      });

      expect(exchange.listing?.title, 'Mini fridge');
      expect(exchange.listing?.price, 35.5);
      expect(exchange.seller?.email, 's@example.com');
      expect(exchange.completedAt, isNotNull);
    });

    test('SoldListingDisplay.fromJson parses num/string prices and updatedAt', () {
      final soldA = SoldListingDisplay.fromJson({
        'id': 'l2',
        'title': 'Desk lamp',
        'imageUrl': '',
        'isFree': false,
        'price': 12,
        'status': 'taken',
        'updatedAt': '2026-02-16T00:00:00.000Z',
      });

      final soldB = SoldListingDisplay.fromJson({
        'id': 'l3',
        'title': 'Storage bins',
        'imageUrl': null,
        'isFree': true,
        'price': '0',
        'status': 'sold',
        'updatedAt': '2026-02-17T00:00:00.000Z',
      });

      expect(soldA.price, 12.0);
      expect(soldB.price, 0.0);
      expect(soldA.updatedAt.toUtc().toIso8601String(), '2026-02-16T00:00:00.000Z');
    });
  });
}

