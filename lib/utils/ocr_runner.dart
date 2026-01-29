// lib/utils/ocr_runner.dart
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:tesseract_ocr/tesseract_ocr.dart';
import 'package:tesseract_ocr/ocr_engine_config.dart';

Future<String> runThaiOcr(String preprocessedPath) async {
  // เช็คไฟล์ก่อน
  final f = File(preprocessedPath);
  final exists = await f.exists();
  final size = exists ? await f.length() : -1;
  if (kDebugMode) {
    debugPrint('🧪 OCR input: $preprocessedPath exists=$exists size=$size');
  }

  // เรียก Tesseract แบบกำหนดภาษา/PSM/OEM
  final text = await TesseractOcr.extractText(
    preprocessedPath,
    config: OCRConfig(
      language: 'tha+eng',
      engine: OCREngine.tesseract,
      options: {
        TesseractConfig.pageSegMode: PageSegmentationMode.singleBlock, // psm=6
        TesseractConfig.ocrEngineMode: '1',                            // LSTM
        'preserve_interword_spaces': '1',
        // 'tessedit_char_whitelist': '๐๑๒๓๔๕๖๗๘๙0123456789.,:/-บาท฿',
      },
    ),
  );
  final textEn = await TesseractOcr.extractText(
    preprocessedPath,
    config: OCRConfig(
      language: 'eng',
      engine: OCREngine.tesseract,
      options: {
        TesseractConfig.pageSegMode: PageSegmentationMode.singleBlock, // psm=6
        TesseractConfig.ocrEngineMode: '1',                            // LSTM
        'preserve_interword_spaces': '1',
        // 'tessedit_char_whitelist': '๐๑๒๓๔๕๖๗๘๙0123456789.,:/-บาท฿',
      },
    ),
  );

  if (kDebugMode) {
    debugPrint('===== OCR RAW =====\n$text');
    debugPrint('✅ OCR length=${text.length}');
    debugPrint('===== OCR RAW En=====\n$textEn');
    debugPrint('✅ OCR En length=${textEn.length}');
  }

  // ถ้ายังว่าง ลอง PSM อื่น ๆ
  // if (text.trim().isEmpty) {
  //   for (final psm in [
  //     PageSegmentationMode.singleLine,     // 7
  //     PageSegmentationMode.sparseText,     // 10
  //     PageSegmentationMode.sparseTextOsd,  // 11
  //     PageSegmentationMode.auto,           // 3
  //   ]) {
  //     if (kDebugMode) debugPrint('🔁 Retry OCR with PSM=$psm');
  //     final retry = await TesseractOcr.extractText(
  //       preprocessedPath,
  //       config: OCRConfig(
  //         language: 'tha+eng',
  //         engine: OCREngine.tesseract,
  //         options: {
  //           TesseractConfig.pageSegMode: psm,
  //           TesseractConfig.ocrEngineMode: '1',
  //           'preserve_interword_spaces': '1',
  //         },
  //       ),
  //     );
  //     if (retry.trim().isNotEmpty) return retry;
  //   }
  // }

  return text;
}
