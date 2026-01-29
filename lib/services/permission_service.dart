import 'package:permission_handler/permission_handler.dart';

class PermissionService {
  static Future<bool> ensurePhotoPermission() async {
    // Android 13+ ใช้ Photo Picker ได้โดยไม่ต้องขอ แต่เผื่อไว้
    final status = await Permission.photos.request();
    return status.isGranted;
  }
}
