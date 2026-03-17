class OcrScanResult {
  final bool success;
  final bool isSlip;
  final String message;
  final String rawText;
  final String? imagePath;
  final List<String> matchedKeywords;
  final int scannedCount;

  const OcrScanResult({
    required this.success,
    required this.isSlip,
    required this.message,
    required this.rawText,
    required this.imagePath,
    required this.matchedKeywords,
    required this.scannedCount,
  });

  factory OcrScanResult.empty(String message) {
    return OcrScanResult(
      success: false,
      isSlip: false,
      message: message,
      rawText: '',
      imagePath: null,
      matchedKeywords: const [],
      scannedCount: 0,
    );
  }
}