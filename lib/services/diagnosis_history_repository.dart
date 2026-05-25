import 'package:hive_flutter/hive_flutter.dart';

import '../models/diagnosis.dart';

class DiagnosisHistoryRepository {
  const DiagnosisHistoryRepository();

  static const _boxName = 'diagnosis_history';

  Future<List<DiagnosisHistoryEntry>> loadAll() async {
    final box = await Hive.openBox<Map>(_boxName);
    final entries =
        box.values
            .map(
              (value) =>
                  DiagnosisHistoryEntry.fromJson(value.cast<String, dynamic>()),
            )
            .toList()
          ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return entries;
  }

  Future<void> save(DiagnosisHistoryEntry entry) async {
    final box = await Hive.openBox<Map>(_boxName);
    await box.put(entry.id, entry.toJson());
  }

  Future<void> clear() async {
    final box = await Hive.openBox<Map>(_boxName);
    await box.clear();
  }
}
