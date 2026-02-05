import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:se_booking/config.dart';
import 'pricing_detail_screen.dart';

class PricingCentersScreen extends StatefulWidget {
  const PricingCentersScreen({super.key});

  @override
  State<PricingCentersScreen> createState() => _PricingCentersScreenState();
}

class _PricingCentersScreenState extends State<PricingCentersScreen> {
  List centers = [];

  Future<void> load() async {
    final res = await http.get(
      Uri.parse('${Config.baseUrl}/admin/centers'),
    );
    centers = jsonDecode(res.body);
    setState(() {});
  }

  @override
  void initState() {
    super.initState();
    load();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Select Center')),
      body: ListView.builder(
        itemCount: centers.length,
        itemBuilder: (_, i) {
          final c = centers[i];
          return Card(
            child: ListTile(
              title: Text(c['center_name']),
              subtitle: Text(c['address']),
              trailing: const Icon(Icons.arrow_forward),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => PricingDetailScreen(
                      centerId: c['id'],
                      centerName: c['center_name'],
                    ),
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }
}
