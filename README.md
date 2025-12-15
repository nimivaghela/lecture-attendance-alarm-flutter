# lecture-attendance-alarm-flutter
Flutter Android app that lets students set daily lecture alarms with full-screen notifications and track attendance (attended/missed) over time.

# Lecture Attendance Alarm (Flutter)

A Flutter Android app that lets students:

- Set up to **3 daily lectures** with custom names and times  
- Get **full-screen alarm-style notifications** at each lecture time  
- Mark each lecture as **Attended** or **Missed**  
- View simple **attendance stats** per lecture over time  

Designed for **India / Ahmedabad** timezone (IST, `Asia/Kolkata`) and tested on **Android 14+**.

---

## Features

- 🎓 Custom lecture names (e.g. “Maths”, “Computer Science”)  
- ⏰ Daily alarms at exact hour:minute (minute-based logic)  
- 🔔 Full-screen alarm-style notification with custom sound  
- 🛑 “Stop alarm” button directly in the notification  
- ✅ Tapping the notification opens a **Confirm** dialog:
  - Mark as **ATTENDED**
  - Mark as **MISSED**
- 📊 Attendance stats screen:
  - Attended / Missed count per lecture
  - Simple percentage for each lecture
- 💾 All data stored locally using `shared_preferences`
- 🌏 Timezone fixed to `Asia/Kolkata` (India / Ahmedabad)

---

## Tech Stack

- **Flutter** (Dart)
- **Android** (Android 14+ / API 34 target)
- Packages:
  - [`flutter_local_notifications`](https://pub.dev/packages/flutter_local_notifications)
  - [`timezone`](https://pub.dev/packages/timezone)
  - [`shared_preferences`](https://pub.dev/packages/shared_preferences)

---

## Getting Started

### 1. Clone the repo

```bash
git clone https://github.com/<your-username>/lecture-attendance-alarm-flutter.git
cd lecture-attendance-alarm-flutter


## License

This project is licensed under the MIT License – see the [LICENSE](LICENSE) file for details.


