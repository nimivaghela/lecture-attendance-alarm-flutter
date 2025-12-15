import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class LectureSettings {
  final String lecture1Name;
  final int lecture1Hour;
  final int lecture1Minute;

  final String lecture2Name;
  final int lecture2Hour;
  final int lecture2Minute;

  final String lecture3Name;
  final int lecture3Hour;
  final int lecture3Minute;

  const LectureSettings({
    required this.lecture1Name,
    required this.lecture1Hour,
    required this.lecture1Minute,
    required this.lecture2Name,
    required this.lecture2Hour,
    required this.lecture2Minute,
    required this.lecture3Name,
    required this.lecture3Hour,
    required this.lecture3Minute,
  });

  Map<String, dynamic> toJson() => {
    'lecture1Name': lecture1Name,
    'lecture1Hour': lecture1Hour,
    'lecture1Minute': lecture1Minute,
    'lecture2Name': lecture2Name,
    'lecture2Hour': lecture2Hour,
    'lecture2Minute': lecture2Minute,
    'lecture3Name': lecture3Name,
    'lecture3Hour': lecture3Hour,
    'lecture3Minute': lecture3Minute,
  };

  factory LectureSettings.fromJson(Map<String, dynamic> json) {
    return LectureSettings(
      lecture1Name: json['lecture1Name'] ?? 'Mathematics',
      lecture1Hour: json['lecture1Hour'] ?? 9,
      lecture1Minute: json['lecture1Minute'] ?? 0,
      lecture2Name: json['lecture2Name'] ?? 'Physics',
      lecture2Hour: json['lecture2Hour'] ?? 11,
      lecture2Minute: json['lecture2Minute'] ?? 0,
      lecture3Name: json['lecture3Name'] ?? 'Computer Science',
      lecture3Hour: json['lecture3Hour'] ?? 14,
      lecture3Minute: json['lecture3Minute'] ?? 0,
    );
  }

  static const defaultSettings = LectureSettings(
    lecture1Name: 'Mathematics',
    lecture1Hour: 9,
    lecture1Minute: 0,
    lecture2Name: 'Physics',
    lecture2Hour: 11,
    lecture2Minute: 0,
    lecture3Name: 'Computer Science',
    lecture3Hour: 14,
    lecture3Minute: 0,
  );
}

class LectureSettingsService {
  static const _key = 'lecture_settings_v1';

  static Future<LectureSettings> load() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_key);
    if (raw == null) return LectureSettings.defaultSettings;

    final map = jsonDecode(raw) as Map<String, dynamic>;
    return LectureSettings.fromJson(map);
  }

  static Future<void> save(LectureSettings settings) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key, jsonEncode(settings.toJson()));
  }
}
