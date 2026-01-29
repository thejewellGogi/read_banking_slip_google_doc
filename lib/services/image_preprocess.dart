// lib/services/image_preprocess.dart
import 'dart:io';
import 'package:image/image.dart' as img;
import 'package:path_provider/path_provider.dart';

class ImagePreprocess {
  /// ปรับภาพให้เหมาะกับ OCR: grayscale + contrast + threshold + resize
  /// คืนค่า path ของไฟล์ภาพที่ปรับแล้ว (PNG) ใน temp
  static Future<String> preprocessForOcr(String inputPath) async {
    final f = File(inputPath);
    if (!await f.exists()) {
      throw Exception('Image not found: $inputPath');
    }

    // 1) อ่านภาพ
    final bytes = await f.readAsBytes();
    img.Image? im = img.decodeImage(bytes);
    if (im == null) throw Exception('Cannot decode image');

    // 2) แก้ EXIF rotation ถ้ามี
    im = img.bakeOrientation(im);

    // 3) ลด/เพิ่มขนาดให้พอดี (ช่วยให้ OCR เสถียร)
    //    ปรับกว้างราว ๆ 1200–1800 px พอ (ตามคุณภาพต้นฉบับ)
    const targetWidth = 1600;
    if (im.width > targetWidth) {
      im = img.copyResize(im, width: targetWidth);
    }

    // 4) แปลงเป็น grayscale
    im = img.grayscale(im);

    // 5) เพิ่ม contrast/brightness เล็กน้อย
    im = img.adjustColor(im, contrast: 1.2, brightness: 0.02);

    // 6) ทำ threshold (ลองค่าต่าง ๆ 170–210 ตามลักษณะสลิป)
    //    ถ้าภาพเข้ม/ซีดต่างกันมาก ลองไม่ threshold แล้วปล่อย grayscale อย่างเดียวก็ได้
    // im = img.threshold(im, threshold: 195);

    // 7) (ทางเลือก) unsharp mask ให้ตัวอักษรคมขึ้น
    // im = img.convolution(im, img.kernelSharpen); // เบา ๆ
    // หรือ:
    // im = img.unsharpMask(im, radius: 2, amount: 1.0);

    // 8) เซฟเป็นไฟล์ชั่วคราว
    final tmpDir = await getTemporaryDirectory();
    final outPath = '${tmpDir.path}/ocr_prep_${DateTime.now().microsecondsSinceEpoch}.png';
    final outBytes = img.encodePng(im);
    await File(outPath).writeAsBytes(outBytes, flush: true);
    return outPath;
  }
}
