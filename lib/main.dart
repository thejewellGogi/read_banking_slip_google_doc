// lib/main.dart
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart'; // ⬅️ เพิ่ม
import 'package:intl/date_symbol_data_local.dart';
import 'package:provider/provider.dart';
import 'dart:developer' as developer;
import 'services/database_service.dart';
import 'state/transactions_provider.dart';
import 'screens/home_screen.dart';
import 'screens/transaction_list_screen.dart';
import 'screens/settings_screen.dart';
import 'screens/image_selection_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // โหลดข้อมูลรูปแบบวันที่ภาษาไทย (จำเป็นสำหรับ intl)
  await initializeDateFormatting('th_TH', null);
  debugPrint('log me Too');
  final db = await AppDatabase.instance.init(); // เปิด DB
  runApp(ReadSlipApp(database: db));
}

class ReadSlipApp extends StatelessWidget {
  const ReadSlipApp({super.key, required this.database});
  final AppDatabase database;

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(
          create: (_) => TransactionsProvider(database),
        ),
      ],
      child: MaterialApp(
        title: 'Read Transfer Slip',
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(seedColor: Colors.teal),
          scaffoldBackgroundColor: const Color(0xFFF3FBF8), // optional: โทนอ่อนทั้งแอพ
          // useMaterial3: true, // เปิดถ้าต้องการ
        ),

        // ⬅️ สำคัญ: เพิ่ม delegates ให้รองรับข้อความระบบของ Material/Cupertino/Widgets
        localizationsDelegates: const [
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],

        // ภาษาที่รองรับ
        supportedLocales: const [
          Locale('th', 'TH'),
          Locale('en', 'US'),
        ],

        // ตั้งค่าให้แอพใช้ภาษาไทยเป็นหลัก
        locale: const Locale('th', 'TH'),

        routes: {
          '/': (_) => const HomeScreen(),
          '/transactions': (_) => const TransactionListScreen(),
          '/settings': (_) => const SettingsScreen(),
          '/pick': (_) => const ImageSelectionScreen(),
        },
        initialRoute: '/',
      ),
    );
  }
}
