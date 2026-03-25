import 'dart:convert';
import 'dart:io';

import 'package:path_provider/path_provider.dart';

import '../models/slip_data_model.dart';

class SlipStorageService {
  static const String _fileName = 'slip_data.json';

  Future<File> _file() async {
    final dir = await getApplicationDocumentsDirectory();
    return File('${dir.path}/$_fileName');
  }

  Future<List<SlipDataModel>> loadAll() async {
    try {
      final file = await _file();

      if (!await file.exists()) {
        return [];
      }

      final text = await file.readAsString();

      if (text.trim().isEmpty) {
        return [];
      }

      final decoded = jsonDecode(text) as List<dynamic>;

      return decoded
          .map((e) => SlipDataModel.fromJson(Map<String, dynamic>.from(e)))
          .toList();
    } catch (e) {
      print('SlipStorageService.loadAll ERROR: $e');
      return [];
    }
  }

  Future<void> saveAll(List<SlipDataModel> slips) async {
    try {
      final file = await _file();
      final raw = slips.map((e) => e.toJson()).toList();

      await file.writeAsString(
        jsonEncode(raw),
        mode: FileMode.write,
        flush: true,
      );
    } catch (e) {
      print('SlipStorageService.saveAll ERROR: $e');
    }
  }

  Future<void> addAll(List<SlipDataModel> slips) async {
    if (slips.isEmpty) return;

    final current = await loadAll();

    final existingIds = current.map((e) => e.id).toSet();

    for (final slip in slips) {
      if (!existingIds.contains(slip.id)) {
        current.add(slip);
      }
    }

    await saveAll(current);
  }

  Future<List<SlipDataModel>> loadAllSortedByDateDesc() async {
    final slips = await loadAll();

    slips.sort((a, b) {
      final ad = a.galleryDateTime ?? DateTime(2000);
      final bd = b.galleryDateTime ?? DateTime(2000);
      return bd.compareTo(ad);
    });

    return slips;
  }

  Future<List<SlipDataModel>> loadByMonth(int year, int month) async {
    final slips = await loadAll();

    return slips.where((e) {
      final dt = e.galleryDateTime;
      return dt != null && dt.year == year && dt.month == month;
    }).toList();
  }

  Future<void> addOne(SlipDataModel slip) async {
    final current = await loadAll();
    current.add(slip);
    await saveAll(current);
  }

  Future<void> updateOne(SlipDataModel updated) async {
    final current = await loadAll();
    final index = current.indexWhere((e) => e.id == updated.id);

    if (index == -1) return;

    current[index] = updated;
    await saveAll(current);
  }

  Future<void> removeById(String id) async {
    final current = await loadAll();
    current.removeWhere((e) => e.id == id);
    await saveAll(current);
  }

  Future<void> clear() async {
    final file = await _file();
    if (await file.exists()) {
      await file.writeAsString('[]', flush: true);
    }
  }

  Future<Map<String, int>> countByBank() async {
    final slips = await loadAll();
    final result = <String, int>{};

    for (final slip in slips) {
      final bank = slip.bankName;
      if (bank == null || bank.isEmpty) continue;
      result[bank] = (result[bank] ?? 0) + 1;
    }

    return result;
  }
}
