import 'dart:io';
import 'package:path_provider/path_provider.dart';

class ScannedRegistry {

  Future<File> _dbFile() async {
    final dir = await getApplicationDocumentsDirectory();
    return File('${dir.path}/scanned.txt');
  }

  Future<Set<String>> load() async {
    final f = await _dbFile();

    if (!await f.exists()) {
      return {};
    }

    final lines = await f.readAsLines();

    return lines.toSet();
  }

  Future<void> add(String path) async {
    final f = await _dbFile();

    final set = await load();

    if (set.contains(path)) {
      return;
    }

    await f.writeAsString(
      "$path\n",
      mode: FileMode.append,
    );
  }

  Future<bool> already(String path) async {
    final set = await load();
    return set.contains(path);
  }

  /// ใช้ตอน debug
  Future<void> clear() async {
    final f = await _dbFile();

    if (await f.exists()) {
      await f.writeAsString("");
    }
  }
}