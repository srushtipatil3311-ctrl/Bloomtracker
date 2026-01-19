import 'package:cloud_firestore/cloud_firestore.dart';

class CycleUtils {
  final DateTime lastPeriodDate;
  final int cycleLength;
  final int periodLength;

  CycleUtils({
    required this.lastPeriodDate,
    this.cycleLength = 28,
    this.periodLength = 5,
  });

  int getCycleDay(DateTime date) {
    final diff = date.difference(lastPeriodDate).inDays;
    return (diff % cycleLength) + 1;
  }

  String getPhaseName(DateTime date) {
    final day = getCycleDay(date);

    if (day <= periodLength) {
      return 'Menstrual Phase';
    } else if (day <= 13) {
      return 'Follicular Phase';
    } else if (day <= 15) {
      return 'Ovulation Phase';
    } else {
      return 'Luteal Phase';
    }
  }

  String getDailyTip(DateTime date) {
    final phase = getPhaseName(date);

    switch (phase) {
      case 'Menstrual Phase':
        return 'Rest more, stay hydrated, and eat iron-rich foods.';
      case 'Follicular Phase':
        return 'Great time to start new habits and light workouts.';
      case 'Ovulation Phase':
        return 'You may feel confident and energetic today.';
      case 'Luteal Phase':
        return 'Slow down and focus on self-care.';
      default:
        return '';
    }
  }
}
