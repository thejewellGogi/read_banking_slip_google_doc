import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/expense_model.dart';

class ExpenseTile extends StatelessWidget {
  final ExpenseModel model;

  const ExpenseTile({super.key, required this.model});

  @override
  Widget build(BuildContext context) {
    final time = DateFormat('HH:mm').format(model.dateTime);
    final money = NumberFormat.currency(locale: 'th_TH', symbol: 'THB ', decimalDigits: 2).format(model.amount);

    return ListTile(
      leading: const CircleAvatar(
        backgroundColor: Color(0xFFE9ECF3),
        child: Icon(Icons.question_mark, color: Colors.black54),
      ),
      title: Text(model.title, style: const TextStyle(fontWeight: FontWeight.w700)),
      subtitle: Text(money, style: const TextStyle(color: Colors.black54)),
      trailing: Text(time, style: const TextStyle(color: Colors.black54)),
    );
  }
}
