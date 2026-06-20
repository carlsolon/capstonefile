import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'firebase_options.dart';
import 'weekly_sleep_screen.dart';
import 'monthly_sleep_screen.dart';
import 'package:table_calendar/table_calendar.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  runApp(const MaterialApp(
    debugShowCheckedModeBanner: false,
    home: SleepSessionScreen(),
  ));
}

class SleepSessionScreen extends StatefulWidget {
  const SleepSessionScreen({super.key});

  @override
  State<SleepSessionScreen> createState() => _SleepSessionScreenState();
}

class _SleepSessionScreenState extends State<SleepSessionScreen> {

  int selectedDayIndex = DateTime.now().weekday % 7;
  DateTime selectedDate = DateTime.now();

  // ✅ ADDED ONLY
  final Map<String, Map<String, dynamic>> _deletedCache = {};

  bool isSameSelectedDay(Timestamp ts) {
    final date = ts.toDate();
    return date.year == selectedDate.year &&
        date.month == selectedDate.month &&
        date.day == selectedDate.day;
  }

  // ✅ ADDED ONLY (DELETE + UNDO LOGIC)
Future<void> deleteWithUndo(String docId, Map<String, dynamic> data) async {
  _deletedCache[docId] = data;

  await FirebaseFirestore.instance
      .collection("vibrator_logs")
      .doc(docId)
      .delete();

  if (!mounted) return;

  ScaffoldMessenger.of(context).clearSnackBars();

  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: const Text("Deleted"),
      duration: const Duration(seconds: 3), // ⬅️ auto close after 3 sec
      action: SnackBarAction(
        label: "UNDO",
        onPressed: () async {
          final restored = _deletedCache[docId];

          if (restored != null) {
            await FirebaseFirestore.instance
                .collection("vibrator_logs")
                .doc(docId)
                .set(restored);

            _deletedCache.remove(docId);
          }
        },
      ),
    ),
  );

  // ⬅️ after 3 seconds, remove undo data (prevents restore after timeout)
  Future.delayed(const Duration(seconds: 3), () {
    _deletedCache.remove(docId);
  });
} 

  @override
  Widget build(BuildContext context) {
    DateTime now = DateTime.now();

    return Scaffold(
      backgroundColor: const Color(0xFF09042F),

      body: SafeArea(
        child: StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance
              .collection("vibrator_logs")
              .orderBy("timestamp", descending: true)
              .snapshots(),

          builder: (context, snapshot) {
            if (!snapshot.hasData) {
              return const Center(
                child: CircularProgressIndicator(color: Colors.cyanAccent),
              );
            }

            final docs = snapshot.data!.docs;

            final sessionLogs = docs.where((doc) {
              final data = doc.data() as Map<String, dynamic>;
              if (data["type"] != "session") return false;
              if (data["timestamp"] == null) return false;
              return isSameSelectedDay(data["timestamp"]);
            }).toList();

            final timerLogs = docs.where((doc) {
              final data = doc.data() as Map<String, dynamic>;
              if (data["type"] != "timer") return false;
              if (data["timestamp"] == null) return false;
              return isSameSelectedDay(data["timestamp"]);
            }).toList();

            final sleepLogs = docs.where((doc) {
              final data = doc.data() as Map<String, dynamic>;
              if (data["type"] != "sleep") return false;
              if (data["sleep_start"] == null) return false;
              return isSameSelectedDay(data["sleep_start"]);
            }).toList();

            return ListView(
              padding: const EdgeInsets.all(20),
              children: [

                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [

                    GestureDetector(
                      onTap: () => Navigator.pop(context),
                      child: Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(.05),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(Icons.arrow_back_ios_new,
                            color: Colors.white),
                      ),
                    ),

                    Row(
                      children: [

                        GestureDetector(
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) =>
                                    const WeeklySleepScreen(),
                              ),
                            );
                          },
                          child: _iconButton(Icons.calendar_view_week),
                        ),

                        GestureDetector(
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) =>
                                    const MonthlySleepScreen(),
                              ),
                            );
                          },
                          child: _iconButton(Icons.calendar_month),
                        ),

                        GestureDetector(
                          onTap: () {
                            showModalBottomSheet(
                              context: context,
                              backgroundColor: const Color(0xFF09042F),
                              isScrollControlled: true,
                              shape: const RoundedRectangleBorder(
                                borderRadius: BorderRadius.vertical(
                                  top: Radius.circular(25),
                                ),
                              ),
                              builder: (_) => const CalendarOverlay(),
                            );
                          },
                          child: _iconButton(Icons.calendar_today),
                        ),
                      ],
                    ),
                  ],
                ),

                const SizedBox(height: 10),

                Text(
                  DateFormat('EEEE').format(now),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 38,
                    fontWeight: FontWeight.bold,
                  ),
                ),

                const SizedBox(height: 5),

                Text(
                  DateFormat('MMMM d, y').format(now),
                  style: TextStyle(
                    color: Colors.white.withOpacity(.7),
                    fontSize: 17,
                  ),
                ),

                const SizedBox(height: 25),

                SizedBox(
                  height: 62,
                  child: ListView(
                    scrollDirection: Axis.horizontal,
                    children: [
                      buildDay("Sun", 0),
                      buildDay("Mon", 1),
                      buildDay("Tue", 2),
                      buildDay("Wed", 3),
                      buildDay("Thu", 4),
                      buildDay("Fri", 5),
                      buildDay("Sat", 6),
                    ],
                  ),
                ),

                const SizedBox(height: 30),

                const Text("Session History",
                    style: TextStyle(color: Colors.white, fontSize: 22)),

                const SizedBox(height: 18),

                ...sessionLogs.map((doc) => buildSessionCard(doc)),

                const SizedBox(height: 25),

                const Text("Timer Logs",
                    style: TextStyle(color: Colors.white, fontSize: 22)),

                const SizedBox(height: 18),

                ...timerLogs.map((doc) => buildTimerCard(doc)),

                const SizedBox(height: 25),

                const Text("Sleep Sessions",
                    style: TextStyle(color: Colors.white, fontSize: 22)),

                const SizedBox(height: 18),

                ...sleepLogs.map((doc) => buildSleepCard(doc)),
              ],
            );
          },
        ),
      ),
    );
  }

  // ================= ICON =================
  Widget _iconButton(IconData icon) {
    return Container(
      margin: const EdgeInsets.only(right: 10),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(.05),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Icon(icon, color: Colors.white, size: 24),
    );
  }

  // ================= DAY =================
  Widget buildDay(String text, int index) {
    final todayIndex = DateTime.now().weekday % 7;
    final isSelected = selectedDayIndex == index;
    final isToday = todayIndex == index;

    return GestureDetector(
      onTap: () {
        setState(() {
          selectedDayIndex = index;
          DateTime now = DateTime.now();
          int diff = index - (now.weekday % 7);
          selectedDate = now.add(Duration(days: diff));
        });
      },
      child: Container(
        width: 80,
        margin: const EdgeInsets.only(right: 12),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(18),
          gradient: isSelected
              ? const LinearGradient(
                  colors: [Color(0xFF6B5BFF), Color(0xFF24E0FF)],
                )
              : isToday
                  ? LinearGradient(
                      colors: [
                        Colors.white.withOpacity(0.15),
                        Colors.white.withOpacity(0.05),
                      ],
                    )
                  : null,
          border: Border.all(color: Colors.white24),
        ),
        child: Center(
          child: Text(text,
              style: const TextStyle(color: Colors.white, fontSize: 18)),
        ),
      ),
    );
  }

  // ================= SESSION CARD (UNCHANGED + WRAPPED) =================
  Widget buildSessionCard(QueryDocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;

    final start = data["start_time"];
    final end = data["end_time"];
    final duration = data["duration"] ?? 0;

    DateTime? startTime =
        start is Timestamp ? start.toDate() : null;

    DateTime? endTime =
        end is Timestamp ? end.toDate() : null;

    return Dismissible(
      key: Key(doc.id),
      direction: DismissDirection.endToStart,
      background: Container(
        margin: const EdgeInsets.only(bottom: 20),
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        decoration: BoxDecoration(
          color: Colors.red,
          borderRadius: BorderRadius.circular(30),
        ),
        child: const Icon(Icons.delete, color: Colors.white),
      ),
      onDismissed: (_) => deleteWithUndo(doc.id, data),

      child: Container(
        margin: const EdgeInsets.only(bottom: 20),
        padding: const EdgeInsets.all(22),
        decoration: BoxDecoration(
          color: const Color(0xFF1B154B),
          borderRadius: BorderRadius.circular(30),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text("Sleep Session Summary",
                style: TextStyle(color: Colors.white, fontSize: 22)),

            const SizedBox(height: 20),

            Text("$duration sec",
                style: const TextStyle(color: Colors.white, fontSize: 32)),

            const SizedBox(height: 20),

            buildInfoRow(Icons.nightlight, "Start",
                startTime != null
                    ? DateFormat('hh:mm a').format(startTime)
                    : "-"),

            buildInfoRow(Icons.wb_sunny, "End",
                endTime != null
                    ? DateFormat('hh:mm a').format(endTime)
                    : "-"),
          ],
        ),
      ),
    );
  }

  // ================= TIMER CARD =================
  Widget buildTimerCard(QueryDocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    final duration = data["duration"] ?? 0;

    return Dismissible(
      key: Key(doc.id),
      direction: DismissDirection.endToStart,
      background: Container(
        margin: const EdgeInsets.only(bottom: 20),
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        decoration: BoxDecoration(
          color: Colors.red,
          borderRadius: BorderRadius.circular(28),
        ),
        child: const Icon(Icons.delete, color: Colors.white),
      ),
      onDismissed: (_) => deleteWithUndo(doc.id, data),

      child: Container(
        margin: const EdgeInsets.only(bottom: 20),
        padding: const EdgeInsets.all(22),
        decoration: BoxDecoration(
          color: const Color(0xFF1B154B),
          borderRadius: BorderRadius.circular(28),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text("Timer Session",
                style: TextStyle(color: Colors.white, fontSize: 22)),

            const SizedBox(height: 15),

            buildInfoRow(Icons.timer, "Duration", "$duration sec"),
          ],
        ),
      ),
    );
  }

  // ================= SLEEP CARD =================
  Widget buildSleepCard(QueryDocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;

    final start = data["sleep_start"];
    final end = data["sleep_end"];
    final duration = data["sleep_duration_minutes"] ?? 0;

    DateTime? startTime =
        start is Timestamp ? start.toDate() : null;

    DateTime? endTime =
        end is Timestamp ? end.toDate() : null;

    return Dismissible(
      key: Key(doc.id),
      direction: DismissDirection.endToStart,
      background: Container(
        margin: const EdgeInsets.only(bottom: 20),
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        decoration: BoxDecoration(
          color: Colors.red,
          borderRadius: BorderRadius.circular(30),
        ),
        child: const Icon(Icons.delete, color: Colors.white),
      ),
      onDismissed: (_) => deleteWithUndo(doc.id, data),

      child: Container(
        margin: const EdgeInsets.only(bottom: 20),
        padding: const EdgeInsets.all(22),
        decoration: BoxDecoration(
          color: const Color(0xFF1B154B),
          borderRadius: BorderRadius.circular(30),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text("Sleep Session",
                style: TextStyle(color: Colors.white, fontSize: 22)),

            const SizedBox(height: 20),

            Text("${duration ~/ 60}h ${duration % 60}m",
                style: const TextStyle(color: Colors.white, fontSize: 32)),

            const SizedBox(height: 20),

            buildInfoRow(Icons.nightlight, "Start",
                startTime != null
                    ? DateFormat('hh:mm a').format(startTime)
                    : "-"),

            buildInfoRow(Icons.wb_sunny, "End",
                endTime != null
                    ? DateFormat('hh:mm a').format(endTime)
                    : "-"),
          ],
        ),
      ),
    );
  }

  Widget buildInfoRow(IconData icon, String title, String value) {
    return Row(
      children: [
        Icon(icon, color: Colors.cyanAccent),
        const SizedBox(width: 12),
        Expanded(
          child: Text(title,
              style: const TextStyle(color: Colors.white)),
        ),
        Text(value,
            style: const TextStyle(
                color: Colors.white, fontWeight: FontWeight.bold)),
      ],
    );
  }
}

// ================= CALENDAR =================
class CalendarOverlay extends StatefulWidget {
  const CalendarOverlay({super.key});

  @override
  State<CalendarOverlay> createState() => _CalendarOverlayState();
}

class _CalendarOverlayState extends State<CalendarOverlay> {
  DateTime focusedDay = DateTime.now();
  DateTime? selectedDay;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      height: MediaQuery.of(context).size.height * 0.85,
      child: TableCalendar(
        firstDay: DateTime.utc(2020),
        lastDay: DateTime.utc(2035),
        focusedDay: focusedDay,
        selectedDayPredicate: (day) => isSameDay(selectedDay, day),
        onDaySelected: (selected, focused) {
          setState(() {
            selectedDay = selected;
            focusedDay = focused;
          });
        },
        calendarStyle: const CalendarStyle(
          defaultTextStyle: TextStyle(color: Colors.white),
          weekendTextStyle: TextStyle(color: Colors.cyanAccent),
          selectedDecoration: BoxDecoration(
            color: Colors.cyanAccent,
            shape: BoxShape.circle,
          ),
          todayDecoration: BoxDecoration(
            color: Colors.deepPurpleAccent,
            shape: BoxShape.circle,
          ),
        ),
      ),
    );
  }
}