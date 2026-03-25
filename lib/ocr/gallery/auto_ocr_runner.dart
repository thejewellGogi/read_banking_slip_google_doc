import 'dart:io';

import 'package:photo_manager/photo_manager.dart';

import '../../features/slips/models/slip_data_model.dart';
import '../../features/slips/services/slip_storage_service.dart';
import '../engines/tesseract_engine.dart';
import '../preprocess/preprocess_service.dart';
import '../slip_rated_analyzer.dart';
import 'scanned_registry.dart';
import '../slip_amount_extractor.dart';

class AutoOcrRunner {
  final registry = ScannedRegistry();
  final pre = PreprocessService();
  final ocr = TesseractEngine();
  final storage = SlipStorageService();

  List<SlipDataModel> slipData = [];

  Future<List<SlipDataModel>> scanAndBuildSlipData({int limit = 100}) async {
    print('RUNNER: START');

    slipData = [];

    final perm = await PhotoManager.requestPermissionExtend();
    final hasGalleryAccess = perm.isAuth || perm.isLimited;

    if (!hasGalleryAccess) {
      print('NO GALLERY ACCESS');
      return [];
    }

    final albums = await PhotoManager.getAssetPathList(
      type: RequestType.image,
      onlyAll: true,
    );

    if (albums.isEmpty) {
      print('NO ALBUMS');
      return [];
    }

    final assets = await albums.first.getAssetListPaged(page: 0, size: limit);

    if (assets.isEmpty) {
      print('NO ASSETS');
      return [];
    }

    print('FOUND ASSETS: ${assets.length}');

    int index = 0;

    for (final asset in assets) {
      index++;

      try {
        final file = await asset.file;
        if (file == null) {
          print('FILE NULL');
          continue;
        }

        final alreadyImported = await registry.already(file.path);
        if (alreadyImported) {
          print('SKIP IMPORTED: ${file.path}');
          continue;
        }

        print('=================================');
        print('IMAGE $index / ${assets.length}');
        print('PATH: ${file.path}');

        final processed = await pre.preprocessSlip(file);
        final rawText = await ocr.recognize(processed.path);

        final analysis = SlipRatedAnalyzer.analyze(rawText);
        final bool isSlip = (analysis['isLikelySlip'] as bool?) ?? false;
        final String? bankName = analysis['bankName'] as String?;

        print('isSlip=$isSlip bankName=$bankName');

        if (!isSlip || bankName == null) {
          continue;
        }

        final amount = SlipAmountExtractor.extract(
          rawText: rawText,
          bankName: bankName,
        );

        // ใช้วันที่/เวลาจากรูปใน Gallery
        final galleryDateTime = asset.createDateTime;
        final bool isReadable = amount != null && amount >= 0.01;
        
        final slip = SlipDataModel(
          id: '${DateTime.now().microsecondsSinceEpoch}_$index',
          imagePath: file.path,
          rawText: rawText,
          bankName: bankName,
          amount: amount,
          galleryDateTime: galleryDateTime,
          receiverName: null,
          isReadable: isReadable,
          isImported: true,
          status: isReadable ? 'ocr read success' : 'ocr read amount failed',

          // ✅ ค่าเริ่มต้น
          slipType: SlipType.expense,
        );

        slipData.add(slip);

        print('ocr read success');
        print('BANK = $bankName');
        print('AMOUNT = $amount');
        print('GALLERY DATE = $galleryDateTime');

        await registry.add(file.path);
      } catch (e, st) {
        print('OCR ERROR IMAGE $index');
        print(e);
        print(st);
      }
    }

    print('SLIP DATA SIZE = ${slipData.length}');

    if (slipData.isNotEmpty) {
      await storage.addAll(slipData);
    }

    return slipData;
  }

  Future<Map<String, int>> scanAllAndCountByBank({int limit = 100}) async {
    await scanAndBuildSlipData(limit: limit);
    return await storage.countByBank();
  }

  Future<void> run({int limit = 100}) async {
    final result = await scanAndBuildSlipData(limit: limit);
    print('AUTO RUN DONE = ${result.length}');
  }
}
