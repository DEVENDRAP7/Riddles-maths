import 'dart:convert';
import 'package:flutter/services.dart' show rootBundle;

import 'level.dart';

/// Loads the 100 puzzle levels from the bundled JSON asset.
class LevelsRepository {
  List<Level>? _cache;

  Future<List<Level>> loadLevels() async {
    if (_cache != null) return _cache!;
    final raw = await rootBundle.loadString('assets/data/levels.json');
    final list = (jsonDecode(raw) as List)
        .map((e) => Level.fromJson(e as Map<String, dynamic>))
        .toList()
      ..sort((a, b) => a.level.compareTo(b.level));
    _cache = list;
    return list;
  }
}
