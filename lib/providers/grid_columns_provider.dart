import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

const String _keyGridColumns = 'grid_columns';

class GridColumnsProvider extends ChangeNotifier {
  int _columns = 2;
  int get columns => _columns;

  GridColumnsProvider() {
    _load();
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    final v = prefs.getInt(_keyGridColumns);
    if (v != null && v >= 1 && v <= 3) {
      _columns = v;
      notifyListeners();
    }
  }

  Future<void> setColumns(int cols) async {
    if (cols < 1 || cols > 3) return;
    _columns = cols;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_keyGridColumns, cols);
  }

  void cycleColumns() {
    final next = _columns >= 3 ? 1 : _columns + 1;
    setColumns(next);
  }
}
