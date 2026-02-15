import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';

class RtdbService {
  static final DatabaseReference _ref = FirebaseDatabase.instance.ref();

  static Future<void> ensureConversation(
    String conversationId,
    String initiatorFirebaseUid,
    String ownerFirebaseUid,
  ) async {
    final convRef = _ref.child('conversations').child(conversationId);
    final snapshot = await convRef.get();
    if (!snapshot.exists) {
      await convRef.set({
        'initiatorUid': initiatorFirebaseUid,
        'ownerUid': ownerFirebaseUid,
        'updatedAt': ServerValue.timestamp,
      });
    }
  }

  static Stream<DatabaseEvent> watchMessages(String conversationId) {
    return _ref.child('messages').child(conversationId).onChildAdded;
  }

  static Future<String> sendMessage(String conversationId, String content) async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) throw Exception('Not authenticated');

    final messagesRef = _ref.child('messages').child(conversationId);
    final pushRef = messagesRef.push();
    await pushRef.set({
      'content': content,
      'senderUid': uid,
      'createdAt': ServerValue.timestamp,
    });
    return pushRef.key ?? '';
  }
}
