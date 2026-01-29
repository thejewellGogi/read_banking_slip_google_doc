import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../state/transactions_provider.dart';

class TransactionListScreen extends StatefulWidget {
  const TransactionListScreen({super.key});
  @override
  State<TransactionListScreen> createState() => _TransactionListScreenState();
}

class _TransactionListScreenState extends State<TransactionListScreen> {
  final fMoney = NumberFormat.currency(locale: 'th_TH', symbol: '฿');
  final fDate = DateFormat('d MMM y เวลา HH:mm น.', 'th_TH');

  @override
  void initState() {
    super.initState();
    // รีเฟรชหลัง build frame แรกเสร็จ
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<TransactionsProvider>().refresh();
    });
  }

  @override
  Widget build(BuildContext context) {
    final prov = context.watch<TransactionsProvider>();
    final items = prov.latest;

    return Scaffold(
      appBar: AppBar(title: const Text('รายการธุรกรรม')),
      body: RefreshIndicator(
        onRefresh: () => context.read<TransactionsProvider>().refresh(),
        child: items.isEmpty
            ? ListView(
                children: const [
                  SizedBox(height: 48),
                  Center(child: Text('ยังไม่มีข้อมูล')),
                ],
              )
            : ListView.separated(
                itemCount: items.length,
                separatorBuilder: (_, __) => const Divider(height: 0),
                itemBuilder: (_, i) {
                  final t = items[i];
                  return ListTile(
                    title: Text('${t.bankName}  •  ${fMoney.format(t.amount)}'),
                    subtitle: Text(
                      '${t.type}  •  ${fDate.format(t.transactionDate)}',
                    ),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.swap_horiz),
                          tooltip: 'สลับเป็น Income/Expense',
                          onPressed: () => prov.toggleType(t.id!, t.type),
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete_outline, color: Colors.red),
                          tooltip: 'ลบรายการนี้',
                          onPressed: () async {
                            final confirm = await showDialog<bool>(
                              context: context,
                              builder: (ctx) => AlertDialog(
                                title: const Text('ยืนยันการลบ'),
                                content: const Text('คุณแน่ใจหรือไม่ว่าต้องการลบรายการนี้?'),
                                actions: [
                                  TextButton(
                                    onPressed: () => Navigator.pop(ctx, false),
                                    child: const Text('ยกเลิก'),
                                  ),
                                  ElevatedButton(
                                    onPressed: () => Navigator.pop(ctx, true),
                                    child: const Text('ลบ'),
                                  ),
                                ],
                              ),
                            );

                            if (confirm == true) {
                              await prov.remove(t.id!);
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text('ลบรายการแล้ว')),
                                );
                              }
                            }
                          },
                        ),
                      ],
                    ),
                  );
                },
              ),
      ),
    );
  }
}
