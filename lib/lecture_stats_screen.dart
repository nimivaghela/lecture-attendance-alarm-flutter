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

  int l1Attended = 0, l1Missed = 0;
  int l2Attended = 0, l2Missed = 0;
  int l3Attended = 0, l3Missed = 0;

  @override
  void initState() {
    super.initState();
    _loadStats();
  }

  Future<void> _loadStats() async {
    final prefs = await SharedPreferences.getInstance();
    final settings = await LectureSettingsService.load();

    setState(() {
      _settings = settings;
      l1Attended = prefs.getInt('attendance_L1_attended') ?? 0;
      l1Missed = prefs.getInt('attendance_L1_missed') ?? 0;
      l2Attended = prefs.getInt('attendance_L2_attended') ?? 0;
      l2Missed = prefs.getInt('attendance_L2_missed') ?? 0;
      l3Attended = prefs.getInt('attendance_L3_attended') ?? 0;
      l3Missed = prefs.getInt('attendance_L3_missed') ?? 0;
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
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _statCard('L1 - ${_settings.lecture1Name}', l1Attended, l1Missed),
          _statCard('L2 - ${_settings.lecture2Name}', l2Attended, l2Missed),
          _statCard('L3 - ${_settings.lecture3Name}', l3Attended, l3Missed),
        ],
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
