import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';

class OCRService {
  final TextRecognizer _textRecognizer =
      TextRecognizer(script: TextRecognitionScript.latin);

  Future<String> readText(String imagePath) async {
    final inputImage = await InputImage.fromFilePath(imagePath);
    final RecognizedText result =
        await _textRecognizer.processImage(inputImage);
    return result.text;
  }

  Future<void> dispose() async {
    await _textRecognizer.close();
  }
}
