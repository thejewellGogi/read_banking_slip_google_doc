import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../core/widgets/month_picker_bar.dart';
import 'models/expense_model.dart';
import 'widgets/expense_day_header.dart';
import 'widgets/expense_tile.dart';

class ExpensesScreen extends StatefulWidget {
  const ExpensesScreen({super.key});

  @override
  State<ExpensesScreen> createState() => _ExpensesScreenState();
}

class _ExpensesScreenState extends State<ExpensesScreen> {
  // เก็บเป็นวันแรกของเดือนเสมอ
  DateTime selectedMonth = DateTime(2026, 1, 1);

  // mock data (หลายเดือน)
  final List<ExpenseModel> all = [
    // Jan 2026 (พ.ศ. 2569)
    ExpenseModel(dateTime: DateTime(2026, 1, 29, 8, 54), title: 'นาย อดิศักดิ์ พรหมพิข', amount: 20),
    ExpenseModel(dateTime: DateTime(2026, 1, 29, 8, 53), title: 'นาย สินมหุต กิตติชัยวัฒนา', amount: 500),
    ExpenseModel(dateTime: DateTime(2026, 1, 29, 8, 28), title: 'ช้อปปี้เพย์ วอลเล็ท (แอร์เพย์)', amount: 804),
    ExpenseModel(dateTime: DateTime(2026, 1, 28, 18, 30), title: 'นาย วิทยา เจริญสุข', amount: 50),
    ExpenseModel(dateTime: DateTime(2026, 1, 28, 17, 11), title: 'นางสาว กนกนิภา กิตติชัยวัฒนา', amount: 100),

    // Feb 2026
    ExpenseModel(dateTime: DateTime(2026, 2, 2, 10, 10), title: 'ค่าอาหาร', amount: 120),
    ExpenseModel(dateTime: DateTime(2026, 2, 2, 20, 45), title: 'เติมน้ำมัน', amount: 700),
    ExpenseModel(dateTime: DateTime(2026, 2, 1, 9, 15), title: 'กาแฟ', amount: 65),

    // Dec 2025 (พ.ศ. 2568) เอาไว้เทสเลื่อนจาก ม.ค. ย้อนมา ธ.ค.
    ExpenseModel(dateTime: DateTime(2025, 12, 31, 21, 10), title: 'ปิดยอดสิ้นปี', amount: 999),
  ];

  // ✅ แก้แล้ว: ให้ DateTime จัดการ rollover ปี/เดือนเอง (ชัวร์สุด)
  DateTime _addMonths(DateTime m, int delta) {
    return DateTime(m.year, m.month + delta, 1);
  }

  List<ExpenseModel> _itemsOfSelectedMonth() {
    final items = all
        .where((e) => e.dateTime.year == selectedMonth.year && e.dateTime.month == selectedMonth.month)
        .toList()
      ..sort((a, b) => b.dateTime.compareTo(a.dateTime)); // ล่าสุดก่อน
    return items;
  }

  double _sumAmount(Iterable<ExpenseModel> items) {
    double sum = 0;
    for (final e in items) {
      sum += e.amount;
    }
    return sum;
  }

  // ===== Thai helpers (ไม่พึ่ง locale) =====

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

  static const _thWeekdaysShort = [
    'จ.',
    'อ.',
    'พ.',
    'พฤ.',
    'ศ.',
    'ส.',
    'อา.',
  ];

  String _thaiMonthYear(DateTime m) {
    final monthName = _thMonths[m.month - 1];
    final buddhistYear = m.year + 543;
    return '$monthName $buddhistYear';
  }

  String _thaiDayHeader(DateTime day) {
    // DateTime.weekday: Mon=1 ... Sun=7
    final w = _thWeekdaysShort[day.weekday - 1];
    final monthName = _thMonths[day.month - 1];
    final buddhistYear = day.year + 543;
    return '$w ${day.day} $monthName $buddhistYear';
  }

  @override
  Widget build(BuildContext context) {
    final items = _itemsOfSelectedMonth();
    final monthTotal = _sumAmount(items);

    final totalText = NumberFormat.currency(
      locale: 'th_TH',
      symbol: '',
      decimalDigits: 2,
    ).format(monthTotal);

    // group by day
    final Map<DateTime, List<ExpenseModel>> grouped = {};
    for (final e in items) {
      final key = DateTime(e.dateTime.year, e.dateTime.month, e.dateTime.day);
      grouped.putIfAbsent(key, () => []).add(e);
    }

    final days = grouped.keys.toList()..sort((a, b) => b.compareTo(a));

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(icon: const Icon(Icons.sync), onPressed: () {}),
        title: const Text('จ่ายไปทั้งหมด', style: TextStyle(fontWeight: FontWeight.w900)),
        centerTitle: true,
        actions: [
          IconButton(icon: const Icon(Icons.bar_chart), onPressed: () {}),
        ],
      ),
      body: ListView(
        children: [
          const SizedBox(height: 8),
          Center(
            child: Text(
              '$totalText ฿',
              style: const TextStyle(fontSize: 44, fontWeight: FontWeight.w900),
            ),
          ),
          const SizedBox(height: 6),

          // ✅ แถบเลื่อนเดือน (เดือนแสดงเป็นไทย + พ.ศ. ถูกปีแน่นอน)
          MonthPickerBar(
            month: selectedMonth,
            onPrev: () => setState(() => selectedMonth = _addMonths(selectedMonth, -1)),
            onNext: () => setState(() => selectedMonth = _addMonths(selectedMonth, 1)),
          ),

          const SizedBox(height: 10),

          if (items.isEmpty)
            const Padding(
              padding: EdgeInsets.all(24),
              child: Center(
                child: Text('ไม่มีรายการในเดือนนี้', style: TextStyle(color: Colors.black54)),
              ),
            )
          else
            ...days.map((day) {
              final list = grouped[day]!;
              final dayTotal = _sumAmount(list);
              final right = NumberFormat.currency(
                locale: 'th_TH',
                symbol: 'THB ',
                decimalDigits: 2,
              ).format(dayTotal);

              // label: วันนี้ หรือ วันภาษาไทย
              final now = DateTime.now();
              final isToday = (day.year == now.year && day.month == now.month && day.day == now.day);
              final left = isToday ? 'วันนี้' : _thaiDayHeader(day);

              return Column(
                children: [
                  ExpenseDayHeader(left: left, right: right),
                  ...list.map((e) => ExpenseTile(model: e)),
                ],
              );
            }),

          const SizedBox(height: 20),
        ],
      ),
    );
  }
}
