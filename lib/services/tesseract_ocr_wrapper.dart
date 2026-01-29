// lib/services/tesseract_ocr_wrapper.dart
import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart';
import 'package:tesseract_ocr/ocr_engine_config.dart';

class TesseractOcr {
  static const String TESS_DATA_CONFIG = 'assets/tessdata_config.json';
  static const String TESS_DATA_PATH = 'assets/tessdata';
  static const MethodChannel _channel = MethodChannel('tesseract_ocr');

  static Future<String> extractText(
    String imagePath, {
    OCRConfig? config,
  }) async {
    assert(await File(imagePath).exists(), true);

    final actualConfig = config ?? const OCRConfig();

    String? tessDataPath;
    if (actualConfig.engine != OCREngine.vision) {
      tessDataPath = await _loadTessData();
    }

    final Map<String, dynamic> args = {
      'imagePath': imagePath,
      'tessData': tessDataPath,
      'language': actualConfig.language,
    };

    // 🟢 เพิ่ม log ตรงนี้
    if (kDebugMode) {
      debugPrint(
        '➡️ OCR call -> lang=${actualConfig.language}, tessData=$tessDataPath, image=$imagePath',
      );
    }

    final String extractedText = await _channel.invokeMethod(
      'extractText',
      args,
    );

    if (kDebugMode) {
      debugPrint('✅ OCR result length=${extractedText.length}');
      debugPrint('📝 OCR result preview:\n${extractedText.substring(0, extractedText.length > 200 ? 200 : extractedText.length)}');
    }

    return extractedText;
  }

  static Future<String> _loadTessData() async {
    final Directory appDirectory = await getApplicationDocumentsDirectory();
    final String tessdataDirectory = join(appDirectory.path, 'tessdata');

    if (!await Directory(tessdataDirectory).exists()) {
      await Directory(tessdataDirectory).create();
    }
    await _copyTessDataToAppDocumentsDirectory(tessdataDirectory);
    return appDirectory.path;
  }

  static Future _copyTessDataToAppDocumentsDirectory(
    String tessdataDirectory,
  ) async {
    final String config = await rootBundle.loadString(TESS_DATA_CONFIG);
    Map<String, dynamic> files = jsonDecode(config);
    for (var file in files["files"]) {
      final assetPath = join(TESS_DATA_PATH, file);
      final destPath = join(tessdataDirectory, file);

      if (!await File(destPath).exists()) {
        final ByteData data = await rootBundle.load(assetPath);
        final Uint8List bytes = data.buffer.asUint8List(
          data.offsetInBytes,
          data.lengthInBytes,
        );
        await File(destPath).writeAsBytes(bytes);

        if (kDebugMode) {
          debugPrint('📂 Copied $file -> $destPath');
        }
      } else {
        if (kDebugMode) {
          debugPrint('ℹ️ Already exists: $file');
        }
      }
    }
  }
}
