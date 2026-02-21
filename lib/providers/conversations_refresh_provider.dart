import 'package:flutter/foundation.dart';

/// Notifies when conversations/inbox should be refreshed (e.g. after starting a new chat).
class ConversationsRefreshProvider extends ChangeNotifier {
  void trigger() => notifyListeners();
}
