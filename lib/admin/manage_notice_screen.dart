import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../config.dart';

class ManageNoticeScreen extends StatefulWidget {
  const ManageNoticeScreen({super.key});

  @override
  State<ManageNoticeScreen> createState() => _ManageNoticeScreenState();
}

class _ManageNoticeScreenState extends State<ManageNoticeScreen> {
  final _textController = TextEditingController();
  bool _enabled = false;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _fetchNotice();
  }

  Future<void> _fetchNotice() async {
    try {
      final res = await http.get(Uri.parse('${Config.baseUrl}/get_notice'));
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        setState(() {
          _textController.text = data['text'] ?? '';
          _enabled = data['enabled'] ?? false;
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
    } finally {
      setState(() => _loading = false);
    }
  }

  Future<void> _updateNotice() async {
    setState(() => _loading = true);
    try {
      final res = await http.post(
        Uri.parse('${Config.baseUrl}/admin/update_notice'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          "text": _textController.text.trim(),
          "enabled": _enabled,
        }),
      );

      if (res.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Notice updated!')));
      } else {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Failed to update')));
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
    } finally {
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Manage Home Notice')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              controller: _textController,
              decoration: const InputDecoration(
                labelText: 'Notice Text',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
            ),
            const SizedBox(height: 20),
            SwitchListTile(
              title: const Text('Enable Notice'),
              value: _enabled,
              onChanged: (val) => setState(() => _enabled = val),
            ),
            const SizedBox(height: 30),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _updateNotice,
                child: const Text('Update Notice'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
