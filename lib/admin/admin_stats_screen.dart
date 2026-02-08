import 'package:flutter/material.dart';
import '../services/api_service.dart';

class AdminStatsScreen extends StatefulWidget {
  const AdminStatsScreen({super.key});

  @override
  State<AdminStatsScreen> createState() => _AdminStatsScreenState();
}

class _AdminStatsScreenState extends State<AdminStatsScreen> {
  List stats = [];
  bool loading = true;

  @override
  void initState() {
    super.initState();
    loadStats();
  }

  Future<void> loadStats() async {
    setState(() => loading = true);
    try {
      final res = await ApiService.getCenterStats();
      setState(() {
        stats = res;
        loading = false;
      });
    } catch (e) {
      setState(() => loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Center Wise Stats')),
      body: loading 
        ? const Center(child: CircularProgressIndicator()) 
        : SingleChildScrollView(
            scrollDirection: Axis.vertical,
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: DataTable(
                columns: const [
                  DataColumn(label: Text('Center Name', style: TextStyle(fontWeight: FontWeight.bold))),
                  DataColumn(label: Text('Total', style: TextStyle(fontWeight: FontWeight.bold))),
                  DataColumn(label: Text('Paid', style: TextStyle(fontWeight: FontWeight.bold))),
                  DataColumn(label: Text('Unpaid', style: TextStyle(fontWeight: FontWeight.bold))),
                  DataColumn(label: Text('Agent Coll.', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.purple))),
                  DataColumn(label: Text('Center Coll.', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.green))),
                  DataColumn(label: Text('Due', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.red))),
                ],
                rows: stats.map((s) {
                  return DataRow(cells: [
                    DataCell(Text(s['center_name'])),
                    DataCell(Text('${s['total_bookings']}')),
                    DataCell(Text('${s['paid_count']}')),
                    DataCell(Text('${s['unpaid_count']}')),
                    DataCell(Text('₹${s['agent_collected']}')),
                    DataCell(Text('₹${s['center_collected']}')),
                    DataCell(Text('₹${s['total_due']}', style: const TextStyle(color: Colors.red))),
                  ]);
                }).toList(),
              ),
            ),
          ),
    );
  }
}
