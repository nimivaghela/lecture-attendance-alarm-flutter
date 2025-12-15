import 'package:flutter/material.dart';

import 'lecture_settings.dart';
import 'lecture_stats_screen.dart';
import 'services/lecture_notification_service.dart';

class LectureHomeScreen extends StatefulWidget {
  const LectureHomeScreen({super.key});

  @override
  State<LectureHomeScreen> createState() => _LectureHomeScreenState();
}

class _LectureHomeScreenState extends State<LectureHomeScreen> {
  final _l1Controller = TextEditingController();
  final _l2Controller = TextEditingController();
  final _l3Controller = TextEditingController();

  TimeOfDay _t1 = const TimeOfDay(hour: 9, minute: 0);
  TimeOfDay _t2 = const TimeOfDay(hour: 11, minute: 0);
  TimeOfDay _t3 = const TimeOfDay(hour: 14, minute: 0);

  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final s = await LectureSettingsService.load();
    setState(() {
      _l1Controller.text = s.lecture1Name;
      _l2Controller.text = s.lecture2Name;
      _l3Controller.text = s.lecture3Name;

      _t1 = TimeOfDay(hour: s.lecture1Hour, minute: s.lecture1Minute);
      _t2 = TimeOfDay(hour: s.lecture2Hour, minute: s.lecture2Minute);
      _t3 = TimeOfDay(hour: s.lecture3Hour, minute: s.lecture3Minute);
      _loading = false;
    });
  }

  Future<void> _pickTime(int index) async {
    final initial = switch (index) {
      1 => _t1,
      2 => _t2,
      3 => _t3,
      _ => TimeOfDay.now(),
    };

    final picked = await showTimePicker(context: context, initialTime: initial);
    if (picked == null) return;

    setState(() {
      if (index == 1) _t1 = picked;
      if (index == 2) _t2 = picked;
      if (index == 3) _t3 = picked;
    });
  }

  Future<void> _saveAndSchedule() async {
    final s = LectureSettings(
      lecture1Name:
          _l1Controller.text.trim().isEmpty
              ? 'Mathematics'
              : _l1Controller.text.trim(),
      lecture1Hour: _t1.hour,
      lecture1Minute: _t1.minute,
      lecture2Name:
          _l2Controller.text.trim().isEmpty
              ? 'Physics'
              : _l2Controller.text.trim(),
      lecture2Hour: _t2.hour,
      lecture2Minute: _t2.minute,
      lecture3Name:
          _l3Controller.text.trim().isEmpty
              ? 'Computer Science'
              : _l3Controller.text.trim(),
      lecture3Hour: _t3.hour,
      lecture3Minute: _t3.minute,
    );

    await LectureSettingsService.save(s);
    await LectureNotificationService.instance.scheduleFromSettings(s);

    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Lecture alerts scheduled')));
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
        title: const Text('Lecture Attendance Alarm'),
        actions: [
          IconButton(
            icon: const Icon(Icons.bar_chart),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const LectureStatsScreen()),
              );
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              _lectureRow('Lecture 1', _l1Controller, _t1, () => _pickTime(1)),
              _lectureRow('Lecture 2', _l2Controller, _t2, () => _pickTime(2)),
              _lectureRow('Lecture 3', _l3Controller, _t3, () => _pickTime(3)),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: SizedBox(
                      height: 48, // optional: fixed height
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.black, // black bg
                          foregroundColor: Colors.white, // ripple / text color
                          shape: const RoundedRectangleBorder(
                            borderRadius: BorderRadius.zero, // rectangle
                          ),
                        ),
                        onPressed: _saveAndSchedule,
                        child: const Text(
                          'Save Alerts',
                          style: TextStyle(color: Colors.white),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10), // 👈 10px space between buttons
                  Expanded(
                    child: SizedBox(
                      height: 48, // optional
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.black,
                          foregroundColor: Colors.white,
                          shape: const RoundedRectangleBorder(
                            borderRadius: BorderRadius.zero,
                          ),
                        ),
                        onPressed: () async {
                          await LectureNotificationService.instance.cancelAll();
                          if (mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('All lecture alerts cancelled'),
                              ),
                            );
                          }
                        },
                        child: const Text('Stop Alerts'),
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity, // 👈 full width
                child: OutlinedButton(
                  style: OutlinedButton.styleFrom(
                    backgroundColor: Colors.white, // 👈 black bg
                    foregroundColor: Colors.black, // 👈 ripple / icon color
                    shape: const RoundedRectangleBorder(
                      // 👈 rectangle, no radius
                      borderRadius: BorderRadius.zero,
                    ),
                  ),
                  onPressed: () async {
                    await LectureNotificationService.instance.testNow();
                    if (!mounted) return;
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text(
                          'Test notification fired – check sound & popup',
                        ),
                      ),
                    );
                  },
                  child: const Text('Test Notification NOW'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _lectureRow(
    String label,
    TextEditingController controller,
    TimeOfDay time,
    VoidCallback onPickTime,
  ) {
    return Card(
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.zero, // rectangle
      ),
      color: Colors.white,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        child: Row(
          children: [
            Expanded(
              flex: 2,
              child: TextField(
                controller: controller,
                decoration: InputDecoration(
                  labelText: label,
                  hintText: 'Subject name',
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: InkWell(
                onTap: onPickTime,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    const Icon(Icons.alarm),
                    Text(time.format(context)),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
