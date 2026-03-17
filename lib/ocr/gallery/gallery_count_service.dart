import 'package:photo_manager/photo_manager.dart';
import 'gallery_album_registry.dart';

class GalleryCountService {
  final _registry = GalleryAlbumRegistry();

  Future<int?> countForBank(String bankName) async {
    final perm = await PhotoManager.requestPermissionExtend();
    if (!perm.isAuth) return null;

    final albumId = await _registry.getAlbumId(bankName);
    if (albumId == null) return 0; // ยังไม่ผูกอัลบั้ม

    // หาอัลบั้มตาม id
    final albums = await PhotoManager.getAssetPathList(
      type: RequestType.image,
      hasAll: true,
      onlyAll: false,
    );

    final match = albums.where((a) => a.id == albumId).toList();
    if (match.isEmpty) return 0;

    final album = match.first;
    final c = await album.assetCountAsync;
    return c;
  }

  Future<List<AssetPathEntity>> listAlbums() async {
    final perm = await PhotoManager.requestPermissionExtend();
    if (!perm.isAuth) return [];

    return PhotoManager.getAssetPathList(
      type: RequestType.image,
      hasAll: true,
      onlyAll: false,
    );
  }

  Future<void> bindBankToAlbum(String bankName, String albumId) async {
    await _registry.setAlbumId(bankName, albumId);
  }
}