import 'dart:io';
import 'dart:math';
import 'package:image/image.dart' as img;
import 'package:path_provider/path_provider.dart';

class PreprocessService {
  Future<File> preprocessSlip(File input) async {
    print("PREPROCESS: input=${input.path}");

    final bytes = await input.readAsBytes();
    final decoded = img.decodeImage(bytes);
    if (decoded == null) {
      throw Exception('Cannot decode image');
    }

    print("PREPROCESS: decoded size=${decoded.width}x${decoded.height}");

    final resized = _resizeIfTooLarge(decoded);
    print("PREPROCESS: resized size=${resized.width}x${resized.height}");

    final cropped = _autoCropForSlip(resized);
    print("PREPROCESS: cropped size=${cropped.width}x${cropped.height}");

    final gray = _grayscale(cropped);
    print("PREPROCESS: grayscale done");

    final contrast = _increaseContrast(gray, amount: 1.25);
    print("PREPROCESS: contrast done");

    final bin = _thresholdOtsu(contrast);
    print("PREPROCESS: threshold done");

    final outFile = await _saveTempPng(bin, prefix: 'pre_');
    print("PREPROCESS: saved=${outFile.path}");

    return outFile;
  }

  /// ✅ ย่อรูปก่อน ถ้ากว้างเกินไป เพื่อลดเวลาของ OCR
  img.Image _resizeIfTooLarge(img.Image src) {
    const maxWidth = 1600;

    if (src.width <= maxWidth) return src;

    final newHeight = (src.height * maxWidth / src.width).round();
    return img.copyResize(
      src,
      width: maxWidth,
      height: newHeight,
      interpolation: img.Interpolation.linear,
    );
  }

  img.Image _autoCropForSlip(img.Image src) {
    final w = src.width;
    final h = src.height;

    final top = (h * 0.08).round();
    final left = (w * 0.04).round();
    final rightCut = (w * 0.04).round();
    final bottomCut = (h * 0.03).round();

    final cropW = max(1, w - left - rightCut);
    final cropH = max(1, h - top - bottomCut);

    return img.copyCrop(
      src,
      x: left,
      y: top,
      width: cropW,
      height: cropH,
    );
  }

  img.Image _grayscale(img.Image src) {
    final out = img.Image.from(src);

    for (int y = 0; y < out.height; y++) {
      for (int x = 0; x < out.width; x++) {
        final p = out.getPixel(x, y);
        final r = p.r.toInt();
        final g = p.g.toInt();
        final b = p.b.toInt();

        final lum = (0.299 * r + 0.587 * g + 0.114 * b)
            .round()
            .clamp(0, 255);

        out.setPixelRgba(x, y, lum, lum, lum, 255);
      }
    }
    return out;
  }

  img.Image _increaseContrast(img.Image src, {double amount = 1.25}) {
    final out = img.Image.from(src);

    for (int y = 0; y < out.height; y++) {
      for (int x = 0; x < out.width; x++) {
        final p = out.getPixel(x, y);
        final v = p.r.toInt();
        final nv = ((v - 128) * amount + 128).round().clamp(0, 255);
        out.setPixelRgba(x, y, nv, nv, nv, 255);
      }
    }
    return out;
  }

  img.Image _thresholdOtsu(img.Image src) {
    final hist = List<int>.filled(256, 0);
    final total = src.width * src.height;

    for (int y = 0; y < src.height; y++) {
      for (int x = 0; x < src.width; x++) {
        final v = src.getPixel(x, y).r.toInt();
        hist[v]++;
      }
    }

    double sum = 0;
    for (int t = 0; t < 256; t++) {
      sum += t * hist[t];
    }

    double sumB = 0;
    int wB = 0;
    double varMax = 0;
    int threshold = 128;

    for (int t = 0; t < 256; t++) {
      wB += hist[t];
      if (wB == 0) continue;

      final wF = total - wB;
      if (wF == 0) break;

      sumB += t * hist[t];
      final mB = sumB / wB;
      final mF = (sum - sumB) / wF;

      final varBetween = wB * wF * (mB - mF) * (mB - mF);
      if (varBetween > varMax) {
        varMax = varBetween;
        threshold = t;
      }
    }

    final out = img.Image.from(src);
    for (int y = 0; y < out.height; y++) {
      for (int x = 0; x < out.width; x++) {
        final v = out.getPixel(x, y).r.toInt();
        final nv = (v >= threshold) ? 255 : 0;
        out.setPixelRgba(x, y, nv, nv, nv, 255);
      }
    }
    return out;
  }

  Future<File> _saveTempPng(img.Image image, {required String prefix}) async {
    final dir = await getTemporaryDirectory();
    final file = File(
      '${dir.path}/$prefix${DateTime.now().millisecondsSinceEpoch}.png',
    );
    await file.writeAsBytes(img.encodePng(image));
    return file;
  }
}