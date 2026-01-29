// lib/utils/ocr_utils.dart
class OcrUtils {
  /// ------------------------
  /// BANK DETECTION
  /// ------------------------
  static String? extractBank(String text) {
    final banks = <String, List<String>>{
      'KBank': ['KBank', 'กสิกร', 'ธนาคารกสิกร','K+'],
      'SCB': ['SCB', 'ไทยพาณิชย์'],
      'Krungthai': ['Krungthai', 'กรุงไทย', 'KTB'],
      'Bangkok Bank': ['Bangkok Bank', 'กรุงเทพ', 'BBL'],
      'Krungsri': ['Krungsri', 'กรุงศรี', 'BAY'],
      'TTB': ['ttb', 'ทหารไทยธนชาต'],
    };

    for (final entry in banks.entries) {
      for (final keyword in entry.value) {
        if (text.toLowerCase().contains(keyword.toLowerCase())) {
          return entry.key;
        }
      }
    }
    return null;
  }

  /// ------------------------
  /// AMOUNT PARSER
  /// ------------------------
  static double? extractAmount(String text) {
    final rex = RegExp(
        r'(\d{1,3}(?:,\d{3})*(?:\.\d{2})|\d+\.\d{2})'); // match 1,234.56 หรือ 1234.56
    final m = rex.firstMatch(text.replaceAll('\n', ' '));
    if (m == null) return null;
    final cleaned = m.group(1)!.replaceAll(',', '');
    return double.tryParse(cleaned);
  }

  /// ------------------------
  /// THAI MONTH LOOKUP
  /// ------------------------
  static final Map<String, int> thMonths = {
    'ม.ค.': 1,
    'ก.พ.': 2,
    'มี.ค.': 3,
    'เม.ย.': 4,
    'พ.ค.': 5,
    'มิ.ย.': 6,
    'ก.ค.': 7,
    'ส.ค.': 8,
    'ก.ย.': 9,
    'ต.ค.': 10,
    'พ.ย.': 11,
    'ธ.ค.': 12,
    'มกราคม': 1,
    'กุมภาพันธ์': 2,
    'มีนาคม': 3,
    'เมษายน': 4,
    'พฤษภาคม': 5,
    'มิถุนายน': 6,
    'กรกฎาคม': 7,
    'สิงหาคม': 8,
    'กันยายน': 9,
    'ตุลาคม': 10,
    'พฤศจิกายน': 11,
    'ธันวาคม': 12,
  };

  /// ------------------------
  /// DATE PARSER
  /// ------------------------
  static DateTime? extractThaiDate(String text) {
    final flat = text.replaceAll('\n', ' ');

    // รูปแบบ dd/MM/yyyy
    final m1 = RegExp(r'\b(\d{1,2})/(\d{1,2})/(\d{4})\b').firstMatch(flat);
    if (m1 != null) {
      final d = int.parse(m1.group(1)!);
      final m = int.parse(m1.group(2)!);
      final y = int.parse(m1.group(3)!);
      return DateTime(y, m, d);
    }

    // รูปแบบ 1 ก.ย. 2568
    final m2 =
        RegExp(r'\b(\d{1,2})\s+([ก-ฮ\.]+)\s+(\d{4})\b').firstMatch(flat);
    if (m2 != null) {
      final d = int.parse(m2.group(1)!);
      final monName = m2.group(2)!;
      final yBE = int.parse(m2.group(3)!);
      final m = thMonths.entries
          .firstWhere((e) => monName.contains(e.key),
              orElse: () => const MapEntry('', 0))
          .value;
      if (m != 0) {
        final yCE = yBE > 2400 ? (yBE - 543) : yBE; // พ.ศ. -> ค.ศ.
        return DateTime(yCE, m, d);
      }
    }
    return null;
  }
}
