// import 'package:flutter/material.dart';
// import 'package:intl/intl.dart';
// import 'package:firebase_core/firebase_core.dart';
// import 'package:cloud_firestore/cloud_firestore.dart';
// import 'firebase_options.dart';

// void main() async {
//   WidgetsFlutterBinding.ensureInitialized();

//   await Firebase.initializeApp(
//     options: DefaultFirebaseOptions.currentPlatform,
//   );

//   runApp(const MaterialApp(
//     debugShowCheckedModeBanner: false,
//     home: SleepSessionScreen(),
//   ));
// }

// class SleepSessionScreen extends StatelessWidget {
//   const SleepSessionScreen({super.key});

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       backgroundColor: const Color(0xFF0A0734),
//       appBar: AppBar(
//         backgroundColor: Colors.transparent,
//         title: const Text("History"),
//         centerTitle: true,
//       ),

//       body: StreamBuilder<QuerySnapshot>(
//         stream: FirebaseFirestore.instance
//             .collection("vibrator_logs")
//             .orderBy("timestamp", descending: true)
//             .snapshots(),

//         builder: (context, snapshot) {
//           if (!snapshot.hasData) {
//             return const Center(
//               child: CircularProgressIndicator(
//                 color: Colors.cyanAccent,
//               ),
//             );
//           }

//           final docs = snapshot.data!.docs;

//           final sessionLogs = docs.where((doc) {
//             final data = doc.data() as Map<String, dynamic>;
//             return data["type"] == "session";
//           }).toList();

//           final timerLogs = docs.where((doc) {
//             final data = doc.data() as Map<String, dynamic>;
//             return data["type"] == "timer";
//           }).toList();

//           return ListView(
//             padding: const EdgeInsets.all(12),
//             children: [
//               const Text(
//                 "🟢 Session History",
//                 style: TextStyle(
//                   color: Colors.greenAccent,
//                   fontSize: 18,
//                   fontWeight: FontWeight.bold,
//                 ),
//               ),

//               const SizedBox(height: 10),

//               ...sessionLogs.map((doc) => buildSessionCard(doc, context)),

//               const SizedBox(height: 25),

//               const Text(
//                 "🔵 Timer Logs",
//                 style: TextStyle(
//                   color: Colors.blueAccent,
//                   fontSize: 18,
//                   fontWeight: FontWeight.bold,
//                 ),
//               ),

//               const SizedBox(height: 10),

//               ...timerLogs.map((doc) => buildTimerCard(doc, context)),
//             ],
//           );
//         },
//       ),
//     );
//   }

//   // ================= SESSION CARD =================
//   Widget buildSessionCard(QueryDocumentSnapshot doc, BuildContext context) {
//     final data = doc.data() as Map<String, dynamic>;

//     final start = data["start_time"];
//     final end = data["end_time"];
//     final duration = data["duration"] ?? 0;
//     final status = data["status"] ?? "unknown";

//     DateTime? startTime =
//         start is Timestamp ? start.toDate() : null;

//     DateTime? endTime =
//         end is Timestamp ? end.toDate() : null;

//     return Dismissible(
//       key: Key(doc.id),
//       direction: DismissDirection.endToStart,

//       onDismissed: (direction) async {
//         await FirebaseFirestore.instance
//             .collection("vibrator_logs")
//             .doc(doc.id)
//             .delete();

//         ScaffoldMessenger.of(context).showSnackBar(
//           const SnackBar(content: Text("Session deleted")),
//         );
//       },

//       background: Container(
//         alignment: Alignment.centerRight,
//         padding: const EdgeInsets.only(right: 20),
//         color: Colors.redAccent,
//         child: const Icon(Icons.delete, color: Colors.white),
//       ),

