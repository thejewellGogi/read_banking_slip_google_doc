import 'package:flutter/material.dart';
import '../expenses/expenses_screen.dart';
import '../sources/source_screen.dart';
import '../../ocr/gallery/auto_ocr_runner.dart';
class BottomShell extends StatefulWidget {
  const BottomShell({super.key});

  @override
  State<BottomShell> createState() => _BottomShellState();
}

class _BottomShellState extends State<BottomShell> {
  int index = 0;

@override
  void initState() {
    super.initState();

    // สแกนอัตโนมัติเมื่อเปิดแอป
    Future.microtask(() async {
      // await AutoOcrRunner().run();
    });
  }
  final pages = const [
    ExpensesScreen(),
    SourceScreen(),
    _SettingsStub(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: pages[index],
      bottomNavigationBar: NavigationBar(
        selectedIndex: index,
        onDestinationSelected: (v) => setState(() => index = v),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.list_alt), label: 'รายจ่าย'),
          NavigationDestination(icon: Icon(Icons.image_outlined), label: 'สลิป'),
          NavigationDestination(icon: Icon(Icons.tune), label: 'ตั้งค่า'),
        ],
      ),
    );
  }
}

class _SettingsStub extends StatelessWidget {
  const _SettingsStub();

  @override
  Widget build(BuildContext context) {
    return const Center(child: Text('ตั้งค่า (ทำทีหลังได้)'));
  }
}
