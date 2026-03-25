import 'package:flutter/material.dart';

import '../../ocr/gallery/auto_ocr_runner.dart';
import '../../ocr/gallery/scanned_registry.dart';
import '../../features/slips/services/slip_storage_service.dart';
import '../shell/bottom_shell.dart';
import 'models/source_model.dart';
import 'widgets/source_tile.dart';

class ScreenLoadSlip extends StatefulWidget {
  const ScreenLoadSlip({super.key});

  @override
  State<ScreenLoadSlip> createState() => _ScreenLoadSlipState();
}

class _ScreenLoadSlipState extends State<ScreenLoadSlip> {
  final AutoOcrRunner runner = AutoOcrRunner();
  final SlipStorageService storage = SlipStorageService();
  final ScannedRegistry scannedRegistry = ScannedRegistry();

  bool _isLoading = true;
  String _headerText = 'สลิปอยู่ไหนบ้างเอ่ย?';
  String _subText = 'กำลังเตรียมระบบ...';
  int _newSlipCount = 0;

  late List<SourceModel> items;

  @override
  void initState() {
    super.initState();
    items = _initialItems();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _startRealScan();
    });
  }

  List<SourceModel> _initialItems() => [
        const SourceModel(
          name: 'Bangkok Bank',
          slipCount: 0,
          statusType: SourceStatusType.starting,
          progress: 0,
        ),
        const SourceModel(
          name: 'K PLUS',
          slipCount: 0,
          statusType: SourceStatusType.starting,
          progress: 0,
        ),
        const SourceModel(
          name: 'Krungthai NEXT',
          slipCount: 0,
          statusType: SourceStatusType.starting,
          progress: 0,
        ),
        const SourceModel(
          name: 'SCB',
          slipCount: 0,
          statusType: SourceStatusType.starting,
          progress: 0,
        ),
        const SourceModel(
          name: 'Krungsri',
          slipCount: 0,
          statusType: SourceStatusType.starting,
          progress: 0,
        ),
        const SourceModel(
          name: 'ttb',
          slipCount: 0,
          statusType: SourceStatusType.starting,
          progress: 0,
        ),
        const SourceModel(
          name: 'UOB',
          slipCount: 0,
          statusType: SourceStatusType.starting,
          progress: 0,
        ),
        const SourceModel(
          name: 'CIMB Thai',
          slipCount: 0,
          statusType: SourceStatusType.starting,
          progress: 0,
        ),
        const SourceModel(
          name: 'Kiatnakin Phatra',
          slipCount: 0,
          statusType: SourceStatusType.starting,
          progress: 0,
        ),
        const SourceModel(
          name: 'TISCO',
          slipCount: 0,
          statusType: SourceStatusType.starting,
          progress: 0,
        ),
        const SourceModel(
          name: 'LH Bank',
          slipCount: 0,
          statusType: SourceStatusType.starting,
          progress: 0,
        ),
        const SourceModel(
          name: 'Thai Credit',
          slipCount: 0,
          statusType: SourceStatusType.starting,
          progress: 0,
        ),
        const SourceModel(
          name: 'ICBC Thai',
          slipCount: 0,
          statusType: SourceStatusType.starting,
          progress: 0,
        ),
        const SourceModel(
          name: 'Bank of China Thai',
          slipCount: 0,
          statusType: SourceStatusType.starting,
          progress: 0,
        ),
      ];

  Future<void> _startRealScan() async {
    try {
      print('SCREEN LOAD SLIP: START');

      if (!mounted) return;
      setState(() {
        _isLoading = true;
        _newSlipCount = 0;
        _subText = 'กำลังโหลดรูปจากเครื่อง...';
        items = items
            .map(
              (e) => e.copyWith(
                statusType: SourceStatusType.scanning,
                progress: 0,
              ),
            )
            .toList();
      });

      await Future.delayed(const Duration(milliseconds: 300));

      if (!mounted) return;
      setState(() {
        _subText = 'กำลังอ่านสลิปจริงจาก OCR...';
      });

      final slips = await runner.scanAndBuildSlipData(limit: 100);
      print('SCREEN LOAD SLIP: NEW SLIPS = ${slips.length}');

      if (!mounted) return;
      setState(() {
        _newSlipCount = slips.length;
        _subText = 'กำลังสรุปจำนวนสลิปแต่ละธนาคาร...';
      });

      final counts = await storage.countByBank();
      print('SCREEN LOAD SLIP: COUNTS = $counts');

      if (!mounted) return;
      setState(() {
        items = items.map((item) {
          final count = counts[item.name] ?? 0;

          return item.copyWith(
            slipCount: count,
            statusType:
                count > 0 ? SourceStatusType.done : SourceStatusType.none,
            progress: 100,
          );
        }).toList();

        _isLoading = false;
        _subText = 'อ่านสลิปใหม่สำเร็จ $_newSlipCount ใบ';
      });
    } catch (e, st) {
      print('SCREEN LOAD SLIP ERROR');
      print(e);
      print(st);

      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _subText = 'เกิดข้อผิดพลาด: $e';
      });
    }
  }

  Future<void> _goNext() async {
    if (!mounted) return;

    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (_) => const BottomShell(),
      ),
    );
  }

  Future<void> _retry() async {
    setState(() {
      items = _initialItems();
      _isLoading = true;
      _newSlipCount = 0;
      _subText = 'กำลังเริ่มสแกนใหม่...';
    });

    await _startRealScan();
  }

  Future<void> _clearSlipMemory() async {
    try {
      setState(() {
        _isLoading = true;
        _subText = 'กำลังล้างข้อมูลสลิปที่เคยอ่าน...';
      });

      await storage.clear();
      await scannedRegistry.clear();

      if (!mounted) return;

      setState(() {
        items = _initialItems();
        _isLoading = false;
        _newSlipCount = 0;
        _subText = 'ล้างข้อมูลสลิปเรียบร้อยแล้ว';
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('ล้างความจำสลิปที่เคยอ่านแล้ว'),
        ),
      );
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _isLoading = false;
        _subText = 'ล้างข้อมูลไม่สำเร็จ: $e';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    print('BUILD ScreenLoadSlip');

    return Scaffold(
      backgroundColor: const Color(0xFFF6F7FB),
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: Text(
          _headerText,
          style: const TextStyle(fontWeight: FontWeight.w800),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: Column(
        children: [
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                const Icon(Icons.image_search_outlined),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    _subText,
                    style: const TextStyle(
                      color: Colors.black54,
                      fontSize: 14,
                    ),
                  ),
                ),
                if (_isLoading)
                  const SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(strokeWidth: 2.5),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: items.length,
              itemBuilder: (_, i) {
                final m = items[i];
                return SourceTile(
                  model: m,
                  onTap: () {
                    print('TAP ${m.name}');
                  },
                );
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: Column(
              children: [
                if (_isLoading)
                  const SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: ElevatedButton(
                      onPressed: null,
                      child: Text('กำลังสแกน...'),
                    ),
                  )
                else ...[
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: ElevatedButton(
                      onPressed: _goNext,
                      child: Text('ไปต่อ ($_newSlipCount ใบใหม่)'),
                    ),
                  ),
                  const SizedBox(height: 10),
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: OutlinedButton(
                      onPressed: _retry,
                      child: const Text('สแกนใหม่อีกครั้ง'),
                    ),
                  ),
                  const SizedBox(height: 10),
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: TextButton(
                      onPressed: _clearSlipMemory,
                      child: const Text('ล้างความจำสลิป'),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}