import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:se_booking/config.dart';

class ManageAgentsScreen extends StatefulWidget {
  const ManageAgentsScreen({super.key});

  @override
  State<ManageAgentsScreen> createState() => _ManageAgentsScreenState();
}

class _ManageAgentsScreenState extends State<ManageAgentsScreen> {
  List agents = [];
  bool loading = true;

  @override
  void initState() {
    super.initState();
    loadAgents();
  }

  Future<void> loadAgents() async {
    final res = await http.get(Uri.parse('${Config.baseUrl}/admin/agents'));
    if (res.statusCode == 200) {
      setState(() {
        agents = jsonDecode(res.body);
        loading = false;
      });
    } else {
      setState(() => loading = false);
    }
  }

  Future<void> addAgent() async {
    final nameCtrl = TextEditingController();
    final userCtrl = TextEditingController();
    final passCtrl = TextEditingController();

    await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Add Agent'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameCtrl,
              decoration: const InputDecoration(labelText: 'Name'),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: userCtrl,
              decoration: const InputDecoration(labelText: 'Username'),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: passCtrl,
              decoration: const InputDecoration(labelText: 'Password'),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (nameCtrl.text.isEmpty ||
                  userCtrl.text.isEmpty ||
                  passCtrl.text.isEmpty) return;

              Navigator.pop(ctx);
              _submitAgent(nameCtrl.text, userCtrl.text, passCtrl.text);
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }

  Future<void> _submitAgent(String name, String username, String password) async {
    setState(() => loading = true);
    try {
      final res = await http.post(
        Uri.parse('${Config.baseUrl}/admin/add_agent'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          "name": name,
          "username": username,
          "password": password,
        }),
      );

      if (res.statusCode == 200) {
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text('Agent Added')));
        loadAgents();
      } else {
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text('Failed to add agent')));
        setState(() => loading = false);
      }
    } catch (e) {
      setState(() => loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Manage Agents')),
      floatingActionButton: FloatingActionButton(
        onPressed: addAgent,
        child: const Icon(Icons.add),
      ),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : ListView.builder(
              itemCount: agents.length,
              itemBuilder: (ctx, i) {
                final a = agents[i];
                return ListTile(
                  leading: const CircleAvatar(child: Icon(Icons.person)),
                  title: Text(a['name']),
                  subtitle: Text('Username: ${a['username']}'),
                );
              },
            ),
    );
  }
}
