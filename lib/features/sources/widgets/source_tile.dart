import 'package:flutter/material.dart';
import '../models/source_model.dart';

class SourceTile extends StatelessWidget {
  final SourceModel model;
  final VoidCallback? onTap;

  const SourceTile({
    super.key,
    required this.model,
    this.onTap,
  });

  String _statusText() {
    switch (model.statusType) {
      case SourceStatusType.done:
        return 'เสร็จสิ้น';
      case SourceStatusType.scanning:
        return 'กำลังสแกน... ${model.progress ?? 0}%';
      case SourceStatusType.starting:
        return 'กำลังเริ่มต้น...';
      case SourceStatusType.none:
        return 'ไม่มีสลิปใหม่';
    }
  }

  @override
  Widget build(BuildContext context) {
    final isActive = model.statusType == SourceStatusType.scanning;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Material(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: isActive ? Colors.black12 : Colors.transparent,
              ),
            ),
            child: Row(
              children: [
                Container(
                  width: 54,
                  height: 54,
                  decoration: BoxDecoration(
                    color: Colors.black12,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.account_balance_wallet_outlined),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        model.name,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${model.slipCount ?? 0} ใบ',
                        style: const TextStyle(color: Colors.black54),
                      ),
                    ],
                  ),
                ),
                Text(
                  _statusText(),
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: isActive ? Colors.black87 : Colors.black54,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}