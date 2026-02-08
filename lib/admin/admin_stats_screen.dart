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

  String dateFilter = 'today'; // 'today', 'all', 'custom'
  DateTime? selectedDate;
  
  // Calculate date range timestamps (UTC or handled by server? We use seconds int)
  @override
  void initState() {
    super.initState();
    loadStats();
  }

  Future<void> loadStats() async {
    setState(() => loading = true);
    
    int? startTs;
    int? endTs;

    if (dateFilter == 'today') {
       final now = DateTime.now();
       final start = DateTime(now.year, now.month, now.day);
       final end = start.add(const Duration(days: 1)).subtract(const Duration(seconds: 1));
       startTs = start.millisecondsSinceEpoch ~/ 1000;
       endTs = end.millisecondsSinceEpoch ~/ 1000;
    } else if (dateFilter == 'custom' && selectedDate != null) {
       final start = DateTime(selectedDate!.year, selectedDate!.month, selectedDate!.day);
       final end = start.add(const Duration(days: 1)).subtract(const Duration(seconds: 1));
       startTs = start.millisecondsSinceEpoch ~/ 1000;
       endTs = end.millisecondsSinceEpoch ~/ 1000;
    }
    // If 'all', leave startTs/endTs null

    try {
      final res = await ApiService.getCenterStats(startTs: startTs, endTs: endTs);
      setState(() {
        stats = res;
        loading = false;
      });
    } catch (e) {
      setState(() => loading = false);
    }
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: selectedDate ?? DateTime.now(),
      firstDate: DateTime(2025),
      lastDate: DateTime(2030),
    );
    if (picked != null) {
      setState(() {
        selectedDate = picked;
        dateFilter = 'custom';
        loadStats();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Center Wise Stats')),
      body: Column(
        children: [
          // Filter Bar
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
               children: [
                 const Text("Filter: ", style: TextStyle(fontWeight: FontWeight.bold)),
                 const SizedBox(width: 8),
                 ChoiceChip(
                   label: const Text('Today'),
                   selected: dateFilter == 'today',
                   onSelected: (sel) {
                     if (sel) setState(() { dateFilter = 'today'; loadStats(); });
                   },
                 ),
                 const SizedBox(width: 8),
                 ChoiceChip(
                   label: const Text('All Time'),
                   selected: dateFilter == 'all',
                   onSelected: (sel) {
                     if (sel) setState(() { dateFilter = 'all'; loadStats(); });
                   },
                 ),
                 const SizedBox(width: 8),
                 ActionChip(
                   label: Text(dateFilter == 'custom' && selectedDate != null
                       ? "${selectedDate!.day}/${selectedDate!.month}/${selectedDate!.year}" 
                       : 'Pick Date'),
                   avatar: const Icon(Icons.calendar_today, size: 16),
                   backgroundColor: dateFilter == 'custom' ? Colors.blue.withOpacity(0.2) : null,
                   onPressed: _pickDate,
                 ),
               ],
            ),
          ),
          
          Expanded(
            child: loading 
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
          ),
        ],
      ),
    );
  }
}
