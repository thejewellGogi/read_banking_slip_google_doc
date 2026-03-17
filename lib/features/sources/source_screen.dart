import 'package:flutter/material.dart';
import 'package:photo_manager/photo_manager.dart';

import 'models/source_model.dart';
import 'widgets/source_tile.dart';

import 'package:read_banking_slip/ocr/gallery/auto_ocr_runner.dart';
import 'package:read_banking_slip/ocr/gallery/gallery_album_registry.dart';

class SourceScreen extends StatefulWidget {
  const SourceScreen({super.key});

  @override
  State<SourceScreen> createState() => _SourceScreenState();
}

class _SourceScreenState extends State<SourceScreen> {
  late List<SourceModel> items;

  @override
  void initState() {
    super.initState();
    print('INIT SourceScreen');

    items = _mock();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      print('POST FRAME CALLBACK');
      _scanAllBanks();
    });
  }

  List<SourceModel> _mock() => [
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

  Future<void> _bindAlbum(BuildContext context, String bankName) async {
    final perm = await PhotoManager.requestPermissionExtend();

    if (!perm.isAuth && !perm.isLimited) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('ยังไม่ได้อนุญาตเข้าถึงคลังภาพ')),
      );
      return;
    }

    final albums = await PhotoManager.getAssetPathList(
      type: RequestType.image,
      hasAll: true,
      onlyAll: false,
    );

    if (!context.mounted) return;

    final picked = await showModalBottomSheet<AssetPathEntity>(
      context: context,
      builder: (_) => SafeArea(
        child: ListView.builder(
          itemCount: albums.length,
          itemBuilder: (_, i) {
            final a = albums[i];
            return ListTile(
              title: Text(a.name),
              subtitle: FutureBuilder<int>(
                future: a.assetCountAsync,
                builder: (_, s) => Text('จำนวนรูป: ${s.data ?? "..."}'),
              ),
              onTap: () => Navigator.pop(context, a),
            );
          },
        ),
      ),
    );

    if (picked == null) return;

    await GalleryAlbumRegistry().setAlbumId(bankName, picked.id);

    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('ตั้งค่าอัลบั้มของ $bankName แล้ว: ${picked.name}'),
      ),
    );
  }

  Future<void> _scanAllBanks() async {
    print("SCAN ALL START");

    setState(() {
      items = items
          .map((e) => e.copyWith(statusType: SourceStatusType.scanning))
          .toList();
    });

    final result = await AutoOcrRunner().scanAllAndCountByBank(limit: 100);

    print(result);

    if (!mounted) return;

    setState(() {
      items = items.map((item) {
        final count = result[item.name] ?? 0;

        return item.copyWith(
          slipCount: count,
          statusType: SourceStatusType.done,
          progress: 100,
        );
      }).toList();
    });

    print("SCAN ALL DONE");
  }

  Future<void> _manualBindAndRescan() async {
    final index = items.indexWhere((e) => e.name == 'Krungthai NEXT');
    if (index == -1) return;

    await _bindAlbum(context, items[index].name);

    if (!mounted) return;
    await _scanAllBanks();
  }

  @override
  Widget build(BuildContext context) {
    final krungthai = items.firstWhere((e) => e.name == 'Krungthai NEXT');
    print('BUILD Krungthai = ${krungthai.slipCount}');

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'สลิปอยู่ไหนบ้างเอ่ย?',
          style: TextStyle(fontWeight: FontWeight.w800),
        ),
      ),
      body: ListView.builder(
        itemCount: items.length,
        itemBuilder: (_, i) {
          final m = items[i];

          return SourceTile(
            model: m,
            onTap: () async {
              if (m.name == 'Krungthai NEXT') {
                await _manualBindAndRescan();
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('ตอนนี้ทดสอบ OCR เฉพาะ Krungthai NEXT'),
                  ),
                );
              }
            },
          );
        },
      ),
    );
  }
}
