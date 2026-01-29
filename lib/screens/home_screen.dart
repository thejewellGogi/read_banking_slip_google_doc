// lib/screens/home_screen.dart
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';

import '../widgets/gradient_button.dart';
// import '../services/image_processing_service.dart';
import '../services/ocr_service.dart';
import '../state/transactions_provider.dart';
import '../models/transaction_model.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  File? preview;
  File? preprocessedPreview;
  bool busy = false;

  /// เลือกรูปจากคลัง -> ประมวลผล OCR -> รีเฟรชรายการ
  Future<void> _pickAndProcess() async {
    final picked = await ImagePicker().pickImage(
      source: ImageSource.gallery,
      maxWidth: 1400,
      imageQuality: 90,
    );
    if (picked == null) return;

    setState(() {
      preview = File(picked.path); // รูปต้นฉบับ
      busy = true;
    });

    await Future.delayed(const Duration(milliseconds: 16));

    // OCR + คืนพาธไฟล์หลัง preprocess
    final ocr = OCRService();
    final result = await ocr.readText(picked.path);

    // โชว์ภาพหลัง preprocess
    if (!mounted) return;
    setState(() {
      preprocessedPreview = File(result.imagePath);
      busy = false;
    });

    // (ถ้าจะ parse แล้ว insert DB ให้ทำต่อจาก result.text ตรงนี้)
    await context.read<TransactionsProvider>().refresh();
  }

  Future<void> _refreshSummary() async {
    await context.read<TransactionsProvider>().refresh();
  }

  @override
  void initState() {
    super.initState();
    _refreshSummary();
  }

  @override
  Widget build(BuildContext context) {
    final prov = context.watch<TransactionsProvider>();
    final List<TransactionModel> latest = List<TransactionModel>.from(
      prov.latest,
    );
    final last = latest.isNotEmpty ? latest.first : null;
    final money = NumberFormat.currency(locale: 'th_TH', symbol: '฿');

    return Scaffold(
      appBar: AppBar(
        title: const Text('Read Transfer Slip'),
        elevation: 0.5,
        actions: [
          IconButton(
            onPressed: () => Navigator.pushNamed(context, '/transactions'),
            icon: const Icon(Icons.list_alt),
          ),
          IconButton(
            onPressed: () => Navigator.pushNamed(context, '/settings'),
            icon: const Icon(Icons.settings),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _refreshSummary,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            if (busy) const LinearProgressIndicator(),

            const Text(
              'อ่านสลิป',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 6),
            Text(
              'ยังไม่มีข้อมูล ลองกดปุ่มด้านล่างเพื่ออ่านสลิปจากรูปภาพ',
              style: TextStyle(color: Colors.black.withOpacity(0.65)),
            ),
            const SizedBox(height: 16),

            // ปุ่มเหลืองไล่ระดับ
            GradientButton(
              onPressed: _pickAndProcess,
              icon: Icons.photo,
              label: 'เลือกภาพจากคลัง & อ่านสลิป',
            ),
            const SizedBox(height: 20),

            // พรีวิวรูป (ถ้ามี)
            if (preview != null)
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.file(preview!, height: 180, fit: BoxFit.cover),
              ),
            if (preview != null) const SizedBox(height: 20),
            // พรีวิวรูปหลัง Preprocess (ถ้ามี)
            if (preprocessedPreview != null)
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'หลัง Preprocess',
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 6),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.file(
                      preprocessedPreview!,
                      height: 180,
                      fit: BoxFit.cover,
                    ),
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            // การ์ดธุรกรรมล่าสุด (ถ้ามี)
            if (last != null)
              Card(
                elevation: 0.5,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: ListTile(
                  leading: const Icon(Icons.receipt_long),
                  title: Text(
                    '${last.bankName} • ${money.format(last.amount)}',
                  ),
                  subtitle: Text(
                    '${last.type.toUpperCase()} • ${_formatDate(last.transactionDate)}',
                  ),
                ),
              ),
            if (last != null) const SizedBox(height: 20),

            const Text(
              'สรุปตามวัน',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),

            // Section รายวัน (กาง/พับได้) — เพิ่มปุ่มลบในแต่ละรายการแล้ว
            ..._buildDailySections(context),
          ],
        ),
      ),
    );
  }

  /// --- Helpers ---

  DateTime _asDateOnly(Object? v) {
    if (v is DateTime) return DateTime(v.year, v.month, v.day);
    if (v is String) {
      final p = DateTime.tryParse(v);
      if (p != null) return DateTime(p.year, p.month, p.day);
    }
    return DateTime.now();
  }

  String _formatDate(Object? v) {
    final d = _asDateOnly(v);
    return DateFormat('d MMM y', 'th').format(d);
  }

  /// จัดกลุ่มธุรกรรมเป็นรายวัน และวาด UI แบบ ExpansionTile (มีปุ่มลบ)
  List<Widget> _buildDailySections(BuildContext context) {
    final prov = context.watch<TransactionsProvider>();
    final List<TransactionModel> txs = List<TransactionModel>.from(prov.latest);
    final money = NumberFormat.currency(locale: 'th_TH', symbol: '฿');

    final Map<DateTime, List<TransactionModel>> byDay =
        <DateTime, List<TransactionModel>>{};
    for (final t in txs) {
      final day = _asDateOnly(t.transactionDate);
      byDay.putIfAbsent(day, () => <TransactionModel>[]).add(t);
    }

    final days = byDay.keys.toList()..sort((a, b) => b.compareTo(a));
    final fmt = DateFormat('วันที่ d MMM y', 'th');

    return [
      for (final day in days)
        _buildDayCard(
          context: context, // ✅ ส่ง context เข้าไปเพื่อใช้ลบ
          day: day,
          items: byDay[day]!,
          money: money,
          fmt: fmt,
        ),
    ];
  }

  Widget _buildDayCard({
    required BuildContext context, // ✅ รับ context
    required DateTime day,
    required List<TransactionModel> items,
    required NumberFormat money,
    required DateFormat fmt,
  }) {
    final total = items.fold<double>(0.0, (s, t) => s + t.amount);

    return Card(
      elevation: 0.5,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ExpansionTile(
        tilePadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        title: Row(
          children: [
            Text(
              fmt.format(day),
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
            const SizedBox(width: 8),
            Text(
              '• รวม ${money.format(total)}',
              style: TextStyle(
                color: Colors.black.withOpacity(0.55),
                fontSize: 13,
              ),
            ),
          ],
        ),
        childrenPadding: const EdgeInsets.fromLTRB(8, 0, 8, 12),
        children: [
          for (var i = 0; i < items.length; i++)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: ListTile(
                dense: true,
                leading: const Icon(Icons.receipt_long, size: 20),
                title: Text(
                  money.format(items[i].amount),
                  style: const TextStyle(fontSize: 15),
                ),
                subtitle: Text(
                  '${items[i].bankName} • ${DateFormat('HH:mm', 'th').format(items[i].transactionDate)}',
                ),
                trailing: IconButton(
                  icon: const Icon(Icons.delete_outline, color: Colors.red),
                  tooltip: 'ลบรายการนี้',
                  onPressed: () async {
                    final confirm = await showDialog<bool>(
                      context: context,
                      builder: (ctx) => AlertDialog(
                        title: const Text('ยืนยันการลบ'),
                        content: const Text('ต้องการลบรายการนี้หรือไม่?'),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(ctx, false),
                            child: const Text('ยกเลิก'),
                          ),
                          ElevatedButton(
                            onPressed: () => Navigator.pop(ctx, true),
                            child: const Text('ลบ'),
                          ),
                        ],
                      ),
                    );
                    if (confirm == true) {
                      await context.read<TransactionsProvider>().remove(
                        items[i].id!,
                      );
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('ลบรายการแล้ว')),
                        );
                      }
                    }
                  },
                ),
              ),
            ),
        ],
      ),
    );
  }
}
