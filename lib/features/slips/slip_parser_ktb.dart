class SlipParserKtb {
  Map<String, dynamic> parse(String rawText) {
    final text = rawText;

    final amountRegex = RegExp(r'(\d{1,3}(,\d{3})*(\.\d{2}))');
    final amountMatch = amountRegex.firstMatch(text);

    return {
      'bank': 'Krungthai',
      'amount': amountMatch?.group(1),
      'rawText': rawText,
    };
  }
}