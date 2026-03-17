import 'dart:io';
import 'package:photo_manager/photo_manager.dart';

import 'gallery_album_registry.dart';

class GalleryAutoScanner {
  final _registry = GalleryAlbumRegistry();

  Future<bool> _hasGalleryAccess() async {
    final permission = await PhotoManager.requestPermissionExtend();
    return permission.isAuth || permission.isLimited;
  }

  FilterOptionGroup _latestFirstOption() {
    return FilterOptionGroup(
      imageOption: const FilterOption(
        sizeConstraint: SizeConstraint(ignoreSize: true),
      ),
      orders: [
        const OrderOption(
          type: OrderOptionType.createDate,
          asc: false,
        ),
      ],
    );
  }

  /// ดึงรูปใหม่ล่าสุดจาก "All/Recent"
  Future<List<File>> fetchLatestImages({int limit = 30}) async {
    final hasAccess = await _hasGalleryAccess();
    if (!hasAccess) return [];

    final albums = await PhotoManager.getAssetPathList(
      type: RequestType.image,
      onlyAll: true,
      filterOption: _latestFirstOption(),
    );

    if (albums.isEmpty) return [];

    final recent = albums.first;
    final assets = await recent.getAssetListPaged(page: 0, size: limit);

    return _assetToFiles(assets);
  }

  /// ดึงรูปจากอัลบั้มที่ผูกกับธนาคาร
  Future<List<File>> fetchImagesForBank(
    String bankName, {
    int limit = 50,
  }) async {
    final hasAccess = await _hasGalleryAccess();
    if (!hasAccess) return [];

    final album = await _findBankAlbum(bankName);
    if (album == null) return [];

    final assets = await album.getAssetListPaged(page: 0, size: limit);
    return _assetToFiles(assets);
  }

  /// นับจำนวนรูปในอัลบั้มของธนาคาร
  Future<int?> countForBank(String bankName) async {
    final hasAccess = await _hasGalleryAccess();
    if (!hasAccess) return null;

    final album = await _findBankAlbum(bankName);
    if (album == null) return 0;

    return await album.assetCountAsync;
  }

  Future<AssetPathEntity?> _findBankAlbum(String bankName) async {
    final albumId = await _registry.getAlbumId(bankName);
    if (albumId == null) return null;

    final albums = await PhotoManager.getAssetPathList(
      type: RequestType.image,
      hasAll: true,
      onlyAll: false,
      filterOption: _latestFirstOption(),
    );

    for (final album in albums) {
      if (album.id == albumId) {
        return album;
      }
    }

    return null;
  }

  Future<List<File>> _assetToFiles(List<AssetEntity> assets) async {
    final files = <File>[];

    for (final asset in assets) {
      final file = await asset.file;
      if (file != null) {
        files.add(file);
      }
    }

    return files;
  }
}