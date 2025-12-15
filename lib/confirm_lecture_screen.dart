import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ConfirmLectureScreen extends StatelessWidget {
  final String lectureId; // "L1", "L2", "L3"
  final String subject;

  const ConfirmLectureScreen({
    super.key,
    required this.lectureId,
    required this.subject,
  });

  Future<void> _mark(BuildContext context, String status) async {
    final prefs = await SharedPreferences.getInstance();
    final key =
        'attendance_${lectureId}_$status'; // e.g. attendance_L1_attended
    final current = prefs.getInt(key) ?? 0;
    await prefs.setInt(key, current + 1);

    if (context.mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Marked $status for $subject')));
      Navigator.of(context)..pop(); // close the dialog route
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      // Dimmed background to look like a dialog overlay
      backgroundColor: Colors.transparent,
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 360),
          child: Material(
            elevation: 8,
            borderRadius: BorderRadius.circular(24),
            color: theme.colorScheme.surface,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Header row: title + close button
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          'Confirm: $subject',
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () => Navigator.of(context).pop(),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Did you attend this lecture?',
                    style: theme.textTheme.titleLarge,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Lecture: $subject ($lectureId)',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurface.withOpacity(0.7),
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.black,
                        foregroundColor: Colors.white,
                        shape: const RoundedRectangleBorder(
                          borderRadius: BorderRadius.zero,
                        ),
                      ),
                      icon: const Icon(Icons.check),
                      label: const Text('Mark as ATTENDED'),
                      onPressed: () => _mark(context, 'attended'),
                    ),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        backgroundColor: Colors.white, // 👈 black bg
                        foregroundColor: Colors.black, // 👈 ripple / icon color
                        shape: const RoundedRectangleBorder(
                          // 👈 rectangle, no radius
                          borderRadius: BorderRadius.zero,
                        ),
                      ),
                      icon: const Icon(Icons.close),
                      label: const Text('Mark as MISSED'),
                      onPressed: () => _mark(context, 'missed'),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
