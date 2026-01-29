import 'dart:async';
import 'package:flutter/material.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';
import '../models/transaction_model.dart';

class AppDatabase {
  AppDatabase._();
  static final AppDatabase instance = AppDatabase._();

  late Database db;

  Future<AppDatabase> init() async {
    final dir = await getApplicationDocumentsDirectory();
    final path = join(dir.path, 'read_slip.db');

    debugPrint('DB PATH => $path'); 
    db = await openDatabase(
      path,
      version: 1,
      onCreate: (d, v) async {
        await d.execute('''
          CREATE TABLE processed_images(
            image_path TEXT PRIMARY KEY,
            processed_at TEXT NOT NULL
          );
        ''');

        await d.execute('''
          CREATE TABLE transactions(
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            image_path TEXT,  
            amount REAL NOT NULL,
            bank_name TEXT NOT NULL,
            transaction_date TEXT NOT NULL,
            type TEXT NOT NULL CHECK(type IN ('income','expense')),
            FOREIGN KEY(image_path) REFERENCES processed_images(image_path)
          );
        ''');
      },
    );
    return this;
  }

  // processed_images
  Future<bool> isProcessed(String imagePath) async {
    final res = await db.query('processed_images',
        where: 'image_path = ?', whereArgs: [imagePath], limit: 1);
    return res.isNotEmpty;
  }

  Future<void> markProcessed(String imagePath) async {
    await db.insert('processed_images', {
      'image_path': imagePath,
      'processed_at': DateTime.now().toIso8601String(),
    }, conflictAlgorithm: ConflictAlgorithm.ignore);
  }

  // transactions CRUD (เฉพาะที่ต้องใช้)
  Future<int> insertTransaction(TransactionModel t) async {
    return db.insert('transactions', t.toMap());
  }

  Future<List<TransactionModel>> latestTransactions({int limit = 20}) async {
    final rows = await db.query('transactions',
        orderBy: 'transaction_date DESC', limit: limit);
    return rows.map(TransactionModel.fromMap).toList();
  }

  Future<void> updateType(int id, String newType) async {
    await db.update('transactions', {'type': newType},
        where: 'id = ?', whereArgs: [id]);
  }

  Future<void> deleteTransaction(int id) async {
    await db.delete('transactions', where: 'id = ?', whereArgs: [id]);
  }

  // สรุปรายวัน/เดือน/ปีแบบง่าย
  Future<Map<String, double>> sumByTypeBetween(DateTime start, DateTime end) async {
    final rows = await db.rawQuery('''
      SELECT type, SUM(amount) as total
      FROM transactions
      WHERE transaction_date >= ? AND transaction_date < ?
      GROUP BY type
    ''', [start.toIso8601String(), end.toIso8601String()]);
    final map = <String, double>{'income': 0, 'expense': 0};
    for (final r in rows) {
      map[r['type'] as String] = (r['total'] as num).toDouble();
    }
    return map;
  }
}
