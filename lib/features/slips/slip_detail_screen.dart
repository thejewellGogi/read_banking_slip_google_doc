import 'dart:io';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import 'models/slip_data_model.dart';
import 'services/slip_storage_service.dart';

class SlipDetailScreen extends StatefulWidget {
  final SlipDataModel slip;

  const SlipDetailScreen({
    super.key,
    required this.slip,
  });

  @override
  State<SlipDetailScreen> createState() => _SlipDetailScreenState();
}

class _SlipDetailScreenState extends State<SlipDetailScreen> {
  final SlipStorageService storage = SlipStorageService();

  late final TextEditingController receiverController;
  late final TextEditingController amountController;

  DateTime? selectedDateTime;
  bool isSaving = false;

  // ✅ เพิ่ม
  late SlipType selectedSlipType;

  @override
  void initState() {
    super.initState();
    receiverController =
        TextEditingController(text: widget.slip.receiverName ?? '');
    amountController = TextEditingController(
      text: widget.slip.amount != null
          ? widget.slip.amount!.toStringAsFixed(2)
          : '',
    );
    selectedDateTime = widget.slip.galleryDateTime;

    // ✅ ค่าเดิม หรือ default เป็นรายจ่าย
    selectedSlipType = widget.slip.slipType;
  }

  @override
  void dispose() {
    receiverController.dispose();
    amountController.dispose();
    super.dispose();
  }

  Future<void> _pickDateTime() async {
    final base = selectedDateTime ?? DateTime.now();

    final pickedDate = await showDatePicker(
      context: context,
      initialDate: base,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
      locale: const Locale('th', 'TH'),
    );

    if (pickedDate == null || !mounted) return;

    final pickedTime = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(base),
    );

    if (!mounted) return;

    setState(() {
      selectedDateTime = DateTime(
        pickedDate.year,
        pickedDate.month,
        pickedDate.day,
        pickedTime?.hour ?? base.hour,
        pickedTime?.minute ?? base.minute,
      );
    });
  }

  Future<void> _save() async {
    setState(() {
      isSaving = true;
    });

    final parsedAmount = double.tryParse(
      amountController.text.replaceAll(',', '').trim(),
    );

    final updated = widget.slip.copyWith(
      receiverName: receiverController.text.trim().isEmpty
          ? null
          : receiverController.text.trim(),
      amount: parsedAmount,
      galleryDateTime: selectedDateTime,
      slipType: selectedSlipType,
      status: 'edited',
    );

    await storage.updateOne(updated);

    if (!mounted) return;

    setState(() {
      isSaving = false;
    });

    Navigator.pop(context, true);
  }

  String _dateText() {
    if (selectedDateTime == null) return '-';
    final d = selectedDateTime!;
    final month = DateFormat('MMMM', 'th_TH').format(d);
    final year = d.year + 543;
    final time = DateFormat('HH:mm').format(d);
    return '${d.day} $month $year - $time';
  }

  @override
  Widget build(BuildContext context) {
    final file = File(widget.slip.imagePath);

    return Scaffold(
      backgroundColor: const Color(0xFFF6F7FB),
      appBar: AppBar(
        title: const Text(
          'รายละเอียดสลิป',
          style: TextStyle(fontWeight: FontWeight.w800),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: file.existsSync()
                ? Image.file(file, fit: BoxFit.cover)
                : Container(
                    height: 260,
                    color: Colors.grey.shade200,
                    alignment: Alignment.center,
                    child: const Icon(Icons.image_not_supported_outlined),
                  ),
          ),
          const SizedBox(height: 16),
          _SectionCard(
            title: 'ข้อมูลสลิป',
            child: Column(
              children: [
                _InfoRow(label: 'ธนาคาร', value: widget.slip.bankName ?? '-'),
                const SizedBox(height: 12),
                _InfoRow(label: 'สถานะ', value: widget.slip.status),
              ],
            ),
          ),
          const SizedBox(height: 12),

          // ✅ เพิ่มส่วนนี้
          _SectionCard(
            title: 'ประเภทสลิป',
            child: Column(
              children: [
                RadioListTile<SlipType>(
                  value: SlipType.expense,
                  groupValue: selectedSlipType,
                  onChanged: (value) {
                    if (value == null) return;
                    setState(() {
                      selectedSlipType = value;
                    });
                  },
                  title: const Text('รายจ่าย'),
                  contentPadding: EdgeInsets.zero,
                ),
                RadioListTile<SlipType>(
                  value: SlipType.income,
                  groupValue: selectedSlipType,
                  onChanged: (value) {
                    if (value == null) return;
                    setState(() {
                      selectedSlipType = value;
                    });
                  },
                  title: const Text('รายรับ'),
                  contentPadding: EdgeInsets.zero,
                ),
              ],
            ),
          ),

          const SizedBox(height: 12),
          _SectionCard(
            title: 'วันที่ทำรายการ',
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _dateText(),
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton(
                    onPressed: _pickDateTime,
                    child: const Text('แก้ไขวันที่'),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          _SectionCard(
            title: 'ผู้รับ',
            child: TextField(
              controller: receiverController,
              decoration: const InputDecoration(
                hintText: 'ระบุชื่อผู้รับ',
                border: OutlineInputBorder(),
              ),
            ),
          ),
          const SizedBox(height: 12),
          _SectionCard(
            title: 'จำนวนเงิน',
            child: TextField(
              controller: amountController,
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              decoration: const InputDecoration(
                hintText: '0.00',
                border: OutlineInputBorder(),
              ),
            ),
          ),
          const SizedBox(height: 12),
          _SectionCard(
            title: 'OCR TEXT',
            child: SelectableText(
              widget.slip.rawText,
              style: const TextStyle(fontSize: 12),
            ),
          ),
          const SizedBox(height: 18),
          SizedBox(
            height: 48,
            child: ElevatedButton(
              onPressed: isSaving ? null : _save,
              child: Text(isSaving ? 'กำลังบันทึก...' : 'บันทึกแก้ไข'),
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  final String title;
  final Widget child;

  const _SectionCard({
    required this.title,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;

  const _InfoRow({
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        SizedBox(
          width: 88,
          child: Text(
            label,
            style: const TextStyle(color: Colors.black54),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(fontWeight: FontWeight.w700),
          ),
        ),
      ],
    );
  }
}