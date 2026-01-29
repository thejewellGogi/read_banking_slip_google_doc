// lib/services/ocr_service.dart
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:tesseract_ocr/tesseract_ocr.dart';
import 'package:image/image.dart' as img;
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;

class OCRResult {
  final String text;
  final String imagePath; // ✅ path ของไฟล์ preprocess

  OCRResult(this.text, this.imagePath);
}

class OCRService {
  Future<OCRResult> readText(String imagePath) async {
    debugPrint('------ OCR Service Start ------');
    debugPrint('imagePath ==== $imagePath');

    final bytes = await File(imagePath).readAsBytes();
    final image = img.decodeImage(bytes);
    if (image == null) return OCRResult('', imagePath);

    // ✅ Preprocess
    final gray = img.grayscale(image);
    final contrast = img.adjustColor(gray, contrast: 1.5);

    // ✅ Save tmp
    final cacheDir = await getTemporaryDirectory();
    final tmpPath = p.join(
      cacheDir.path,
      'ocr_${DateTime.now().microsecondsSinceEpoch}.png',
    );
    await File(tmpPath).writeAsBytes(img.encodePng(contrast), flush: true);

    final exists = await File(tmpPath).exists();
    final len = exists ? await File(tmpPath).length() : -1;
    debugPrint('🧪 Preprocess tmpPath=$tmpPath exists=$exists size=$len');

    // ✅ OCR
    debugPrint('===== Before (Tesseract) =====');
    final text = await TesseractOcr.extractText(tmpPath);
    // final text = await TesseractOcr.extractText(
    //   tmpPath,
    //   config: OCRConfig(
    //     language: 'tha+eng',
    //     engine: OCREngine.tesseract,
    //     options: {
    //       TesseractConfig.pageSegMode: PageSegmentationMode.singleBlock, // "6"
    //       TesseractConfig.ocrEngineMode: '1', // LSTM only (ถ้าเวอร์ชันรองรับ)
    //       'preserve_interword_spaces': '1',
    //       // 'tessedit_char_whitelist': '0123456789./-บาท฿', // ถ้าต้องการจำกัดตัวอักษร
    //     },
    //   ),
    // );
    debugPrint('===== OCR RAW (Tesseract) =====\n$text');
    debugPrint('------ END OCR Service ------');

    return OCRResult(text, tmpPath); // คืน path
  }
}
