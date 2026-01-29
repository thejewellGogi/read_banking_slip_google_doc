import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});
  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool subscribed = false;
  bool autoRead = false;

  bool _loading = true;   // โหลดค่าตอนเปิดจอ
  bool _saving = false;   // ระหว่างกด Save

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final sp = await SharedPreferences.getInstance();
      if (!mounted) return;
      setState(() {
        subscribed = sp.getBool('user_is_subscribed') ?? false;
        autoRead   = sp.getBool('auto_read_enabled') ?? false;
        _loading   = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _loading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('โหลดการตั้งค่าไม่สำเร็จ: $e')),
      );
    }
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    try {
      final sp = await SharedPreferences.getInstance();
      await sp.setBool('user_is_subscribed', subscribed);
      await sp.setBool('auto_read_enabled',   autoRead);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('บันทึกสำเร็จ')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('บันทึกล้มเหลว: $e')),
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
        children: [
          SwitchListTile.adaptive(
            title: const Text('Subscribed (demo toggle)'),
            value: subscribed,
            onChanged: _saving ? null : (v) => setState(() => subscribed = v),
          ),
          SwitchListTile.adaptive(
            title: const Text('Enable Auto Read (future)'),
            value: autoRead,
            onChanged: _saving ? null : (v) => setState(() => autoRead = v),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: ElevatedButton.icon(
              onPressed: _saving ? null : _save,
              icon: _saving
                  ? const SizedBox(
                  width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
                  : const Icon(Icons.save_outlined),
              label: Text(_saving ? 'Saving...' : 'Save'),
            ),
          ),
        ],
      ),
    );
  }
}
