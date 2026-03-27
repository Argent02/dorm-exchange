import 'package:dormexchange/models/conversation.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('ConversationMessage.fromRtdb', () {
    test('parses millisecond timestamp and senderUid', () {
      final msg = ConversationMessage.fromRtdb('m1', {
        'content': 'hello',
        'senderUid': 'firebase-uid',
        'createdAt': 1707955200000,
      });

      expect(msg.id, 'm1');
      expect(msg.content, 'hello');
      expect(msg.senderUid, 'firebase-uid');
      expect(msg.createdAt.millisecondsSinceEpoch, 1707955200000);
    });

    test('falls back to now when createdAt is invalid', () {
      final before = DateTime.now();
      final msg = ConversationMessage.fromRtdb('m2', {
        'content': 'hi',
        'senderUid': 'u2',
        'createdAt': 'invalid',
      });
      final after = DateTime.now();

      expect(msg.id, 'm2');
      expect(msg.createdAt.isAfter(before) || msg.createdAt.isAtSameMomentAs(before), isTrue);
      expect(msg.createdAt.isBefore(after) || msg.createdAt.isAtSameMomentAs(after), isTrue);
    });
  });
}

