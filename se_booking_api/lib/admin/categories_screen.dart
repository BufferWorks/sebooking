import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:se_booking/config.dart';

class CategoriesScreen extends StatefulWidget {
  const CategoriesScreen({super.key});

  @override
  State<CategoriesScreen> createState() => _CategoriesScreenState();
}

class _CategoriesScreenState extends State<CategoriesScreen> {
  List categories = [];

  Future<void> load() async {
    final res = await http.get(Uri.parse('${Config.baseUrl}/admin/categories'));
    categories = jsonDecode(res.body);
    setState(() {});
  }

  @override
  void initState() {
    super.initState();
    load();
  }

  void addCategory() {
    final ctrl = TextEditingController();

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Add Category'),
        content: TextField(controller: ctrl),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              await http.post(
                Uri.parse('${Config.baseUrl}/admin/add_category'),
                headers: {'Content-Type': 'application/json'},
                body: jsonEncode({"name": ctrl.text}),
              );
              Navigator.pop(context);
              load();
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Categories')),
      floatingActionButton: FloatingActionButton(onPressed: addCategory, child: const Icon(Icons.add)),
      body: ListView(
        children: categories.map((c) => ListTile(title: Text(c['name']))).toList(),
      ),
    );
  }
}
