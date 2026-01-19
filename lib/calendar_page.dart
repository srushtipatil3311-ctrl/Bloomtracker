import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

// ================= COLORS =================
const Color periodColor = Color(0xFFFF6F91);
const Color follicularColor = Color(0xFFC3B1E1);
const Color ovulationColor = Color(0xFF7B5EA7);
const Color lutealColor = Color(0xFFB0A8B9);
const Color bgColor = Color(0xFFF8F1FF);

class CalendarPage extends StatefulWidget {
  const CalendarPage({super.key});

  @override
  State<CalendarPage> createState() => _CalendarPageState();
}

class _CalendarPageState extends State<CalendarPage> {
  // ================= CORE STATE =================
  DateTime focusedMonth = DateTime.now();
  DateTime selectedDate = DateTime.now();

  DateTime lastPeriodStart = DateTime(2026, 1, 20);

  int cycleLength = 45; // PCOS-safe default
  int periodLength = 5;

  bool showWeekly = true;

  final List<int> pastCycleLengths = [];

  // ================= 🔹 ADDED: LOAD FROM FIREBASE =================
  @override
  void initState() {
    super.initState();
    _loadCycleFromFirebase();
  }

  Future<void> _loadCycleFromFirebase() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final doc = await FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .get();

    final data = doc.data();
    if (data == null) return;

    final savedCycle =
    data['cycle']?['userSetCycleLength'];

