// lib/lecture_settings.dart
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

/// One lecture config (used for ALL lectures: default + newly added)
class LectureConfig {
  final String name;
  final int hour;
  final int minute;
  final bool enabled;
  final List<int> days; // 1 = Mon .. 7 = Sun

  const LectureConfig({
    required this.name,
    required this.hour,
    required this.minute,
    required this.enabled,
    required this.days,
  });

  Map<String, dynamic> toJson() => {
    'name': name,
    'hour': hour,
    'minute': minute,
    'enabled': enabled,
    'days': days,
  };

  factory LectureConfig.fromJson(Map<String, dynamic> json) {
    final rawDays = json['days'];
    final List<int> parsedDays;
    if (rawDays is List) {
      parsedDays = rawDays
          .map((e) => (e as num).toInt())
          .toList(growable: false);
    } else {
      // fallback → all days
      parsedDays = const [1, 2, 3, 4, 5, 6, 7];
    }

    return LectureConfig(
      name: json['name'] as String? ?? 'Lecture',
      hour: json['hour'] as int? ?? 9,
      minute: json['minute'] as int? ?? 0,
      enabled: json['enabled'] as bool? ?? true,
      days: parsedDays,
    );
  }

  LectureConfig copyWith({
    String? name,
    int? hour,
    int? minute,
    bool? enabled,
    List<int>? days,
  }) {
    return LectureConfig(
      name: name ?? this.name,
      hour: hour ?? this.hour,
      minute: minute ?? this.minute,
      enabled: enabled ?? this.enabled,
      days: days ?? this.days,
    );
  }
}

/// Settings now = LIST of lectures (no more fixed lecture1/2/3 in the model)
class LectureSettings {
  final List<LectureConfig> lectures;

  const LectureSettings({required this.lectures});

  Map<String, dynamic> toJson() => {
    'lectures': lectures.map((l) => l.toJson()).toList(),
  };

  factory LectureSettings.fromJson(Map<String, dynamic> json) {
    // New format v2: "lectures": [ {name, hour, ...}, ... ]
    if (json['lectures'] is List) {
      final list =
          (json['lectures'] as List)
              .whereType<Map<String, dynamic>>()
              .map(LectureConfig.fromJson)
              .toList();
      if (list.isNotEmpty) {
        return LectureSettings(lectures: list);
      }
    }

    // Fallback: old v1 format with lecture1Name, lecture2Name, ...
    final String l1Name = json['lecture1Name'] ?? 'Lecture 1';
    final int l1Hour = json['lecture1Hour'] ?? 9;
    final int l1Minute = json['lecture1Minute'] ?? 0;
    final bool l1Enabled = json['lecture1Enabled'] ?? true;

    final String l2Name = json['lecture2Name'] ?? 'Lecture 2';
    final int l2Hour = json['lecture2Hour'] ?? 11;
    final int l2Minute = json['lecture2Minute'] ?? 0;
    final bool l2Enabled = json['lecture2Enabled'] ?? true;

    final String l3Name = json['lecture3Name'] ?? 'Lecture 3';
    final int l3Hour = json['lecture3Hour'] ?? 14;
    final int l3Minute = json['lecture3Minute'] ?? 0;
    final bool l3Enabled = json['lecture3Enabled'] ?? true;

    return LectureSettings(
      lectures: [
        LectureConfig(
          name: l1Name,
          hour: l1Hour,
          minute: l1Minute,
          enabled: l1Enabled,
          days: const [1, 2, 3, 4, 5, 6, 7],
        ),
        LectureConfig(
          name: l2Name,
          hour: l2Hour,
          minute: l2Minute,
          enabled: l2Enabled,
          days: const [1, 2, 3, 4, 5, 6, 7],
        ),
        LectureConfig(
          name: l3Name,
          hour: l3Hour,
          minute: l3Minute,
          enabled: l3Enabled,
          days: const [1, 2, 3, 4, 5, 6, 7],
        ),
      ],
    );
  }

  static const LectureSettings defaultSettings = LectureSettings(
    lectures: [
      LectureConfig(
        name: 'Lecture 1',
        hour: 9,
        minute: 0,
        enabled: true,
        days: [1, 2, 3, 4, 5, 6, 7],
      ),
      LectureConfig(
        name: 'Lecture 2',
        hour: 11,
        minute: 0,
        enabled: true,
        days: [1, 2, 3, 4, 5, 6, 7],
      ),
      LectureConfig(
        name: 'Lecture 3',
        hour: 14,
        minute: 0,
        enabled: true,
        days: [1, 2, 3, 4, 5, 6, 7],
      ),
    ],
  );
}

class LectureSettingsService {
  // keep same key, we handle both old & new JSON in fromJson()
  static const _key = 'lecture_settings_v1';

  static Future<LectureSettings> load() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_key);
    if (raw == null) return LectureSettings.defaultSettings;

    try {
      final map = jsonDecode(raw) as Map<String, dynamic>;
      return LectureSettings.fromJson(map);
    } catch (_) {
      return LectureSettings.defaultSettings;
    }
  }

  static Future<void> save(LectureSettings settings) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key, jsonEncode(settings.toJson()));
  }
}
