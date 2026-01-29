import 'dart:math';

class SlipParseResult {
  final bool isSlip;
  final double? amount;
  final String? bankName;
  final DateTime? date;
  final String? type; // income/expense (guess)

  const SlipParseResult({
    required this.isSlip,
    this.amount,
    this.bankName,
    this.date,
    this.type,
  });
}

class SlipIdentificationService {
  static final _amountRegex =
  RegExp(r'(?:Amount|ยอดเงิน|จำนวนเงิน|THB|฿)\s*[:\-]?\s*([0-9,]+(?:\.[0-9]{1,2})?)',
      caseSensitive: false);
  static final _dateRegex =
  RegExp(r'(\d{1,2}[/\-]\d{1,2}[/\-]\d{2,4}|\d{4}[-/]\d{1,2}[-/]\d{1,2})');

  static const _banks = [
    'SCB','KBank','Krungthai','Bangkok Bank','BBL','KTB','Krungsri','TTB','UOB','CIMB','SCB ไทยพาณิชย์','กสิกร'
  ];

  SlipParseResult parse(String ocrText) {
    final text = ocrText.replaceAll('\n', ' ');
    final lower = text.toLowerCase();

    final isLikelySlip = [
      'โอนเงินสำเร็จ','ทำรายการสำเร็จ','transfer successful','transaction completed','โอนไปยัง','รับโอน'
    ].any(lower.contains);

    if (!isLikelySlip) {
      // fallback: ถ้ามีทั้งคำว่า transfer และ amount ก็ถือว่าเป็น slip
      if (!(lower.contains('transfer') && _amountRegex.hasMatch(text))) {
        return const SlipParseResult(isSlip: false);
      }
    }

    // amount
    double? amount;
    final m = _amountRegex.firstMatch(text);
    if (m != null) {
      final raw = m.group(1)!.replaceAll(',', '');
      amount = double.tryParse(raw);
    }

    // bank
    String? bank;
    for (final b in _banks) {
      if (lower.contains(b.toLowerCase())) {
        bank = b;
        break;
      }
    }

    // date (best-effort)
    DateTime? dt;
    final d = _dateRegex.firstMatch(text);
    if (d != null) {
      final s = d.group(0)!;
      dt = DateTime.tryParse(_rearrangeDateIfNeeded(s));
    }
    dt ??= DateTime.now();

    // type guess
    String? type;
    if (lower.contains('received') || lower.contains('รับโอน') || lower.contains('credit')) {
      type = 'income';
    } else if (lower.contains('sent') || lower.contains('โอนออก') || lower.contains('debit')) {
      type = 'expense';
    } else {
      // เดาแบบง่าย ๆ
      type = amount != null && Random().nextBool() ? 'expense' : 'income';
    }

    return SlipParseResult(
      isSlip: true,
      amount: amount,
      bankName: bank ?? 'Unknown',
      date: dt,
      type: type,
    );
  }

  String _rearrangeDateIfNeeded(String s) {
    // รองรับรูปแบบ dd/MM/yyyy -> yyyy-MM-dd
    final parts = s.contains('/') ? s.split('/') : s.split('-');
    if (parts.length == 3 && parts[2].length == 4) {
      // dd/MM/yyyy
      return '${parts[2]}-${parts[1].padLeft(2,'0')}-${parts[0].padLeft(2,'0')}';
    }
    return s; // เผื่อเป็น yyyy-MM-dd อยู่แล้ว
  }
}
