// lib/services/ocr_service.dart
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:image/image.dart' as img;
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;

import '../utils/ocr_runner.dart'; // << ใช้ runThaiOcr

class OCRResult {
  final String text;
  final String imagePath; // path ของไฟล์หลัง preprocess
  OCRResult(this.text, this.imagePath);
}

class OCRService {
  Future<OCRResult> readText(String imagePath) async {
    if (kDebugMode) {
      debugPrint('------ OCR Service Start ------');
      debugPrint('imagePath ==== $imagePath');
    }

    final bytes = await File(imagePath).readAsBytes();
    final decoded = img.decodeImage(bytes);
    if (decoded == null) return OCRResult('', imagePath);

    // Preprocess: grayscale + contrast (ลองปรับค่าได้)
    final gray = img.grayscale(decoded);
    final boosted = img.adjustColor(gray, contrast: 3);

    // เขียนไฟล์ชั่วคราวลง cache
    final cacheDir = await getTemporaryDirectory();
    final tmpPath = p.join(
      cacheDir.path,
      'ocr_${DateTime.now().microsecondsSinceEpoch}.png',
    );
    await File(tmpPath).writeAsBytes(img.encodePng(boosted), flush: true);

    // log ไฟล์ preprocess
    final exists = await File(tmpPath).exists();
    final size = exists ? await File(tmpPath).length() : -1;
    if (kDebugMode) {
      debugPrint('🧪 Preprocess tmpPath=$tmpPath exists=$exists size=$size');
      debugPrint('===== Before (Tesseract) =====');
    }

    // ✅ เรียก OCR แบบกำหนดภาษา tha+eng ผ่าน runThaiOcr
    final text = await runThaiOcr(tmpPath);

    if (kDebugMode) {
      debugPrint('------ END OCR Service ------');
    }

    return OCRResult(text, tmpPath);
  }
}
