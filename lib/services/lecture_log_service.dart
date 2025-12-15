import 'dart:convert';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LectureLogService {
  static const _key = 'lecture_logs_v1';

  /// Save Yes/No for a lecture on a given day
  static Future<void> saveLog({
    required String lectureId, // 'L1','L2','L3'
    required String subject,
    required bool attended,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final dateKey = DateFormat('yyyy-MM-dd').format(DateTime.now());
    final uniqueKey = '${dateKey}_$lectureId';

    final message =
        attended
            ? 'Yes attended $subject lecture'
            : 'No missed $subject lecture';

    final now = DateTime.now().toIso8601String();

    final raw = prefs.getString(_key);
    final Map<String, dynamic> map = raw == null ? {} : jsonDecode(raw);

    map[uniqueKey] = {
      'dateKey': dateKey,
      'lectureId': lectureId,
      'subject': subject,
      'attended': attended,
      'message': message,
      'savedAt': now,
    };

    await prefs.setString(_key, jsonEncode(map));
  }

  /// Raw logs list (newest first)
  static Future<List<Map<String, dynamic>>> getLogs() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_key);
    if (raw == null) return [];
    final Map<String, dynamic> map = jsonDecode(raw);
    final items = map.values.map((e) => Map<String, dynamic>.from(e)).toList();
    items.sort(
      (a, b) => (b['savedAt'] as String).compareTo(a['savedAt'] as String),
    );
    return items;
  }

  /// Stats grouped by subject:
  /// {
  ///   "Math": {"attended": 5, "total": 7},
  ///   "Physics": {"attended": 3, "total": 4},
  /// }
  static Future<Map<String, Map<String, int>>> getStatsBySubject() async {
    final logs = await getLogs();
    final Map<String, Map<String, int>> stats = {};

    for (final l in logs) {
      final subject = (l['subject'] as String?) ?? 'Unknown';
      final attended = (l['attended'] as bool?) ?? false;

      stats.putIfAbsent(subject, () => {'attended': 0, 'total': 0});

      stats[subject]!['total'] = stats[subject]!['total']! + 1;
      if (attended) {
        stats[subject]!['attended'] = stats[subject]!['attended']! + 1;
      }
    }

    return stats;
  }
}
