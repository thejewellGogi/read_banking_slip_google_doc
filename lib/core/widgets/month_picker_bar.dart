import 'package:flutter/material.dart';

class MonthPickerBar extends StatelessWidget {
  final DateTime month; // วันแรกของเดือน
  final VoidCallback onPrev;
  final VoidCallback onNext;

  const MonthPickerBar({
    super.key,
    required this.month,
    required this.onPrev,
    required this.onNext,
  });

  static const _thMonths = [
    'มกราคม',
    'กุมภาพันธ์',
    'มีนาคม',
    'เมษายน',
    'พฤษภาคม',
    'มิถุนายน',
    'กรกฎาคม',
    'สิงหาคม',
    'กันยายน',
    'ตุลาคม',
    'พฤศจิกายน',
    'ธันวาคม',
  ];

  String _thaiMonthYear(DateTime m) {
    final monthName = _thMonths[m.month - 1];
    final buddhistYear = m.year + 543;
    return '$monthName $buddhistYear';
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        IconButton(onPressed: onPrev, icon: const Icon(Icons.chevron_left)),
        Text(
          _thaiMonthYear(month),
          style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800),
        ),
        IconButton(onPressed: onNext, icon: const Icon(Icons.chevron_right)),
      ],
    );
  }
}
