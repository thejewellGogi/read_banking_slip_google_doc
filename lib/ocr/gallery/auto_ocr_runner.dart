import 'dart:io';
import 'package:photo_manager/photo_manager.dart';

import '../preprocess/preprocess_service.dart';
import '../engines/tesseract_engine.dart';
import '../slip_rated_analyzer.dart';
import 'gallery_auto_scanner.dart';

class AutoOcrRunner {
  final scanner = GalleryAutoScanner();
  final pre = PreprocessService();
  final ocr = TesseractEngine();

  Future<Map<String, int>> scanAllAndCountByBank({int limit = 100}) async {
    print('RUNNER: START');

    final perm = await PhotoManager.requestPermissionExtend();
    final hasGalleryAccess = perm.isAuth || perm.isLimited;

    if (!hasGalleryAccess) {
      return {};
    }

    final List<File> images =
        await scanner.fetchLatestImages(limit: limit);

    if (images.isEmpty) {
      return {};
    }

    print('FOUND IMAGES: ${images.length}');

    final Map<String, int> counts = {};

    int index = 0;

    for (final file in images) {
      index++;

      try {
        print('IMAGE $index');

        final processed = await pre.preprocessSlip(file);
        final rawText = await ocr.recognize(processed.path);

        final analysis = SlipRatedAnalyzer.analyze(rawText);

        final bool isSlip =
            (analysis['isLikelySlip'] as bool?) ?? false;

        final String? bankName =
            analysis['bankName'] as String?;

        if (isSlip && bankName != null) {
          counts[bankName] = (counts[bankName] ?? 0) + 1;

          print('FOUND $bankName');
        }
      } catch (e) {
        print('ERROR $index');
      }
    }

    print('RESULT = $counts');

    return counts;
  }
}