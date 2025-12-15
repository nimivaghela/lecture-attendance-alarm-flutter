// lib/lecture_home_screen.dart
import 'package:flutter/material.dart';

import 'lecture_settings.dart';
import 'lecture_stats_screen.dart';
import 'services/lecture_notification_service.dart';

/// Data returned from the Add/Edit lecture dialog
class _NewLectureData {
  final String name;
  final TimeOfDay time;
  final Set<int> days; // 1=Mon..7=Sun

  _NewLectureData({required this.name, required this.time, required this.days});
}

class LectureHomeScreen extends StatefulWidget {
  const LectureHomeScreen({super.key});

  @override
  State<LectureHomeScreen> createState() => _LectureHomeScreenState();
}

class _LectureHomeScreenState extends State<LectureHomeScreen> {
  /// One controller + time + days + enabled per lecture row
  final List<TextEditingController> _controllers = [];
  final List<TimeOfDay> _times = [];
  final List<Set<int>> _lectureDays = []; // 1=Mon ... 7=Sun
  final List<bool> _enabled = []; // per-lecture enable/disable

  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  @override
  void dispose() {
    for (final c in _controllers) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _loadSettings() async {
    final settings = await LectureSettingsService.load();

    _controllers.clear();
    _times.clear();
    _lectureDays.clear();
    _enabled.clear();

    // If nothing stored, use defaults
    final lectures =
        settings.lectures.isNotEmpty
            ? settings.lectures
            : LectureSettings.defaultSettings.lectures;

    for (final lec in lectures) {
      _controllers.add(TextEditingController(text: lec.name));
      _times.add(TimeOfDay(hour: lec.hour, minute: lec.minute));
      _lectureDays.add(lec.days.toSet());
      _enabled.add(lec.enabled);
    }

    setState(() {
      _loading = false;
    });
  }

  Future<TimeOfDay?> _show24hTimePicker(
    BuildContext context,
    TimeOfDay initialTime,
  ) {
    return showTimePicker(
      context: context,
      initialTime: initialTime,
      builder: (ctx, child) {
        final media = MediaQuery.of(ctx);
        final baseTheme = Theme.of(ctx);

        return MediaQuery(
          data: media.copyWith(alwaysUse24HourFormat: true),
          child: Theme(
            data: baseTheme.copyWith(
              // white/black theme
              colorScheme: const ColorScheme.light(
                primary: Colors.white, // selected tile background
                onPrimary: Colors.black, // text on selected tile
                surface: Colors.white, // dialog background
                onSurface: Colors.black, // normal text
              ),
              timePickerTheme: const TimePickerThemeData(
                backgroundColor: Colors.white,
                // border around whole dialog
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.zero,
                  side: BorderSide(color: Colors.black, width: 1),
                ),
                // border + square shape for HH and MM
                hourMinuteShape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.zero,
                  side: BorderSide(color: Colors.black, width: 1),
                ),
                hourMinuteTextColor: Colors.black,
                dialHandColor: Colors.black54,
                dialBackgroundColor: Colors.white,
                dialTextColor: Colors.black,
                entryModeIconColor: Colors.black,
                helpTextStyle: TextStyle(color: Colors.black),
              ),
              textButtonTheme: TextButtonThemeData(
                style: ButtonStyle(
                  foregroundColor: MaterialStatePropertyAll<Color>(
                    Colors.black,
                  ),
                  overlayColor: const MaterialStatePropertyAll<Color>(
                    Colors.black54,
                  ),
                  shape: const MaterialStatePropertyAll<OutlinedBorder>(
                    RoundedRectangleBorder(borderRadius: BorderRadius.zero),
                  ),
                ),
              ),
            ),
            child: child!,
          ),
        );
      },
    );
  }

  String _formatTime24(TimeOfDay t) {
    final hh = t.hour.toString().padLeft(2, '0');
    final mm = t.minute.toString().padLeft(2, '0');
    return '$hh:$mm';
  }

  Future<void> _pickTimeInline(int index) async {
    final initial = _times[index];

    final picked = await _show24hTimePicker(context, initial);
    if (picked == null) return;

    setState(() {
      _times[index] = picked;
    });
  }

  // ---------- ADD / EDIT DIALOGS ----------

  Future<_NewLectureData?> _showLectureDialog({
    required BuildContext ctx,
    String? initialName,
    TimeOfDay? initialTime,
    Set<int>? initialDays,
    required String title,
  }) async {
    final nameController = TextEditingController(
      text: initialName?.trim() ?? '',
    );
    TimeOfDay dialogTime = initialTime ?? const TimeOfDay(hour: 9, minute: 0);
    final Set<int> selectedDays =
        initialDays != null && initialDays.isNotEmpty
            ? {...initialDays}
            : {1, 2, 3, 4, 5}; // default Mon–Fri

    final result = await showDialog<_NewLectureData>(
      context: ctx,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (dialogContext, setStateDialog) {
            Future<void> pickDialogTime() async {
              final picked = await _show24hTimePicker(
                dialogContext,
                dialogTime,
              );
              if (picked != null) {
                setStateDialog(() {
                  dialogTime = picked;
                });
              }
            }

            return AlertDialog(
              backgroundColor: Colors.white,
              shape: const RoundedRectangleBorder(
                borderRadius: BorderRadius.zero,
              ),
              title: Text(title),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: nameController,
                      decoration: const InputDecoration(
                        labelText: 'Lecture name',
                        hintText: 'e.g. Mathematics',
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        const Text('Time:'),
                        const SizedBox(width: 16),
                        ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.black,
                            foregroundColor: Colors.white,
                            shape: const RoundedRectangleBorder(
                              borderRadius: BorderRadius.zero,
                            ),
                          ),
                          icon: const Icon(Icons.alarm),
                          onPressed: pickDialogTime,
                          label: Text(_formatTime24(dialogTime)),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        'Days:',
                        style: Theme.of(dialogContext).textTheme.bodyMedium,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 4,
                      runSpacing: 4,
                      children: List.generate(7, (i) {
                        final day = i + 1; // 1..7
                        final isSelected = selectedDays.contains(day);
                        return ChoiceChip(
                          label: Text(
                            _weekdayShortName(day),
                            style: TextStyle(
                              color: isSelected ? Colors.white : Colors.black,
                            ),
                          ),
                          selected: isSelected,
                          selectedColor: Colors.black,
                          backgroundColor: Colors.white,
                          checkmarkColor: Colors.white,
                          side: const BorderSide(color: Colors.black),
                          shape: const RoundedRectangleBorder(
                            borderRadius: BorderRadius.zero,
                          ),
                          onSelected: (val) {
                            setStateDialog(() {
                              if (val) {
                                selectedDays.add(day);
                              } else {
                                selectedDays.remove(day);
                              }
                            });
                          },
                        );
                      }),
                    ),
                  ],
                ),
              ),
              actions: [
                OutlinedButton(
                  style: OutlinedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: Colors.black,
                    shape: const RoundedRectangleBorder(
                      borderRadius: BorderRadius.zero,
                    ),
                  ),
                  onPressed: () => Navigator.of(dialogContext).pop(),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.black,
                    foregroundColor: Colors.white,
                    shape: const RoundedRectangleBorder(
                      borderRadius: BorderRadius.zero,
                    ),
                  ),
                  onPressed: () {
                    final rawName = nameController.text.trim();
                    final name = rawName.isEmpty ? 'Lecture' : rawName;

                    if (selectedDays.isEmpty) {
                      // Ensure at least 1 day
                      selectedDays.add(1);
                    }

                    Navigator.of(dialogContext).pop(
                      _NewLectureData(
                        name: name,
                        time: dialogTime,
                        days: {...selectedDays},
                      ),
                    );
                  },
                  child: const Text('Save Alert'),
                ),
              ],
            );
          },
        );
      },
    );

    // Don't dispose nameController here (avoids "used after dispose" issues)
    return result;
  }

  Future<void> _openAddLectureDialog() async {
    final result = await _showLectureDialog(ctx: context, title: 'Add Lecture');

    if (result != null) {
      setState(() {
        _controllers.add(TextEditingController(text: result.name));
        _times.add(result.time);
        _lectureDays.add(result.days);
        _enabled.add(true); // new lecture enabled by default
      });
      await _saveAndSchedule(); // persist immediately if you want
    }
  }

  Future<void> _openEditLectureDialog(int index) async {
    final currentName = _controllers[index].text.trim();
    final currentTime = _times[index];
    final currentDays =
        (index < _lectureDays.length) ? _lectureDays[index] : <int>{1, 2, 3};

    final result = await _showLectureDialog(
      ctx: context,
      title: 'Edit Lecture',
      initialName: currentName,
      initialTime: currentTime,
      initialDays: currentDays,
    );

    if (result != null) {
      setState(() {
        _controllers[index].text = result.name;
        _times[index] = result.time;
        if (index < _lectureDays.length) {
          _lectureDays[index] = result.days;
        } else {
          _lectureDays.add(result.days);
        }
      });
      await _saveAndSchedule();
    }
  }

  // ---------- SAVE TO SETTINGS + SCHEDULE ----------

  String _getNameOrFallback(int index, String fallback) {
    if (index >= _controllers.length) return fallback;
    final text = _controllers[index].text.trim();
    return text.isEmpty ? fallback : text;
  }

  TimeOfDay _getTimeOrFallback(int index, TimeOfDay fallback) {
    if (index >= _times.length) return fallback;
    return _times[index];
  }

  /// Build LectureSettings from current UI state and save & schedule
  Future<void> _saveAndSchedule() async {
    final List<LectureConfig> lectures = [];

    for (int i = 0; i < _controllers.length; i++) {
      final name = _getNameOrFallback(i, 'Lecture ${i + 1}');
      final time = _getTimeOrFallback(i, const TimeOfDay(hour: 9, minute: 0));
      final enabled = i < _enabled.length ? _enabled[i] : true;
      final daysSet =
          i < _lectureDays.length && _lectureDays[i].isNotEmpty
              ? _lectureDays[i]
              : <int>{1, 2, 3, 4, 5, 6, 7};

      lectures.add(
        LectureConfig(
          name: name,
          hour: time.hour,
          minute: time.minute,
          enabled: enabled,
          days: daysSet.toList()..sort(),
        ),
      );
    }

    final settings = LectureSettings(lectures: lectures);

    // Persist to SharedPreferences
    await LectureSettingsService.save(settings);

    // Schedule notifications based on these settings
    await LectureNotificationService.instance.scheduleFromSettings(settings);

    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Lecture alerts scheduled')));
  }

  // ---------- UI BUILD ----------

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
              // Dynamic rows (including newly added ones)
              for (int i = 0; i < _controllers.length; i++)
                _lectureRow(
                  index: i,
                  label: 'Lecture ${i + 1}',
                  controller: _controllers[i],
                  time: _times[i],
                  days: i < _lectureDays.length ? _lectureDays[i] : null,
                  onTapEdit: () => _openEditLectureDialog(i),
                  onInlinePickTime: () => _pickTimeInline(i),
                ),
              const SizedBox(height: 12),

              // Add lecture → opens popup
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: Colors.black,
                    shape: const RoundedRectangleBorder(
                      borderRadius: BorderRadius.zero,
                    ),
                  ),
                  onPressed: _openAddLectureDialog,
                  icon: const Icon(Icons.add),
                  label: const Text('Add Lecture'),
                ),
              ),

              const SizedBox(height: 24),

              // Save / Stop alerts
              Row(
                children: [
                  Expanded(
                    child: SizedBox(
                      height: 48,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.black,
                          foregroundColor: Colors.white,
                          shape: const RoundedRectangleBorder(
                            borderRadius: BorderRadius.zero,
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
                  const SizedBox(width: 10),
                  Expanded(
                    child: SizedBox(
                      height: 48,
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
                width: double.infinity,
                child: OutlinedButton(
                  style: OutlinedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: Colors.black,
                    shape: const RoundedRectangleBorder(
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

  Widget _lectureRow({
    required int index,
    required String label,
    required TextEditingController controller,
    required TimeOfDay time,
    required VoidCallback onTapEdit,
    required VoidCallback onInlinePickTime,
    Set<int>? days,
  }) {
    final isEnabled = index < _enabled.length ? _enabled[index] : true;

    return Card(
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
      color: Colors.white,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        child: Opacity(
          opacity: isEnabled ? 1.0 : 0.4, // fade disabled rows
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Top row: label + edit icon + switch
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: controller,
                      readOnly: true,
                      decoration: InputDecoration(
                        labelText: label,
                        hintText: 'Subject name',
                        border: InputBorder.none,
                      ),
                      onTap: onTapEdit, // tap label area -> edit
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.edit),
                    tooltip: 'Edit lecture',
                    onPressed: onTapEdit,
                  ),
                  const SizedBox(width: 4),
                  // Enable / Disable switch
                  Switch(
                    value: isEnabled,
                    onChanged: (val) async {
                      setState(() {
                        _enabled[index] = val;
                      });
                      await _saveAndSchedule(); // persist & reschedule immediately
                    },
                    activeColor: Colors.white,
                    activeTrackColor: Colors.black,
                    inactiveThumbColor: Colors.black,
                    inactiveTrackColor: Colors.black26,
                    materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                ],
              ),
              const SizedBox(height: 4),
              // Time + day summary
              Row(
                children: [
                  InkWell(
                    onTap: onInlinePickTime,
                    child: Row(
                      children: [
                        const Icon(Icons.alarm, size: 18),
                        const SizedBox(width: 4),
                        Text(_formatTime24(time)),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  if (days != null && days.isNotEmpty)
                    Expanded(
                      child: Text(
                        _formatDays(days),
                        style: const TextStyle(
                          fontSize: 12,
                          color: Colors.grey,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _weekdayShortName(int weekday) {
    switch (weekday) {
      case 1:
        return 'Mon';
      case 2:
        return 'Tue';
      case 3:
        return 'Wed';
      case 4:
        return 'Thu';
      case 5:
        return 'Fri';
      case 6:
        return 'Sat';
      case 7:
        return 'Sun';
      default:
        return '?';
    }
  }

  String _formatDays(Set<int> days) {
    final sorted = days.toList()..sort();
    return sorted.map(_weekdayShortName).join(', ');
  }
}
