import 'dart:convert';
import 'package:flutter/material.dart';

import 'lecture_home_screen.dart';
import 'confirm_lecture_screen.dart';
import 'services/lecture_notification_service.dart';

final GlobalKey<NavigatorState> navKey = GlobalKey<NavigatorState>();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await LectureNotificationService.instance.init(
    onTap: (payload) {
      if (payload == null) return;
      final data = jsonDecode(payload) as Map<String, dynamic>;
      final lectureId = (data['lectureId'] as String?) ?? 'L1';
      final subject = (data['subject'] as String?) ?? 'Lecture';

      navKey.currentState?.push(
        MaterialPageRoute(
          builder:
              (_) =>
                  ConfirmLectureScreen(lectureId: lectureId, subject: subject),
        ),
      );
    },
  );

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      navigatorKey: navKey,
      debugShowCheckedModeBanner: false,
      // 👈 add this
      title: 'Lecture Attendance Alarm',
      theme: ThemeData(colorSchemeSeed: Colors.blue, useMaterial3: true),
      home: const LectureHomeScreen(),
    );
  }
}
