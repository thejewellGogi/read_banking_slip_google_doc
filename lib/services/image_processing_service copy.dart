// lib/services/image_processing_service.dart
import 'dart:io';
import 'dart:isolate';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:image/image.dart' as img;
import 'package:path_provider/path_provider.dart';
import '../models/transaction_model.dart';
import 'database_service.dart';
import 'ocr_service.dart';              // ✅ ใช้ OCRService
import '../utils/ocr_utils.dart';

class ImageProcessingService {
  final AppDatabase db;
  final OCRService ocr;                // ✅ inject OCRService

  ImageProcessingService(this.db, this.ocr);

  /// ---- Utility: Threshold ----
  img.Image applyThreshold(img.Image src, int threshold) {
    final out = img.Image.from(src);
    for (int y = 0; y < out.height; y++) {
      for (int x = 0; x < out.width; x++) {
        final c = out.getPixel(x, y);
        final luma = img.getLuminance(c);
        out.setPixelRgba(
          x,
          y,
          luma < threshold ? 0 : 255,
          luma < threshold ? 0 : 255,
          luma < threshold ? 0 : 255,
          255,
        );
      }
    }
    return out;
  }

  /// 1) งานหนัก: resize + preprocess ใน Isolate
  Future<Uint8List> prepareBytes(Uint8List bytes,
      {int maxWidth = 1600, int threshold = 195, bool doThreshold = true}) async {
    return await Isolate.run(() {
      final decoded = img.decodeImage(bytes);
      if (decoded == null) return bytes;

      var im = img.bakeOrientation(decoded);
      if (im.width > maxWidth) {
        im = img.copyResize(im, width: maxWidth);
      }
      im = img.grayscale(im);
      im = img.adjustColor(im, contrast: 1.2, brightness: 0.02);

      if (doThreshold) {
        im = applyThreshold(im, threshold);
      }

      return Uint8List.fromList(img.encodePng(im));
    });
  }

  /// 2) Pipeline: read -> preprocess -> OCR -> parse -> (insert DB)
  Future<void> processImagePathOptimized(String originalPath) async {
    final raw = await File(originalPath).readAsBytes();

    final prepped = await prepareBytes(raw);
    final tmpDir = await getTemporaryDirectory();
    final tmpFile = File('${tmpDir.path}/ocr_${DateTime.now().microsecondsSinceEpoch}.png');
    await tmpFile.writeAsBytes(prepped, flush: true);
    debugPrint('------Befor OCR Service');
    final text = await ocr.readText(tmpFile.path);  // ✅ ใช้ OCRService
    debugPrint('------END OCR Service');
    // Parse
    // final bank = OcrUtils.extractBank(text) ?? 'Unknown';
    // final amount = OcrUtils.extractAmount(text) ?? 0.0;
    // final when = OcrUtils.extractThaiDate(text) ?? DateTime.now();

    // if (kDebugMode) {
    //   debugPrint('Parsed -> bank=$bank, amount=$amount, date=$when');
    // }

    // try {
    //   if (amount > 0) {
    //     final tx = TransactionModel(
    //       imagePath: originalPath,
    //       bankName: bank,
    //       amount: amount,
    //       transactionDate: when,
    //       type: 'expense',
    //     );
    //     await db.insertTransaction(tx);
    //     debugPrint("✅ Inserted: ${tx.toMap()}");
    //   }
    // } catch (e) {
    //   debugPrint("❌ DB Insert Error: $e");
    // } finally {
    //   await tmpFile.delete().catchError((_) {});
    // }
  }

  Future<void> processImagePath(String path) => processImagePathOptimized(path);
}
