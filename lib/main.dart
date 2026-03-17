import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:intl/date_symbol_data_local.dart';

import 'app.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // ✅ init ข้อมูล date locale
  Intl.defaultLocale = 'th_TH';
  await initializeDateFormatting('th_TH', null);

  runApp(const SlipReaderApp());
}
