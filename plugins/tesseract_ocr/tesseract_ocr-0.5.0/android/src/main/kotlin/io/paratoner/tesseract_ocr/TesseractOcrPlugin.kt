package io.paratoner.tesseract_ocr

import android.graphics.BitmapFactory
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import com.googlecode.tesseract.android.TessBaseAPI

class TesseractOcrPlugin : FlutterPlugin, MethodChannel.MethodCallHandler {
  private lateinit var channel: MethodChannel

  override fun onAttachedToEngine(binding: FlutterPlugin.FlutterPluginBinding) {
    channel = MethodChannel(binding.binaryMessenger, "tesseract_ocr")
    channel.setMethodCallHandler(this)
  }

  override fun onDetachedFromEngine(binding: FlutterPlugin.FlutterPluginBinding) {
    channel.setMethodCallHandler(null)
  }

  override fun onMethodCall(call: MethodCall, result: MethodChannel.Result) {
    when (call.method) {
      "extractText" -> {
        try {
          val imagePath = call.argument<String>("imagePath") ?: run {
            result.error("ARG", "imagePath is required", null); return
          }
          val tessData = call.argument<String>("tessData") ?: ""
          val language = call.argument<String>("language") ?: "eng"

          // ✅ options จากฝั่ง Dart: OCRConfig.options
          @Suppress("UNCHECKED_CAST")
          val options = call.argument<Map<String, Any?>>("options") ?: emptyMap()

          val api = TessBaseAPI()

          // NOTE: tess-two ส่วนมาก init(datapath, lang) พอ
          api.init(tessData, language)

          // ---- PSM (Page Segmentation Mode) ----
          // รับได้ทั้ง key "tessedit_pageseg_mode" (ตาม TesseractConfig.pageSegMode)
          // หรือ shorthand "psm" ก็ได้
          val psmString = (options["tessedit_pageseg_mode"] ?: options["psm"])?.toString()
          if (psmString != null) {
            val mode = when (psmString) {
              "0"  -> TessBaseAPI.PageSegMode.PSM_OSD_ONLY
              "1"  -> TessBaseAPI.PageSegMode.PSM_AUTO_OSD
              "2"  -> TessBaseAPI.PageSegMode.PSM_AUTO_ONLY
              "3"  -> TessBaseAPI.PageSegMode.PSM_AUTO
              "4"  -> TessBaseAPI.PageSegMode.PSM_SINGLE_COLUMN
              "5"  -> TessBaseAPI.PageSegMode.PSM_SINGLE_BLOCK_VERT_TEXT
              "6"  -> TessBaseAPI.PageSegMode.PSM_SINGLE_BLOCK
              "7"  -> TessBaseAPI.PageSegMode.PSM_SINGLE_LINE
              "8"  -> TessBaseAPI.PageSegMode.PSM_SINGLE_WORD
              "9"  -> TessBaseAPI.PageSegMode.PSM_SINGLE_CHAR
              "10" -> TessBaseAPI.PageSegMode.PSM_SPARSE_TEXT
              "11" -> TessBaseAPI.PageSegMode.PSM_SPARSE_TEXT_OSD
              "12" -> TessBaseAPI.PageSegMode.PSM_RAW_LINE
              else -> TessBaseAPI.PageSegMode.PSM_AUTO
            }
            api.pageSegMode = mode
          }

          // ---- OEM (ถ้า lib/เวอร์ชันรองรับผ่าน setVariable) ----
          // ปกติ OEM จะถูกกำหนดตอน init; ถ้า lib ไม่รองรับ OEM ใน init
          // เราส่งผ่าน variable ได้บ้างในบาง build
          val oemString = (options["tessedit_ocr_engine_mode"] ?: options["oem"])?.toString()
          if (oemString != null) {
            // 0: Tesseract only, 1: LSTM only, 2: Tesseract+LSTM, 3: Default
            api.setVariable("tessedit_ocr_engine_mode", oemString)
          }

          // ---- ตัวเลือกอื่น ๆ (whitelist/blacklist/keep spaces ฯลฯ) ----
          options["tessedit_char_whitelist"]?.toString()?.let {
            api.setVariable("tessedit_char_whitelist", it)
          }
          options["tessedit_char_blacklist"]?.toString()?.let {
            api.setVariable("tessedit_char_blacklist", it)
          }
          options["preserve_interword_spaces"]?.toString()?.let {
            api.setVariable("preserve_interword_spaces", it) // "0" หรือ "1"
          }
          options["debug_file"]?.toString()?.let {
            api.setVariable("debug_file", it) // path ไฟล์ debug
          }

          val bmp = BitmapFactory.decodeFile(imagePath)
          if (bmp == null) {
            api.end()
            result.error("IMG", "Failed to decode image at $imagePath", null)
            return
          }

          try {
            api.setImage(bmp)
            val text = api.utF8Text ?: ""
            result.success(text)
          } finally {
            bmp.recycle()
            api.end()
          }
        } catch (e: Exception) {
          result.error("OCR", e.message, null)
        }
      }
      else -> result.notImplemented()
    }
  }
}
