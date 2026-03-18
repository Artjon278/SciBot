import 'package:flutter/material.dart';

class ActivityCalendar extends StatelessWidget {
  final Map<String, int> activityData;

  const ActivityCalendar({super.key, required this.activityData});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final now = DateTime.now();

    final weeks = <List<_DayData>>[];
    var currentWeek = <_DayData>[];

    for (int i = 29; i >= 0; i--) {
      final date = now.subtract(Duration(days: i));
      final dateStr = '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
      final count = activityData[dateStr] ?? 0;

      if (currentWeek.length == 7) {
        weeks.add(currentWeek);
        currentWeek = [];
      }
      currentWeek.add(_DayData(date: date, count: count));
    }
    if (currentWeek.isNotEmpty) weeks.add(currentWeek);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Aktiviteti i 30 ditëve',
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            Row(
              children: [
                Text('Pak', style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.secondary, fontSize: 10,
                )),
                const SizedBox(width: 4),
                ...List.generate(4, (i) => Container(
                  width: 10,
                  height: 10,
                  margin: const EdgeInsets.symmetric(horizontal: 1),
                  decoration: BoxDecoration(
                    color: _getColor(i + 1, isDark),
                    borderRadius: BorderRadius.circular(2),
                  ),
                )),
                const SizedBox(width: 4),
                Text('Shumë', style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.secondary, fontSize: 10,
                )),
              ],
            ),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: weeks.map((week) {
            return Column(
              children: week.map((day) {
                return Tooltip(
                  message: '${day.date.day}/${day.date.month}: ${day.count} aktivitete',
                  child: Container(
                    width: 14,
                    height: 14,
                    margin: const EdgeInsets.all(1.5),
                    decoration: BoxDecoration(
                      color: day.count == 0
                          ? (isDark ? Colors.white.withOpacity(0.06) : Colors.black.withOpacity(0.04))
                          : _getColor(day.count, isDark),
                      borderRadius: BorderRadius.circular(3),
                    ),
                  ),
                );
              }).toList(),
            );
          }).toList(),
        ),
      ],
    );
  }

  Color _getColor(int count, bool isDark) {
    if (count >= 4) return isDark ? Colors.green.shade300 : Colors.green.shade700;
    if (count >= 3) return isDark ? Colors.green.shade400 : Colors.green.shade500;
    if (count >= 2) return isDark ? Colors.green.shade600 : Colors.green.shade300;
    return isDark ? Colors.green.shade800 : Colors.green.shade200;
  }
}

class _DayData {
  final DateTime date;
  final int count;
  _DayData({required this.date, required this.count});
}
