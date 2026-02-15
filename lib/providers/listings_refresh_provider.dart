import 'package:flutter/foundation.dart';

/// Notifies when listings should be refreshed (e.g. after creating a new one).
class ListingsRefreshProvider extends ChangeNotifier {
  void trigger() => notifyListeners();
}
