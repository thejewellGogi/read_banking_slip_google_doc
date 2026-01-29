import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:image/image.dart' as img;
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import 'package:tesseract_ocr/tesseract_ocr.dart';
// import '../services/tesseract_ocr_wrapper.dart';
import 'package:tesseract_ocr/ocr_engine_config.dart';

class OCRService {
  Future<String> readText(String imagePath) async {
    debugPrint('imagePath ==== $imagePath');

    final bytes = await File(imagePath).readAsBytes();
    final image = img.decodeImage(bytes);
    if (image == null) return '';

    // Grayscale + contrast
    final gray = img.grayscale(image);
    final contrast = img.adjustColor(gray, contrast: 1.5);

    // ✅ สร้างไฟล์ใหม่ใน temp directory ของแอพ
    final cacheDir = await getTemporaryDirectory();
    final tmpPath = p.join(
      cacheDir.path,
      'ocr_${DateTime.now().microsecondsSinceEpoch}.png',
    );
    await File(tmpPath).writeAsBytes(img.encodePng(contrast), flush: true);

    // Debug ตรวจสอบว่ามีไฟล์จริงไหม
    final exists = await File(tmpPath).exists();
    final len = exists ? await File(tmpPath).length() : -1;
    debugPrint('🧪 tmpPath=$tmpPath exists=$exists size=$len');
    if (!exists) throw Exception('Temp image not found at $tmpPath');

    // OCR
    debugPrint('===== Before (Tesseract) =====');
    final text = await TesseractOcr.extractText(
      tmpPath,
      config:const OCRConfig(
        language: 'tha+eng',
        engine: OCREngine.tesseract,
        options: {
          TesseractConfig.pageSegMode: PageSegmentationMode.singleBlock, // "6"
          TesseractConfig.ocrEngineMode: '1', // LSTM only (ถ้าเวอร์ชันรองรับ)
          'preserve_interword_spaces': '1',
          // 'tessedit_char_whitelist': '0123456789./-บาท฿', // ถ้าต้องการจำกัดตัวอักษร
        },
      ),
    );

    debugPrint('===== OCR RAW =====\n$text');
    return text;
  }
}
