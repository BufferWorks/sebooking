import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:se_booking/config.dart';
import 'center_home_screen.dart';

class CenterLoginScreen extends StatefulWidget {
  const CenterLoginScreen({super.key});

  @override
  State<CenterLoginScreen> createState() => _CenterLoginScreenState();
}

class _CenterLoginScreenState extends State<CenterLoginScreen> {
  final usernameCtrl = TextEditingController();
  final passwordCtrl = TextEditingController();
  bool loading = false;

  Future<void> login() async {
    if (usernameCtrl.text.isEmpty || passwordCtrl.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Enter username & password')),
      );
      return;
    }

    setState(() => loading = true);

    final res = await http.post(
      Uri.parse('${Config.baseUrl}/center/login'),
      headers: {'Content-Type': 'application/json'},
      body: json.encode({
        "username": usernameCtrl.text.trim(),
        "password": passwordCtrl.text.trim(),
      }),
    );

    setState(() => loading = false);

    if (res.statusCode == 200) {
      final data = json.decode(res.body);

      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('center_logged_in', true);
      await prefs.setInt('center_id', data['center_id']);
      await prefs.setString('center_name', data['center_name']);

      if (!mounted) return;

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => CenterHomeScreen(
            centerId: data['center_id'],
            centerName: data['center_name'],
          ),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Invalid login')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Center Login')),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            const Icon(
              Icons.local_hospital,
              size: 64,
              color: Color(0xFF1976D2),
            ),
            const SizedBox(height: 20),

            TextField(
              controller: usernameCtrl,
              decoration: const InputDecoration(
                labelText: 'Username',
                border: OutlineInputBorder(),
              ),
            ),

            const SizedBox(height: 12),

            TextField(
              controller: passwordCtrl,
              obscureText: true,
              decoration: const InputDecoration(
                labelText: 'Password',
                border: OutlineInputBorder(),
              ),
            ),

            const SizedBox(height: 20),

            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: loading ? null : login,
                child: loading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text('Login'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
