enum SlipType {
  income,
  expense,
}

class SlipDataModel {
  final String id;
  final String imagePath;
  final String rawText;
  final String? bankName;

  final double? amount;
  final DateTime? galleryDateTime;
  final String? receiverName;

  final bool isReadable;
  final bool isImported;
  final String status;

  // ✅ เพิ่ม
  final SlipType slipType;

  const SlipDataModel({
    required this.id,
    required this.imagePath,
    required this.rawText,
    this.bankName,
    this.amount,
    this.galleryDateTime,
    this.receiverName,
    this.isReadable = false,
    this.isImported = false,
    this.status = '',

    // ✅ ค่าเริ่มต้นเป็นรายจ่าย
    this.slipType = SlipType.expense,
  });

  SlipDataModel copyWith({
    String? id,
    String? imagePath,
    String? rawText,
    String? bankName,
    double? amount,
    DateTime? galleryDateTime,
    String? receiverName,
    bool? isReadable,
    bool? isImported,
    String? status,
    SlipType? slipType,
  }) {
    return SlipDataModel(
      id: id ?? this.id,
      imagePath: imagePath ?? this.imagePath,
      rawText: rawText ?? this.rawText,
      bankName: bankName ?? this.bankName,
      amount: amount ?? this.amount,
      galleryDateTime: galleryDateTime ?? this.galleryDateTime,
      receiverName: receiverName ?? this.receiverName,
      isReadable: isReadable ?? this.isReadable,
      isImported: isImported ?? this.isImported,
      status: status ?? this.status,
      slipType: slipType ?? this.slipType,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'imagePath': imagePath,
      'rawText': rawText,
      'bankName': bankName,
      'amount': amount,
      'galleryDateTime': galleryDateTime?.toIso8601String(),
      'receiverName': receiverName,
      'isReadable': isReadable,
      'isImported': isImported,
      'status': status,
      'slipType': slipType.name,
    };
  }

  factory SlipDataModel.fromJson(Map<String, dynamic> json) {
    return SlipDataModel(
      id: json['id'] as String? ?? '',
      imagePath: json['imagePath'] as String? ?? '',
      rawText: json['rawText'] as String? ?? '',
      bankName: json['bankName'] as String?,
      amount: (json['amount'] as num?)?.toDouble(),
      galleryDateTime: json['galleryDateTime'] != null
          ? DateTime.tryParse(json['galleryDateTime'] as String)
          : null,
      receiverName: json['receiverName'] as String?,
      isReadable: json['isReadable'] as bool? ?? false,
      isImported: json['isImported'] as bool? ?? false,
      status: json['status'] as String? ?? '',
      slipType: _parseSlipType(json['slipType']),
    );
  }

  static SlipType _parseSlipType(dynamic value) {
    final v = (value as String?)?.toLowerCase().trim();

    switch (v) {
      case 'income':
        return SlipType.income;
      case 'expense':
        return SlipType.expense;
      default:
        return SlipType.expense;
    }
  }
}