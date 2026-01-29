
class TransactionModel {
  final int? id;
  final String? imagePath;
  final double amount;
  final String bankName;
  final DateTime transactionDate;
  final String type;  

  TransactionModel({
    this.id,
    this.imagePath,
    required this.amount,
    required this.bankName,
    required this.transactionDate,
    required this.type,
  });

  Map<String, dynamic> toMap() => {
        'id': id,
        'image_path': imagePath,
        'amount': amount,
        'bank_name': bankName,
        'transaction_date': transactionDate.toIso8601String(),
        'type': type, // enum -> string
      };

  factory TransactionModel.fromMap(Map<String, dynamic> m) => TransactionModel(
        id: m['id'] as int?,
        imagePath: m['image_path'] as String?,
        amount: (m['amount'] as num).toDouble(),
        bankName: m['bank_name'] as String,
        transactionDate: DateTime.parse(m['transaction_date'] as String),
        type: m['type'] as String,
      );
}