    if (savedCycle != null && savedCycle is int) {
      setState(() {
        cycleLength = savedCycle;
      });
    }
  }
  // ================= END ADDITION =================

  // ================= HELPERS =================
  bool sameDate(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  int cycleDay(DateTime date) =>
      date.difference(lastPeriodStart).inDays + 1;

  // ================= PHASE LOGIC =================
  String getPhase(DateTime date) {
    final cd = cycleDay(date);
    if (cd <= 0) return "";

    final ovulationDay = cycleLength - 14;

    if (cd <= periodLength) return "Period";
    if (cd < ovulationDay) return "Follicular";
    if (cd == ovulationDay) return "Ovulation";
    if (cd <= cycleLength) return "Luteal";
    return "";
  }

  Color phaseColor(String phase) {
    switch (phase) {
      case "Period":
        return periodColor;
      case "Follicular":
        return follicularColor;
      case "Ovulation":
        return ovulationColor;
      case "Luteal":
        return lutealColor;
      default:
        return Colors.transparent;
    }
  }

  // ================= FUTURE PREDICTION =================
  bool isPredictedPeriod(DateTime date) {
    if (date.isBefore(lastPeriodStart)) return false;

    final diff = date.difference(lastPeriodStart).inDays;
    final cycleIndex = diff ~/ cycleLength;
    final dayInCycle = diff % cycleLength + 1;

    return cycleIndex > 0 && dayInCycle <= periodLength;
  }

  // ================= ACTIONS =================
  void logPeriod() {
    final diff = selectedDate.difference(lastPeriodStart).inDays;

    if (diff >= 21 && diff <= 45) {
      pastCycleLengths.add(diff);
      if (pastCycleLengths.length > 3) {
        pastCycleLengths.removeAt(0);
      }
      cycleLength =
          (pastCycleLengths.reduce((a, b) => a + b) /
              pastCycleLengths.length)
              .round();
    }

    setState(() {
      lastPeriodStart = selectedDate;
    });
  }

  // ================= EDIT CYCLE =================
  Future<void> showEditCycleDialog() async {
    final controller =
    TextEditingController(text: cycleLength.toString());

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Edit Cycle Length"),
        content: TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(
            labelText: "Cycle length (days)",
            hintText: "28 – 45",
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            onPressed: () async {
              final value = int.tryParse(controller.text);
              if (value == null || value < 20 || value > 60) return;

              await FirebaseFirestore.instance
                  .collection('users')
                  .doc(FirebaseAuth.instance.currentUser!.uid)
                  .update({
                'cycle.userSetCycleLength': value,
              });

              setState(() => cycleLength = value);
              Navigator.pop(context);
            },
            child: const Text("Save"),
          ),
        ],
      ),
    );
  }

  void prevMonth() => setState(() =>
  focusedMonth = DateTime(focusedMonth.year, focusedMonth.month - 1));

  void nextMonth() => setState(() =>
  focusedMonth = DateTime(focusedMonth.year, focusedMonth.month + 1));

  // ================= UI =================
  @override
  Widget build(BuildContext context) {
    final daysInMonth =
        DateTime(focusedMonth.year, focusedMonth.month + 1, 0).day;

    final firstWeekday =
        DateTime(focusedMonth.year, focusedMonth.month, 1).weekday;

    const totalCells = 42;
    final weekStart =
    selectedDate.subtract(Duration(days: selectedDate.weekday - 1));

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        title: const Text("My Cycle"),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: showEditCycleDialog,
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // ================= MONTH HEADER =================
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  IconButton(
                      icon: const Icon(Icons.chevron_left),
                      onPressed: prevMonth),
                  Text(
                    DateFormat.yMMMM().format(focusedMonth),
                    style: const TextStyle(
                        fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  IconButton(
                      icon: const Icon(Icons.chevron_right),
                      onPressed: nextMonth),
                ],
              ),
            ),

            // ================= WEEKDAYS =================
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text("Mon"),
                  Text("Tue"),
                  Text("Wed"),
                  Text("Thu"),
                  Text("Fri"),
                  Text("Sat"),
                  Text("Sun"),
                ],
              ),
            ),

            // ================= CALENDAR =================
            SizedBox(
              height: 330,
              child: GridView.builder(
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate:
                const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 7,
                ),
                itemCount: totalCells,
                itemBuilder: (_, index) {
                  final day = index - (firstWeekday - 1) + 1;
                  if (day < 1 || day > daysInMonth) return const SizedBox();

                  final date = DateTime(
                      focusedMonth.year, focusedMonth.month, day);

                  final phase = getPhase(date);
                  final predicted = isPredictedPeriod(date);
                  final selected = sameDate(date, selectedDate);

                  return GestureDetector(
                    onTap: () => setState(() => selectedDate = date),
                    child: Column(
                      children: [
                        Container(
                          width: 36,
                          height: 36,
                          decoration: BoxDecoration(
                            color: phaseColor(phase),
                            shape: BoxShape.circle,
                            border: predicted
                                ? Border.all(color: periodColor, width: 2)
                                : selected
                                ? Border.all(
                                color: Colors.black, width: 2)
                                : null,
                          ),
                          child: Center(
                            child: Text(
                              "$day",
                              style: const TextStyle(
                                color: Color(0xFF6A1B9A),
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          predicted ? "Predicted" : phase,
                          style: const TextStyle(fontSize: 8),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),

            const SizedBox(height: 12),

            // ================= TOGGLE =================
            ToggleButtons(
              isSelected: [showWeekly, !showWeekly],
              onPressed: (i) => setState(() => showWeekly = i == 0),
              borderRadius: BorderRadius.circular(20),
              children: const [
                Padding(
                    padding: EdgeInsets.symmetric(horizontal: 16),
                    child: Text("Weekly")),
                Padding(
                    padding: EdgeInsets.symmetric(horizontal: 16),
                    child: Text("Monthly")),
              ],
            ),

            const SizedBox(height: 16),

            // ================= GRAPH =================
            SizedBox(
              height: 80,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: showWeekly
                    ? Row(
                  mainAxisAlignment:
                  MainAxisAlignment.spaceBetween,
                  children: List.generate(7, (i) {
                    final d = weekStart.add(Duration(days: i));
                    return Column(
                      children: [
                        Container(
                          width: 14,
                          height: 48,
                          decoration: BoxDecoration(
                            color: phaseColor(getPhase(d)),
                            borderRadius:
                            BorderRadius.circular(8),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(DateFormat.E().format(d),
                            style:
                            const TextStyle(fontSize: 10)),
                      ],
                    );
                  }),
                )
                    : ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: daysInMonth,
                  itemBuilder: (_, i) {
                    final d = DateTime(focusedMonth.year,
                        focusedMonth.month, i + 1);
                    return Container(
                      width: 10,
                      margin:
                      const EdgeInsets.symmetric(horizontal: 4),
                      decoration: BoxDecoration(
                        color: phaseColor(getPhase(d)),
                        borderRadius: BorderRadius.circular(6),
                      ),
                    );
                  },
                ),
              ),
            ),

            const SizedBox(height: 16),

            // ================= LEGEND =================
            Wrap(
              alignment: WrapAlignment.center,
              spacing: 16,
              runSpacing: 8,
              children: const [
                _LegendItem(periodColor, "Period"),
                _LegendItem(follicularColor, "Follicular"),
                _LegendItem(ovulationColor, "Ovulation"),
                _LegendItem(lutealColor, "Luteal"),
                _LegendItem(periodColor, "Predicted", outlined: true),
              ],
            ),

            const SizedBox(height: 16),

            // ================= BUTTON =================
            Padding(
              padding: const EdgeInsets.all(16),
              child: ElevatedButton(
                onPressed: logPeriod,
                style: ElevatedButton.styleFrom(
                  backgroundColor: periodColor,
                  minimumSize: const Size(double.infinity, 48),
                ),
                child: const Text("Log Period"),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ================= LEGEND ITEM =================
class _LegendItem extends StatelessWidget {
  final Color color;
  final String label;
  final bool outlined;

  const _LegendItem(this.color, this.label, {this.outlined = false});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: outlined ? Colors.transparent : color,
            border:
            outlined ? Border.all(color: color, width: 2) : null,
          ),
        ),
        const SizedBox(width: 6),
        Text(label, style: const TextStyle(fontSize: 12)),
      ],
    );
  }
}
