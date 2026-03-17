import 'package:shared_preferences/shared_preferences.dart';

class GalleryAlbumRegistry {
  static const _prefix = 'bank_album_';

  Future<void> setAlbumId(String bankName, String albumId) async {
    final sp = await SharedPreferences.getInstance();
    await sp.setString('$_prefix$bankName', albumId);
  }

  Future<String?> getAlbumId(String bankName) async {
    final sp = await SharedPreferences.getInstance();
    return sp.getString('$_prefix$bankName');
  }

  Future<void> clearAlbumId(String bankName) async {
    final sp = await SharedPreferences.getInstance();
    await sp.remove('$_prefix$bankName');
  }
}