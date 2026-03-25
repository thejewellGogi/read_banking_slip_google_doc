import 'dart:io';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import 'models/slip_data_model.dart';
import 'services/slip_storage_service.dart';
import 'slip_detail_screen.dart';
enum SlipFilterType { all, unreadable, readable }

class SlipsScreen extends StatefulWidget {
  const SlipsScreen({super.key});

  @override
  State<SlipsScreen> createState() => _SlipsScreenState();
}

class _SlipsScreenState extends State<SlipsScreen> {
  final SlipStorageService storage = SlipStorageService();

  bool isLoading = true;
  DateTime selectedMonth = DateTime.now();
  SlipFilterType selectedFilter = SlipFilterType.all;

  List<SlipDataModel> allSlips = [];

  @override
  void initState() {
    super.initState();
    _loadSlips();
  }

  Future<void> _loadSlips() async {
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

  List<SlipDataModel> get filteredMonthSlips {
    final list = allSlips.where((e) {
      final dt = e.galleryDateTime;
      if (dt == null) return false;

      final sameMonth =
          dt.year == selectedMonth.year && dt.month == selectedMonth.month;

      if (!sameMonth) return false;

      switch (selectedFilter) {
        case SlipFilterType.all:
          return true;
        case SlipFilterType.unreadable:
          return !e.isReadable;
        case SlipFilterType.readable:
          return e.isReadable;
      }
    }).toList();

    list.sort((a, b) {
      final ad = a.galleryDateTime ?? DateTime(2000);
      final bd = b.galleryDateTime ?? DateTime(2000);
      return bd.compareTo(ad);
    });

    return list;
  }

  Map<DateTime, List<SlipDataModel>> get groupedByDay {
    final map = <DateTime, List<SlipDataModel>>{};

    for (final slip in filteredMonthSlips) {
      final dt = slip.galleryDateTime!;
      final key = DateTime(dt.year, dt.month, dt.day);

      map.putIfAbsent(key, () => []);
      map[key]!.add(slip);
    }

    return map;
  }

  String _filterLabel(SlipFilterType type) {
    switch (type) {
      case SlipFilterType.all:
        return 'ทั้งหมด';
      case SlipFilterType.unreadable:
        return 'อ่านไม่ได้';
      case SlipFilterType.readable:
        return 'อ่านได้';
    }
  }

  // Future<void> _openSlipDetail(SlipDataModel slip) async {
  //   // ตอนนี้ทำเป็น dialog ชั่วคราวก่อน
  //   // รอบถัดไปค่อยแยกเป็น SlipDetailScreen จริง
  //   await showDialog(
  //     context: context,
  //     builder: (_) => AlertDialog(
  //       title: const Text('รายละเอียดสลิป'),
  //       content: SingleChildScrollView(
  //         child: Column(
  //           crossAxisAlignment: CrossAxisAlignment.start,
  //           children: [
  //             Text('ธนาคาร: ${slip.bankName ?? "-"}'),
  //             const SizedBox(height: 8),
  //             Text('จำนวนเงิน: ${slip.amount ?? 0}'),
  //             const SizedBox(height: 8),
  //             Text('วันที่รูป: ${slip.galleryDateTime ?? "-"}'),
  //             const SizedBox(height: 8),
  //             Text('สถานะ: ${slip.status}'),
  //             const SizedBox(height: 12),
  //             const Text('OCR TEXT'),
  //             const SizedBox(height: 6),
  //             Text(
  //               slip.rawText,
  //               style: const TextStyle(fontSize: 12),
  //             ),
  //           ],
  //         ),
  //       ),
  //       actions: [
  //         TextButton(
  //           onPressed: () => Navigator.pop(context),
  //           child: const Text('ปิด'),
  //         ),
  //       ],
  //     ),
  //   );
  // }
  Future<void> _openSlipDetail(SlipDataModel slip) async {
    final updated = await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (_) => SlipDetailScreen(slip: slip)),
    );

