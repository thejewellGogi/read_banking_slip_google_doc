class SlipAmountExtractor {
  static double? extract({
    required String rawText,
    String? bankName,
  }) {
    final text = _normalize(rawText);
    final candidates = <double, int>{};

    void addCandidate(String raw, int score, {String? reason}) {
      final normalized = _normalizeAmountString(raw);
      final value = double.tryParse(normalized);

      if (value == null) return;

      // ต้องมากกว่าหรือเท่ากับ 0.01
      if (value < 0.01) return;

      // กัน account / ref ยาวเกินจริง
      if (value > 10000000) return;

      final current = candidates[value] ?? 0;
      if (score > current) {
        candidates[value] = score;
      }
    }

    // ------------------------------------------------
    // 1) ตัวที่มี currency กำกับ ได้คะแนนสูงสุด
    // ------------------------------------------------
    for (final reg in _currencyPatterns()) {
      for (final m in reg.allMatches(text)) {
        for (int i = 1; i <= m.groupCount; i++) {
          final g = m.group(i);
          if (g == null) continue;

          if (_amountLike(g)) {
            addCandidate(g, 1000, reason: 'currency');
          }
        }
      }
    }

    // ------------------------------------------------
    // 2) ตัวที่อยู่หลัง keyword จำนวนเงิน / amount
    // ------------------------------------------------
    for (final reg in _amountKeywordPatterns(bankName)) {
      for (final m in reg.allMatches(text)) {
        for (int i = 1; i <= m.groupCount; i++) {
          final g = m.group(i);
          if (g == null) continue;

          if (_amountLike(g)) {
            addCandidate(g, 900, reason: 'amount-keyword');
          }
        }
      }
    }

    // ------------------------------------------------
    // 3) จับเลข format มี comma เช่น 12,904.00
    // ------------------------------------------------
    final groupedMatches =
        RegExp(r'\b\d{1,3}(?:[,.]\d{3})+(?:[.,]\d{2})\b').allMatches(text);

    for (final m in groupedMatches) {
      addCandidate(m.group(0)!, 600, reason: 'grouped');
    }

    // ------------------------------------------------
    // 4) จับเลขทศนิยมทั่วไป เช่น 12904.00 หรือ OCR เพี้ยน 2.500.00
    // ------------------------------------------------
    final decimalMatches =
        RegExp(r'\b\d+(?:[.,]\d{2}|\.\d{3}\.\d{2}|(?:\.\d+)+)\b').allMatches(text);

    for (final m in decimalMatches) {
      addCandidate(m.group(0)!, 350, reason: 'decimal');
    }

    // ------------------------------------------------
    // 5) ตัวเลข fallback (เอาไว้น้อยสุด)
    // ------------------------------------------------
    final simpleMatches = RegExp(r'\b\d{1,6}\b').allMatches(text);

    for (final m in simpleMatches) {
      addCandidate(m.group(0)!, 100, reason: 'simple');
    }

    if (candidates.isEmpty) {
      return null;
    }

    final sorted = candidates.entries.toList()
      ..sort((a, b) {
        final scoreCompare = b.value.compareTo(a.value);
        if (scoreCompare != 0) return scoreCompare;
        return b.key.compareTo(a.key);
      });

    print('AMOUNT CANDIDATES = $candidates');
    print('AMOUNT PICKED = ${sorted.first.key}');

    return sorted.first.key;
  }

  static List<RegExp> _currencyPatterns() {
    return [
      RegExp(
        r'([\d.,]+)\s*(บาท|baht|thb|฿|bht|th8|tbh|บาท\.|บาท:|thb\.|thb:)',
      ),
      RegExp(
        r'(บาท|baht|thb|฿|bht|th8|tbh|บาท\.|บาท:|thb\.|thb:)\s*([\d.,]+)',
      ),
    ];
  }

  static List<RegExp> _amountKeywordPatterns(String? bankName) {
    final common = [
      RegExp(r'(จำนวนเงิน|จํานวนเงิน|amount)\s*[:\-]?\s*([\d.,]+)'),
      RegExp(r'(ยอดโอน|ยอดเงิน|รวม)\s*[:\-]?\s*([\d.,]+)'),
    ];

    switch ((bankName ?? '').toLowerCase()) {
      case 'krungthai next':
        return [
          ...common,
          RegExp(r'(จำนวนเงิน|จํานวนเงิน)\s*[:\-]?\s*([\d.,]+)'),
        ];
      case 'k plus':
        return [
          ...common,
          RegExp(r'(amount|จำนวนเงิน)\s*[:\-]?\s*([\d.,]+)'),
        ];
      case 'scb':
        return [
          ...common,
          RegExp(r'(amount|จำนวนเงิน|ยอดเงิน)\s*[:\-]?\s*([\d.,]+)'),
        ];
      case 'bangkok bank':
        return [
          ...common,
          RegExp(r'(amount|ยอดเงิน)\s*[:\-]?\s*([\d.,]+)'),
        ];
      default:
        return common;
    }
  }

  static bool _amountLike(String value) {
    return RegExp(r'^[\d,\.]+$').hasMatch(value.trim());
  }

  static String _normalizeAmountString(String raw) {
    var s = raw.trim();

    // ลบ comma ก่อน
    s = s.replaceAll(',', '');

    // ถ้ามีจุดมากกว่า 1 ตัว เช่น 2.500.00
    final dotCount = '.'.allMatches(s).length;
    if (dotCount > 1) {
      final lastDot = s.lastIndexOf('.');
      final intPart = s.substring(0, lastDot).replaceAll('.', '');
      final decPart = s.substring(lastDot + 1);

      // ต้องมีทศนิยม 2 หลัก ถึงจะถือเป็นจำนวนเงิน
      if (RegExp(r'^\d{2}$').hasMatch(decPart)) {
        s = '$intPart.$decPart';
      } else {
        // fallback: ลบจุดทั้งหมด
        s = s.replaceAll('.', '');
      }
    }

    return s;
  }

  static String _normalize(String input) {
    return input
        .toLowerCase()
        .replaceAll('\n', ' ')
        .replaceAll('\r', ' ')
        .replaceAll('\t', ' ')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
  }
}