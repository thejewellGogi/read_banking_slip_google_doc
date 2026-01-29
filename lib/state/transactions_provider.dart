import 'package:flutter/foundation.dart';
import '../services/database_service.dart';
import '../models/transaction_model.dart';

class TransactionsProvider extends ChangeNotifier {
  final AppDatabase db;
  TransactionsProvider(this.db);

  final List<TransactionModel> _latest = [];
  List<TransactionModel> get latest => List.unmodifiable(_latest);

  bool _loading = false;
  bool get loading => _loading;
  Object? _error;
  Object? get error => _error;

  Future<void> refresh() async {
    _loading = true;
    _error = null;
    notifyListeners();

    try {
      final rows = await db.latestTransactions();
      _latest
        ..clear()
        ..addAll(rows);

      if (kDebugMode) {
        print('TP.refresh -> count=${_latest.length}');
        if (_latest.isNotEmpty) {
          final t = _latest.first;
          print('first: id=${t.id} bank=${t.bankName} amount=${t.amount} date=${t.transactionDate}');
        }
      }
    } catch (e) {
      _error = e;
      if (kDebugMode) print('TP.refresh error: $e');
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  Future<void> toggleType(int id, String current) async {
    final next = current == 'income' ? 'expense' : 'income';
    await db.updateType(id, next);
    await refresh();
  }

  Future<void> remove(int id) async {
    await db.deleteTransaction(id);
    await refresh();
  }
}
