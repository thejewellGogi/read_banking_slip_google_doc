class SlipRatedAnalyzer {
  static Map<String, dynamic> analyze(String rawText) {
    final text = _normalize(rawText);

    final matchedKeywords = <String>[];
    int score = 0;

    bool hasAny(List<String> keywords, {int addScore = 1}) {
      for (final k in keywords) {
        final kw = k.toLowerCase();

        if (text.contains(kw)) {
          matchedKeywords.add(k);
          score += addScore;
          return true;
        }
      }
      return false;
    }

    final bankMap = <String, List<String>>{
      'Bangkok Bank': ['bangkok bank', 'ธนาคารกรุงเทพ', 'กรุงเทพ', 'bbl'],
      'K PLUS': [
        'k plus',
        'kasikorn',
        'kasikornbank',
        'ธนาคารกสิกรไทย',
        'กสิกร',
        'kbank',
      ],
      'Krungthai NEXT': [
        'กรุงไทย',
        'krungthai',
        'krung thai',
        'ktb',
        'กรงไทย',
        'กรุไทย',
        'ธนาคารกรุงไทย',
      ],
      'SCB': ['scb', 'siam commercial bank', 'ธนาคารไทยพาณิชย์', 'ไทยพาณิชย์'],
      'Krungsri': [
        'krungsri',
        'bank of ayudhya',
        'ธนาคารกรุงศรีอยุธยา',
        'กรุงศรี',
        'bay',
      ],
      'ttb': ['ttb', 'tmbthanachart', 'ธนาคารทีเอ็มบีธนชาต', 'ธนชาต', 'ทีทีบี'],
      'UOB': ['uob', 'ธนาคารยูโอบี', 'ยูโอบี'],
      'CIMB Thai': ['cimb', 'cimb thai', 'ธนาคารซีไอเอ็มบี ไทย', 'ซีไอเอ็มบี'],
      'Kiatnakin Phatra': [
        'kiatnakin',
        'phatra',
        'kiatnakin phatra',
        'ธนาคารเกียรตินาคินภัทร',
        'เกียรตินาคิน',
      ],
      'TISCO': ['tisco', 'ธนาคารทิสโก้', 'ทิสโก้'],
      'LH Bank': [
        'land and houses bank',
        'lh bank',
        'ธนาคารแลนด์ แอนด์ เฮ้าส์',
        'แลนด์ แอนด์ เฮ้าส์',
      ],
      'Thai Credit': [
        'thai credit',
        'the thai credit retail bank',
        'ธนาคารไทยเครดิต',
        'ไทยเครดิต',
      ],
      'ICBC Thai': ['icbc', 'icbc thai', 'ธนาคารไอซีบีซี'],
      'Bank of China Thai': [
        'bank of china',
        'bank of china thai',
        'ธนาคารแห่งประเทศจีน',
      ],
    };

    String? detectedBank;

    for (final entry in bankMap.entries) {
      final found = hasAny(entry.value, addScore: 3);
      if (found) {
        detectedBank = entry.key;
        break;
      }
    }

    final hasMoney = hasAny([
      'จำนวนเงิน',
      'จํานวนเงิน',
      'บาท',
      'baht',
      'amount',
    ]);

    final hasDateTime = hasAny([
      'วันที่',
      'เวลา',
      'date',
      'time',
      'ทํารายการ',
      'ทำรายการ',
    ]);

    final hasTransfer = hasAny([
      'โอนเงิน',
      'transfer',
      'ผู้โอน',
      'ผู้รับโอน',
      'เลขที่รายการ',
      'บัญชี',
      'สำเร็จ',
      'success',
    ]);

    final amountPattern = RegExp(r'\d{1,3}(,\d{3})*(\.\d{2})');
    if (amountPattern.hasMatch(text)) {
      matchedKeywords.add('amount-pattern');
      score += 1;
    }

    final isLikelySlip =
        detectedBank != null ||
        (score >= 3) ||
        ((hasMoney || hasDateTime) && hasTransfer);

    return {
      'isLikelySlip': isLikelySlip,
      'bankName': detectedBank,
      'score': score,
      'matchedKeywords': matchedKeywords.toSet().toList(),
    };
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
