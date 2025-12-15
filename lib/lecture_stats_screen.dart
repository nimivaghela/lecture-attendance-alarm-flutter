// lib/lecture_stats_screen.dart
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'lecture_settings.dart';

class LectureStatsScreen extends StatefulWidget {
  const LectureStatsScreen({super.key});

  @override
  State<LectureStatsScreen> createState() => _LectureStatsScreenState();
}

class _LectureStatsScreenState extends State<LectureStatsScreen> {
  bool _loading = true;
  late LectureSettings _settings;

  // Parallel lists for stats, aligned by index with _settings.lectures
  List<int> _attended = [];
  List<int> _missed = [];

  @override
  void initState() {
    super.initState();
    _loadStats();
  }

  Future<void> _loadStats() async {
    final prefs = await SharedPreferences.getInstance();
    final settings = await LectureSettingsService.load();

    // Use defaults if nothing in storage
    final lectures =
        settings.lectures.isNotEmpty
            ? settings.lectures
            : LectureSettings.defaultSettings.lectures;

    final attended = <int>[];
    final missed = <int>[];

    for (int i = 0; i < lectures.length; i++) {
      final keyIndex = i + 1; // L1, L2, L3, ...

      attended.add(prefs.getInt('attendance_L${keyIndex}_attended') ?? 0);
      missed.add(prefs.getInt('attendance_L${keyIndex}_missed') ?? 0);
    }

    setState(() {
      _settings = LectureSettings(lectures: lectures);
      _attended = attended;
      _missed = missed;
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        title: const Text('Lecture Attendance Stats'),
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _settings.lectures.length,
        itemBuilder: (context, index) {
          final lecture = _settings.lectures[index];
          final attended = _attended.length > index ? _attended[index] : 0;
          final missed = _missed.length > index ? _missed[index] : 0;
          final title =
              'L${index + 1} - ${lecture.name}'
              '${lecture.enabled ? '' : ' (Disabled)'}';

          return _statCard(title, attended, missed);
        },
      ),
    );
  }

  Widget _statCard(String title, int attended, int missed) {
    final total = attended + missed;
    final percent = total == 0 ? 0 : (attended * 100 ~/ total);

    return Card(
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.zero, // rectangle
      ),
      color: Colors.white,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 10),
            Text('Attended: $attended'),
            Text('Missed: $missed'),
            const SizedBox(height: 4),
            Text('Attendance: $percent%'),
          ],
        ),
      ),
    );
  }
}
