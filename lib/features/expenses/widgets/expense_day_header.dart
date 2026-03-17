import 'package:flutter/material.dart';

class ExpenseDayHeader extends StatelessWidget {
  final String left;
  final String right;

  const ExpenseDayHeader({super.key, required this.left, required this.right});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 14, 16, 8),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFF0B1B3A),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              left,
              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700),
            ),
          ),
          Text(
            right,
            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800),
          ),
        ],
      ),
    );
  }
}