    if (updated == true) {
      await _loadSlips();
    }
  }

  @override
  Widget build(BuildContext context) {
    final groups = groupedByDay.entries.toList()
      ..sort((a, b) => b.key.compareTo(a.key));

    return Scaffold(
      backgroundColor: const Color(0xFFF6F7FB),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text(
          'สลิป',
          style: TextStyle(fontWeight: FontWeight.w800),
        ),
        centerTitle: false,
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadSlips,
              child: ListView(
                padding: const EdgeInsets.only(bottom: 24),
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Row(
                      children: [
                        _MonthArrowButton(
                          icon: Icons.chevron_left,
                          onTap: _prevMonth,
                        ),
                        Expanded(
                          child: Center(
                            child: Text(
                              _thaiMonthYear(selectedMonth),
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ),
                        ),
                        _MonthArrowButton(
                          icon: Icons.chevron_right,
                          onTap: _nextMonth,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Row(
                      children: [
                        Expanded(
                          child: _FilterButton(
                            label: _filterLabel(SlipFilterType.all),
                            selected: selectedFilter == SlipFilterType.all,
                            onTap: () {
                              setState(() {
                                selectedFilter = SlipFilterType.all;
                              });
                            },
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: _FilterButton(
                            label: _filterLabel(SlipFilterType.unreadable),
                            selected:
                                selectedFilter == SlipFilterType.unreadable,
                            onTap: () {
                              setState(() {
                                selectedFilter = SlipFilterType.unreadable;
                              });
                            },
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: _FilterButton(
                            label: _filterLabel(SlipFilterType.readable),
                            selected: selectedFilter == SlipFilterType.readable,
                            onTap: () {
                              setState(() {
                                selectedFilter = SlipFilterType.readable;
                              });
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),
                  if (groups.isEmpty)
                    const Padding(
                      padding: EdgeInsets.only(top: 80),
                      child: Center(
                        child: Text(
                          'ไม่พบสลิปในเดือนนี้',
                          style: TextStyle(fontSize: 16, color: Colors.black54),
                        ),
                      ),
                    )
                  else
                    ...groups.map((entry) {
                      final day = entry.key;
                      final slips = entry.value;

                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            margin: const EdgeInsets.fromLTRB(16, 0, 16, 10),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 10,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xFF0B1B4A),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    _thaiDayHeader(day),
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 15,
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
                                ),
                                Text(
                                  '${slips.length} ใบ',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 15,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            child: GridView.builder(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              itemCount: slips.length,
                              gridDelegate:
                                  const SliverGridDelegateWithFixedCrossAxisCount(
                                    crossAxisCount: 3,
                                    crossAxisSpacing: 8,
                                    mainAxisSpacing: 8,
                                    childAspectRatio: 0.68,
                                  ),
                              itemBuilder: (_, index) {
                                final slip = slips[index];
                                return _SlipThumbCard(
                                  slip: slip,
                                  onTap: () => _openSlipDetail(slip),
                                );
                              },
                            ),
                          ),
                          const SizedBox(height: 14),
                        ],
                      );
                    }),
                ],
              ),
            ),
    );
  }
}

class _MonthArrowButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;

  const _MonthArrowButton({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(10),
      onTap: onTap,
      child: Container(
        width: 38,
        height: 38,
        decoration: BoxDecoration(
          border: Border.all(color: Colors.black26),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon),
      ),
    );
  }
}

class _FilterButton extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _FilterButton({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final bg = selected ? const Color(0xFF0B1B4A) : Colors.white;
    final fg = selected ? Colors.white : Colors.black54;
    final border = selected ? Colors.transparent : Colors.black12;

    return InkWell(
      borderRadius: BorderRadius.circular(10),
      onTap: onTap,
      child: Container(
        height: 42,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: border),
        ),
        child: Text(
          label,
          style: TextStyle(color: fg, fontWeight: FontWeight.w700),
        ),
      ),
    );
  }
}

class _SlipThumbCard extends StatelessWidget {
  final SlipDataModel slip;
  final VoidCallback onTap;

  const _SlipThumbCard({required this.slip, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final file = File(slip.imagePath);
    final hasFile = file.existsSync();

    return InkWell(
      borderRadius: BorderRadius.circular(8),
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: slip.isReadable ? Colors.transparent : Colors.red.shade200,
          ),
        ),
        child: Stack(
          children: [
            Positioned.fill(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: hasFile
                    ? Image.file(file, fit: BoxFit.cover)
                    : Container(
                        color: Colors.grey.shade200,
                        alignment: Alignment.center,
                        child: const Icon(Icons.image_not_supported_outlined),
                      ),
              ),
            ),
            Positioned(
              left: 6,
              right: 6,
              bottom: 6,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.55),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  slip.bankName ?? 'ไม่ทราบธนาคาร',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
            if (!slip.isReadable)
              Positioned(
                right: 6,
                bottom: 34,
                child: Container(
                  width: 28,
                  height: 28,
                  decoration: BoxDecoration(
                    color: Colors.red.shade400,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.qr_code_2,
                    size: 18,
                    color: Colors.white,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
