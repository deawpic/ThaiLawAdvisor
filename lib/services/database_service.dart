import 'package:hive_flutter/hive_flutter.dart';
import '../models/history_record.dart';

class DatabaseService {
  static const String _boxName = 'history_box';

  static Future<void> init() async {
    await Hive.initFlutter();
    await Hive.openBox(_boxName);
  }

  static Future<int> saveAnalysis(HistoryRecord record) async {
    final box = Hive.box(_boxName);
    // Hive's add returns the auto-incremented integer key (id)
    final id = await box.add(record.toMap());
    return id;
  }

  static List<HistoryRecord> getAllHistory() {
    final box = Hive.box(_boxName);
    final List<HistoryRecord> list = [];
    
    for (var key in box.keys) {
      final data = box.get(key);
      if (data != null) {
        final map = Map<dynamic, dynamic>.from(data as Map);
        list.add(HistoryRecord.fromMap(key as int, map));
      }
    }
    
    // Sort by id descending (most recent first)
    list.sort((a, b) => (b.id ?? 0).compareTo(a.id ?? 0));
    return list;
  }

  static HistoryRecord? getHistoryById(int id) {
    final box = Hive.box(_boxName);
    final data = box.get(id);
    if (data != null) {
      final map = Map<dynamic, dynamic>.from(data as Map);
      return HistoryRecord.fromMap(id, map);
    }
    return null;
  }

  static void deleteHistoryById(int id) {
    final box = Hive.box(_boxName);
    box.delete(id);
  }

  static void clearAllHistory() {
    final box = Hive.box(_boxName);
    box.clear();
  }
}
