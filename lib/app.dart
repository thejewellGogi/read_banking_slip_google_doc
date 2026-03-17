import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import 'features/shell/bottom_shell.dart';

class SlipReaderApp extends StatelessWidget {
  const SlipReaderApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Slip Reader',

      // ✅ localization
      locale: const Locale('th', 'TH'),
      supportedLocales: const [
        Locale('th', 'TH'),
        Locale('en', 'US'),
      ],
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],

      theme: ThemeData(
        useMaterial3: true,
        colorSchemeSeed: const Color(0xFF0B1B3A),
        scaffoldBackgroundColor: const Color(0xFFF6F7FB),
      ),
      home: const BottomShell(),
    );
  }
}
