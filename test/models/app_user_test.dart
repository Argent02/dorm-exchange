import 'package:dormexchange/models/user.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('AppUser JSON parsing', () {
    test('fromJson parses dorm field and required fields', () {
      final user = AppUser.fromJson({
        'id': 'u1',
        'firebaseUid': 'f1',
        'email': 'user@example.com',
        'name': 'User',
        'avatarUrl': null,
        'phone': '123',
        'dorm': 'Neptune North',
        'role': 'student',
        'isVerified': false,
        'reportCount': 0,
        'joinDate': '2026-02-15T00:00:00.000Z',
      });

      expect(user.id, 'u1');
      expect(user.dorm, 'Neptune North');
      expect(user.role, 'student');
    });

    test('toJson includes dorm and serializes joinDate', () {
      final user = AppUser(
        id: 'u1',
        firebaseUid: 'f1',
        email: 'user@example.com',
        dorm: 'Patterson Hall',
        role: 'student',
        isVerified: true,
        reportCount: 2,
        joinDate: DateTime.parse('2026-02-15T00:00:00.000Z'),
      );

      final json = user.toJson();
      expect(json['dorm'], 'Patterson Hall');
      expect(json['joinDate'], '2026-02-15T00:00:00.000Z');
    });
  });
}

