import 'package:flutter_tesseract_ocr/flutter_tesseract_ocr.dart';

class TesseractEngine {
  Future<String> recognize(String imagePath) async {
    print("TESSERACT: start image=$imagePath");

    final text = await FlutterTesseractOcr.extractText(
      imagePath,
      language: "tha+eng",
      args: {
        "psm": "11",
        "oem": "1",
        "preserve_interword_spaces": "1",
      },
    );

    print("TESSERACT: done");
    return text;
  }
}