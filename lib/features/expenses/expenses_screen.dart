import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../slips/models/slip_data_model.dart';
import '../slips/services/slip_storage_service.dart';

class ExpensesScreen extends StatefulWidget {
  const ExpensesScreen({super.key});

  @override
  State<ExpensesScreen> createState() => _ExpensesScreenState();
}

class _ExpensesScreenState extends State<ExpensesScreen> {
  final SlipStorageService storage = SlipStorageService();

  DateTime selectedMonth = DateTime.now();
  List<SlipDataModel> allSlips = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() {
      isLoading = true;
    });

    final slips = await storage.loadAll();

    setState(() {
      allSlips = slips;
      isLoading = false;
    });
  }

  void _prevMonth() {
    setState(() {
      selectedMonth = DateTime(selectedMonth.year, selectedMonth.month - 1, 1);
    });
  }

  void _nextMonth() {
    setState(() {
      selectedMonth = DateTime(selectedMonth.year, selectedMonth.month + 1, 1);
    });
  }

  List<SlipDataModel> get monthSlips {
    return allSlips.where((e) {
      final dt = e.galleryDateTime;
      return dt != null &&
          dt.year == selectedMonth.year &&
          dt.month == selectedMonth.month &&
          e.amount != null;
    }).toList()
      ..sort((a, b) {
        final ad = a.galleryDateTime ?? DateTime(2000);
        final bd = b.galleryDateTime ?? DateTime(2000);
        return bd.compareTo(ad);
      });
  }

  double get monthTotal {
    double total = 0;

    for (final s in monthSlips) {
      final amount = s.amount ?? 0;

      if (s.slipType == SlipType.expense) {
        total += amount;
      } else if (s.slipType == SlipType.income) {
        total -= amount;
      }
    }

    return total;
  }

  Map<DateTime, List<SlipDataModel>> get groupedByDay {
    final map = <DateTime, List<SlipDataModel>>{};

    for (final slip in monthSlips) {
      final dt = slip.galleryDateTime!;
      final key = DateTime(dt.year, dt.month, dt.day);

      map.putIfAbsent(key, () => []);
      map[key]!.add(slip);
    }

    return map;
  }

  String _thaiMonthYear(DateTime date) {
    final month = DateFormat('MMMM', 'th_TH').format(date);
    final year = date.year + 543;
    return '$month $year';
  }

  String _thaiDayHeader(DateTime date) {
    final dayName = DateFormat('E', 'th_TH').format(date);
    final month = DateFormat('MMMM', 'th_TH').format(date);
    final year = date.year + 543;
    return '$dayName. ${date.day} $month $year';
  }

  String _timeText(DateTime? dt) {
    if (dt == null) return '--:--';
    return DateFormat('HH:mm').format(dt);
  }

  double _dayNetTotal(List<SlipDataModel> slips) {
    double total = 0;

    for (final s in slips) {
      final amount = s.amount ?? 0;

      if (s.slipType == SlipType.expense) {
        total += amount;
      } else if (s.slipType == SlipType.income) {
        total -= amount;
      }
    }

    return total;
  }

  @override
  Widget build(BuildContext context) {
    final groups = groupedByDay.entries.toList()
      ..sort((a, b) => b.key.compareTo(a.key));

    return Scaffold(
      backgroundColor: const Color(0xFFF6F7FB),
      appBar: AppBar(
        title: const Text(
          'จ่ายไปทั้งหมด',
          style: TextStyle(fontWeight: FontWeight.w800),
        ),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                const SizedBox(height: 12),
                Text(
                  NumberFormat('#,##0.00').format(monthTotal),
                  style: const TextStyle(
                    fontSize: 44,
                    fontWeight: FontWeight.w900,
                    color: Color(0xFF171A22),
                  ),
                ),
                const Text(
                  '฿',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    IconButton(
                      onPressed: _prevMonth,
                      icon: const Icon(Icons.chevron_left),
                    ),
                    Text(
                      _thaiMonthYear(selectedMonth),
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    IconButton(
                      onPressed: _nextMonth,
                      icon: const Icon(Icons.chevron_right),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Expanded(
                  child: ListView.builder(
                    padding: const EdgeInsets.only(bottom: 16),
                    itemCount: groups.length,
                    itemBuilder: (_, i) {
                      final day = groups[i].key;
                      final slips = groups[i].value;
                      final dayTotal = _dayNetTotal(slips);

                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            margin: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 14,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xFF0B1B4A),
                              borderRadius: BorderRadius.circular(18),
                            ),
                            child: Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    _thaiDayHeader(day),
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.w800,
                                      fontSize: 16,
                                    ),
                                  ),
                                ),
                                Text(
                                  'THB ${NumberFormat("#,##0.00").format(dayTotal)}',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w800,
                                    fontSize: 16,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          ...slips.map((slip) {
                            final isIncome = slip.slipType == SlipType.income;

                            return ListTile(
                              leading: CircleAvatar(
                                radius: 26,
                                backgroundColor: Colors.grey.shade300,
                                child: const Text(
                                  '?',
                                  style: TextStyle(
                                    fontSize: 24,
                                    fontWeight: FontWeight.w700,
                                    color: Colors.black45,
                                  ),
                                ),
                              ),
                              title: Text(
                                slip.receiverName?.isNotEmpty == true
                                    ? slip.receiverName!
                                    : (slip.bankName ?? 'ไม่ทราบชื่อผู้รับ'),
                                style: const TextStyle(
                                  fontWeight: FontWeight.w800,
                                  fontSize: 16,
                                ),
                              ),
                              subtitle: Text(
                                '${isIncome ? "+" : "-"} THB ${NumberFormat("#,##0.00").format(slip.amount ?? 0)}',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: isIncome ? Colors.green : Colors.black54,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              trailing: Text(
                                _timeText(slip.galleryDateTime),
                                style: const TextStyle(
                                  color: Colors.black54,
                                  fontSize: 14,
                                ),
                              ),
                            );
                          }),
                        ],
                      );
                    },
                  ),
                ),
              ],
            ),
    );
  }
}