//       child: Container(
//         margin: const EdgeInsets.symmetric(vertical: 8),
//         padding: const EdgeInsets.all(16),
//         decoration: BoxDecoration(
//           color: const Color(0xFF1E1B48),
//           borderRadius: BorderRadius.circular(18),
//         ),
//         child: Column(
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: [
//             Text(
//               "SESSION - ${status.toUpperCase()}",
//               style: const TextStyle(
//                 color: Colors.greenAccent,
//                 fontWeight: FontWeight.bold,
//               ),
//             ),

//             const SizedBox(height: 10),

//             Text("Duration: $duration sec",
//                 style: const TextStyle(color: Colors.white)),

                

// Text(
//   "Vibration: ${((data["final_vibration_level"] ?? 0) is double
//     ? ((data["final_vibration_level"] ?? 0) * 100).round()
//     : data["final_vibration_level"] ?? 0)}%",
//   style: const TextStyle(color: Colors.white),
// ),

//             Text(
//               "Start: ${startTime != null ? DateFormat('hh:mm a').format(startTime) : '-'}",
//               style: const TextStyle(color: Colors.white70),
//             ),

//             Text(
//               "End: ${endTime != null ? DateFormat('hh:mm a').format(endTime) : '-'}",
//               style: const TextStyle(color: Colors.white70),
//             ),
//           ],
//         ),
//       ),
//     );
//   }

//   // ================= TIMER CARD =================
// Widget buildTimerCard(QueryDocumentSnapshot doc, BuildContext context) {
//   final data = doc.data() as Map<String, dynamic>;

//   final duration = data["duration"] ?? 0;
//   final setTime = data["set_time"];
//   final end = data["end_time"];

//   DateTime? time =
//       setTime is Timestamp ? setTime.toDate() : null;

//   DateTime? endTime =
//       end is Timestamp ? end.toDate() : null;

//   return Dismissible(
//     key: Key(doc.id),
//     direction: DismissDirection.endToStart,

//     onDismissed: (direction) async {
//       await FirebaseFirestore.instance
//           .collection("vibrator_logs")
//           .doc(doc.id)
//           .delete();

//       ScaffoldMessenger.of(context).showSnackBar(
//         const SnackBar(content: Text("Timer deleted")),
//       );
//     },

//     background: Container(
//       alignment: Alignment.centerRight,
//       padding: const EdgeInsets.only(right: 20),
//       color: Colors.redAccent,
//       child: const Icon(Icons.delete, color: Colors.white),
//     ),

//     child: Container(
//       margin: const EdgeInsets.symmetric(vertical: 8),
//       padding: const EdgeInsets.all(16),
//       decoration: BoxDecoration(
//         color: const Color(0xFF1B154B),
//         borderRadius: BorderRadius.circular(18),
//       ),

//       child: Column(
//         crossAxisAlignment: CrossAxisAlignment.start,
//         children: [
//           const Text(
//             "TIMER",
//             style: TextStyle(
//               color: Colors.blueAccent,
//               fontWeight: FontWeight.bold,
//             ),
//           ),

//           const SizedBox(height: 10),

//           Text(
//             "Duration: $duration sec",
//             style: const TextStyle(color: Colors.white),
//           ),

//           const SizedBox(height: 6),

//           Text(
//             "Set at: ${time != null ? DateFormat('hh:mm a').format(time) : '-'}",
//             style: const TextStyle(color: Colors.white70),
//           ),

//           const SizedBox(height: 6),

//           Text(
//             "End at: ${endTime != null ? DateFormat('hh:mm a').format(endTime) : '-'}",
//             style: const TextStyle(color: Colors.white70),
//           ),

//           const SizedBox(height: 6),

//           // OPTIONAL: vibration level (if you save it in timer logs)
//           Text(
//             "Vibration: ${data["vibration_level"] ?? 0}%",
//             style: const TextStyle(color: Colors.white),
//           ),
//         ],
//       ),
//     ),
//   );
// }
// }
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

  // ✅ CLICKABLE DAYS STATE
int selectedDayIndex = DateTime.now().weekday % 7;
DateTime selectedDate = DateTime.now();

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
                child: CircularProgressIndicator(
                  color: Colors.cyanAccent,
                ),
              );
            }

            final docs = snapshot.data!.docs;

            final sessionLogs = docs.where((doc) {
  final data = doc.data() as Map<String, dynamic>;

  if (data["type"] != "session") return false;

  final Timestamp ts = data["timestamp"];
  final date = ts.toDate();

  return date.year == selectedDate.year &&
         date.month == selectedDate.month &&
         date.day == selectedDate.day;
}).toList();

            final timerLogs = docs.where((doc) {
  final data = doc.data() as Map<String, dynamic>;

  if (data["type"] != "timer") return false;

  final Timestamp ts = data["timestamp"];
  final date = ts.toDate();

  return date.year == selectedDate.year &&
         date.month == selectedDate.month &&
         date.day == selectedDate.day;
}).toList();

            return ListView(
              padding: const EdgeInsets.all(20),
              children: [

                // ================= TOP =================
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [

                    GestureDetector(
                      onTap: () => Navigator.pop(context),
                      child: Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: .05),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(
                          Icons.arrow_back_ios_new,
                          color: Colors.white,
                          size: 20,
                        ),
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
                          child: Container(
                            margin: const EdgeInsets.only(right: 10),
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: .05),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Icon(
                              Icons.calendar_view_week,
                              color: Colors.white,
                              size: 24,
                            ),
                          ),
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
                          child: Container(
                            margin: const EdgeInsets.only(right: 10),
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: .05),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Icon(
                              Icons.calendar_month,
                              color: Colors.white,
                              size: 24,
                            ),
                          ),
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
                          child: Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: .05),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Icon(
                              Icons.calendar_month_rounded,
                              color: Colors.white,
                              size: 24,
                            ),
                          ),
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
                    color: Colors.white.withValues(alpha: .7),
                    fontSize: 17,
                  ),
                ),

                const SizedBox(height: 25),

                // ================= DAYS (REAL TIME + CLICKABLE) =================
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

                const Text(
                  "Session History",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),

                const SizedBox(height: 18),

                ...sessionLogs.map((doc) =>
                    buildSessionCard(doc, context)),

                const SizedBox(height: 25),

                const Text(
                  "Timer Logs",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),

                const SizedBox(height: 18),

                ...timerLogs.map((doc) =>
                    buildTimerCard(doc, context)),
              ],
            );
          },
        ),
      ),
    );
  }

  // ================= DAYS (CLICKABLE + REAL TIME) =================
  Widget buildDay(String text, int index) {
    final todayIndex = DateTime.now().weekday % 7;

    final isSelected = selectedDayIndex == index;
    final isToday = todayIndex == index;

    return GestureDetector(
      onTap: () {
  setState(() {
    selectedDayIndex = index;

    // convert index → actual weekday date
    DateTime now = DateTime.now();
    int difference = index - (now.weekday % 7);
    selectedDate = now.add(Duration(days: difference));
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
                        Colors.white.withValues(alpha: 0.15),
                        Colors.white.withValues(alpha: 0.05),
                      ],
                    )
                  : null,

          border: Border.all(
            color: isSelected ? Colors.cyanAccent : Colors.white24,
          ),
        ),
        child: Center(
          child: Text(
            text,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w600,
              fontSize: 18,
            ),
          ),
        ),
      ),
    );
  }

  // ================= SESSION CARD =================
  Widget buildSessionCard(QueryDocumentSnapshot doc, BuildContext context) {
    final data = doc.data() as Map<String, dynamic>;

    final start = data["start_time"];
    final end = data["end_time"];
    final duration = data["duration"] ?? 0;

    final vibration =
        ((data["final_vibration_level"] ?? 0) is double)
            ? ((data["final_vibration_level"] ?? 0) * 100).round()
            : data["final_vibration_level"] ?? 0;

    DateTime? startTime =
        start is Timestamp ? start.toDate() : null;

    DateTime? endTime =
        end is Timestamp ? end.toDate() : null;

    final hours = duration ~/ 3600;
    final minutes = (duration % 3600) ~/ 60;
    final seconds = duration % 60;

    return Dismissible(
      key: Key(doc.id),
      direction: DismissDirection.endToStart,
      onDismissed: (_) async {
        await FirebaseFirestore.instance
            .collection("vibrator_logs")
            .doc(doc.id)
            .delete();
      },
      background: Container(
        margin: const EdgeInsets.only(bottom: 18),
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 25),
        decoration: BoxDecoration(
          color: Colors.redAccent,
          borderRadius: BorderRadius.circular(28),
        ),
        child: const Icon(Icons.delete, color: Colors.white),
      ),
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

            const Text(
              "Sleep Session Summary",
              style: TextStyle(
                color: Colors.white,
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 30),

            Center(
              child: Column(
                children: [
                  Text(
                    "${hours}h ${minutes}m ${seconds}s",
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 48,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    "Sleep Duration",
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: .7),
                      fontSize: 18,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 35),

            buildInfoRow(Icons.nightlight_round, "Start",
                startTime != null
                    ? DateFormat('hh:mm a').format(startTime)
                    : "-"),

            const SizedBox(height: 18),

            buildInfoRow(Icons.wb_sunny_rounded, "Wake",
                endTime != null
                    ? DateFormat('hh:mm a').format(endTime)
                    : "-"),

            const SizedBox(height: 18),

            buildInfoRow(Icons.thermostat, "Temperature", "38°C"),

            const SizedBox(height: 18),

            buildInfoRow(Icons.vibration, "Vibration", "$vibration%"),
          ],
        ),
      ),
    );
  }

  // ================= TIMER CARD =================
  Widget buildTimerCard(QueryDocumentSnapshot doc, BuildContext context) {
    final data = doc.data() as Map<String, dynamic>;

    final duration = data["duration"] ?? 0;
    final setTime = data["set_time"];
    final end = data["end_time"];

    DateTime? time =
        setTime is Timestamp ? setTime.toDate() : null;

    DateTime? endTime =
        end is Timestamp ? end.toDate() : null;

    return Dismissible(
      key: Key(doc.id),
      direction: DismissDirection.endToStart,
      onDismissed: (_) async {
        await FirebaseFirestore.instance
            .collection("vibrator_logs")
            .doc(doc.id)
            .delete();
      },
      background: Container(
        margin: const EdgeInsets.only(bottom: 18),
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 25),
        decoration: BoxDecoration(
          color: Colors.redAccent,
          borderRadius: BorderRadius.circular(28),
        ),
        child: const Icon(Icons.delete, color: Colors.white),
      ),
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

            const Text(
              "Timer Session",
              style: TextStyle(
                color: Colors.white,
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 25),

            buildInfoRow(Icons.timer, "Duration", "$duration sec"),

            const SizedBox(height: 18),

            buildInfoRow(Icons.access_time, "Set At",
                time != null ? DateFormat('hh:mm a').format(time) : "-"),

            const SizedBox(height: 18),

            buildInfoRow(Icons.alarm, "End At",
                endTime != null ? DateFormat('hh:mm a').format(endTime) : "-"),

            const SizedBox(height: 18),

            buildInfoRow(Icons.vibration, "Vibration",
                "${data["vibration_level"] ?? 0}%"),
          ],
        ),
      ),
    );
  }

  Widget buildInfoRow(IconData icon, String title, String value) {
    return Row(
      children: [
        Container(
          height: 52,
          width: 52,
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: .08),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Icon(icon, color: const Color(0xFF25E5FF)),
        ),
        const SizedBox(width: 18),
        Expanded(
          child: Text(
            title,
            style: const TextStyle(color: Colors.white, fontSize: 18),
          ),
        ),
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }
}

// ================= CALENDAR OVERLAY =================
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [

          const Text(
            "Sleep Calendar",
            style: TextStyle(
              color: Colors.white,
              fontSize: 22,
              fontWeight: FontWeight.bold,
            ),
          ),

          const SizedBox(height: 20),

          TableCalendar(
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
            headerStyle: const HeaderStyle(
              titleTextStyle: TextStyle(color: Colors.white),
              formatButtonVisible: false,
              leftChevronIcon: Icon(Icons.chevron_left, color: Colors.white),
              rightChevronIcon: Icon(Icons.chevron_right, color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }
}