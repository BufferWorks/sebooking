import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:se_booking/config.dart';
import '../screens/test_category_screen.dart';
import '../screens/home_screen.dart';

class AgentHomeScreen extends StatefulWidget {
  const AgentHomeScreen({super.key});

  @override
  State<AgentHomeScreen> createState() => _AgentHomeScreenState();
}

class _AgentHomeScreenState extends State<AgentHomeScreen> {
  final nameController = TextEditingController();
  final mobileController = TextEditingController();

  List categories = [];
  bool loading = true;
  String? errorMessage;
  String agentName = "";
  String _paymentStatus = "Unpaid";

  @override
  void initState() {
    super.initState();
    _loadAgentInfo();
    loadCategories();
  }

  Future<void> _loadAgentInfo() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      agentName = prefs.getString('agent_name') ?? "Agent";
    });
  }

  Future<void> loadCategories() async {
    try {
      final res = await http.get(
        Uri.parse('${Config.baseUrl}/admin/categories'),
      );

      if (res.statusCode == 200) {
        categories = jsonDecode(res.body);
      } else {
        errorMessage = 'Failed to load: ${res.statusCode}';
      }
    } catch (e) {
      errorMessage = 'Error: $e';
    } finally {
      if (mounted) {
        setState(() => loading = false);
      }
    }
  }

  Future<void> _logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
    if (!mounted) return;
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const HomeScreen()),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Agent: $agentName'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: _logout,
          ),
        ],
      ),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : errorMessage != null
              ? Center(child: Text(errorMessage!))
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Book Test for Patient',
                        style: TextStyle(
                            fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: nameController,
                        decoration:
                            const InputDecoration(labelText: 'Patient Name'),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: mobileController,
                        keyboardType: TextInputType.phone,
                        decoration:
                            const InputDecoration(labelText: 'Mobile Number'),
                      ),
                      const SizedBox(height: 16),
                      const Text('Payment Status for Booking:', style: TextStyle(fontWeight: FontWeight.bold)),
                      Row(
                        children: [
                          Expanded(
                            child: RadioListTile(
                              title: const Text('Unpaid'),
                              value: 'Unpaid',
                              groupValue: _paymentStatus,
                              onChanged: (val) => setState(() => _paymentStatus = val.toString()),
                              dense: true,
                              contentPadding: EdgeInsets.zero,
                            ),
                          ),
                          Expanded(
                            child: RadioListTile(
                              title: const Text('Paid'),
                              value: 'Paid',
                              groupValue: _paymentStatus,
                              onChanged: (val) => setState(() => _paymentStatus = val.toString()),
                              dense: true,
                              contentPadding: EdgeInsets.zero,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),
                      const Text(
                        'Select Category',
                        style: TextStyle(
                            fontSize: 16, fontWeight: FontWeight.w600),
                      ),
                      const SizedBox(height: 16),
                      GridView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: categories.length,
                        gridDelegate:
                            const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          mainAxisSpacing: 12,
                          crossAxisSpacing: 12,
                          childAspectRatio: 1.2,
                        ),
                        itemBuilder: (_, i) {
                          final cat = categories[i];
                          return _categoryCard(cat);
                        },
                      ),
                    ],
                  ),
                ),
    );
  }

  Widget _categoryCard(Map category) {
    return GestureDetector(
      onTap: () {
        final name = nameController.text.trim();
        final mobile = mobileController.text.trim();

        if (name.isEmpty || mobile.isEmpty) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Enter patient name & mobile')),
          );
          return;
        }

        // Don't clear fields immediately for agent convenience? Or maybe clear.
        // Let's clear to avoid booking for wrong person next.
        nameController.clear();
        mobileController.clear();

        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => TestCategoryScreen(
              categoryId: category['id'],
              categoryName: category['name'],
              patientName: name,
              mobile: mobile,
              paymentStatus: _paymentStatus,
            ),
          ),
        );
      },
      child: Container(
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF2196F3), Color(0xFF1976D2)],
          ),
          borderRadius: BorderRadius.circular(18),
        ),
        child: Center(
          child: Text(
            category['name'],
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
    );
  }
}
