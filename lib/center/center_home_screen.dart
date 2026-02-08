import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:se_booking/config.dart';
import '../services/api_service.dart';

class CenterHomeScreen extends StatefulWidget {
  final int centerId;
  final String centerName;

  const CenterHomeScreen({
    super.key,
    required this.centerId,
    required this.centerName,
  });

  @override
  State<CenterHomeScreen> createState() => _CenterHomeScreenState();
}

class _CenterHomeScreenState extends State<CenterHomeScreen> {
  bool loading = true;
  List allBookings = [];
  List filteredBookings = [];

  String searchText = '';
  String dateFilter = 'today'; // today | all | custom
  DateTime? selectedDate;

  @override
  void initState() {
    super.initState();
    loadBookings();
  }

  Future<void> loadBookings() async {
    setState(() => loading = true);

    final res = await http.get(
      Uri.parse(
        '${Config.baseUrl}/center/bookings?center_id=${widget.centerId}',
      ),
    );

    if (res.statusCode == 200) {
      allBookings = json.decode(res.body);
    } else {
      allBookings = [];
    }

    applyFilters();
    setState(() => loading = false);
  }

  void applyFilters() {
    final now = DateTime.now();

    filteredBookings = allBookings.where((b) {
      final bookingTime =
          DateTime.fromMillisecondsSinceEpoch(b['created_at'] * 1000);

      bool matchesDate = false;
      if (dateFilter == 'today') {
        matchesDate = bookingTime.year == now.year &&
                bookingTime.month == now.month &&
                bookingTime.day == now.day;
      } else if (dateFilter == 'all') {
        matchesDate = true;
      } else if (dateFilter == 'custom' && selectedDate != null) {
        matchesDate = bookingTime.year == selectedDate!.year &&
                bookingTime.month == selectedDate!.month &&
                bookingTime.day == selectedDate!.day;
      }

      final matchesSearch = searchText.isEmpty ||
          b['patient_name']
              .toString()
              .toLowerCase()
              .contains(searchText.toLowerCase()) ||
          b['booking_id']
              .toString()
              .toLowerCase()
              .contains(searchText.toLowerCase());

      return matchesDate && matchesSearch;
    }).toList();
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
        applyFilters();
      });
    }
  }

  Future<void> markDone(String bookingId) async {
    await http.post(
      Uri.parse('${Config.baseUrl}/center/mark_done'),
      headers: {'Content-Type': 'application/json'},
      body: json.encode({"booking_id": bookingId}),
    );

    loadBookings();
  }

  Future<void> _openPaymentDialog(Map b) async {
    final price = double.tryParse(b['price'].toString()) ?? 0;
    final agentColl = double.tryParse(b['agent_collected'].toString()) ?? 0;
    final centerColl = double.tryParse(b['center_collected'].toString()) ?? 0;

    final agentController = TextEditingController(text: agentColl.toStringAsFixed(0));
    final centerController = TextEditingController(text: centerColl.toStringAsFixed(0));

    await showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          title: const Text('Update Payment Details'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _infoRow('Total Price', '₹${price.toStringAsFixed(0)}'),
                const Divider(),
                const SizedBox(height: 10),
                TextField(
                  controller: agentController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Agent Collection',
                    prefixText: '₹ ',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: centerController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Center Collection',
                    prefixText: '₹ ',
                    border: OutlineInputBorder(),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                final ac = double.tryParse(agentController.text) ?? 0;
                final cc = double.tryParse(centerController.text) ?? 0;

                await ApiService.updatePaymentDetails(
                  bookingId: b['booking_id'],
                  agentCollected: ac,
                  centerCollected: cc,
                  updatedByName: widget.centerName,
                );
                if (mounted) Navigator.pop(ctx);
                loadBookings();
              },
              child: const Text('Save'),
            ),
          ],
        );
      },
    );
  }

  Widget _infoRow(String k, String v) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [Text(k), Text(v, style: const TextStyle(fontWeight: FontWeight.bold))],
      ),
    );
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
        title: Text(widget.centerName),
        actions: [
            IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: loadBookings,
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: _logout,
          ),
        ],
      ),
      body: Column(
        children: [
          // 🔍 SEARCH BAR
          Padding(
            padding: const EdgeInsets.all(12),
            child: TextField(
              decoration: const InputDecoration(
                hintText: 'Search by patient / booking ID',
                prefixIcon: Icon(Icons.search),
              ),
              onChanged: (v) {
                searchText = v;
                setState(() => applyFilters());
              },
            ),
          ),

          // 📅 DATE FILTER
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  ChoiceChip(
                    label: const Text('Today'),
                    selected: dateFilter == 'today',
                    onSelected: (_) {
                      setState(() {
                        dateFilter = 'today';
                        applyFilters();
                      });
                    },
                  ),
                  const SizedBox(width: 8),
                  ActionChip(
                    label: Text(dateFilter == 'custom' 
                        ? DateFormat('dd MMM').format(selectedDate!) 
                        : 'Pick Date'),
                    avatar: const Icon(Icons.calendar_today, size: 16),
                    onPressed: _pickDate,
                    backgroundColor: dateFilter == 'custom' ? Colors.blue.withOpacity(0.2) : null,
                  ),
                  const SizedBox(width: 8),
                  ChoiceChip(
                    label: const Text('All'),
                    selected: dateFilter == 'all',
                    onSelected: (_) {
                      setState(() {
                        dateFilter = 'all';
                        applyFilters();
                      });
                    },
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 8),

          // 📋 BOOKINGS LIST
          Expanded(
            child: loading
                ? const Center(child: CircularProgressIndicator())
                : filteredBookings.isEmpty
                ? const Center(child: Text('No bookings found'))
                : ListView.builder(
              itemCount: filteredBookings.length,
              itemBuilder: (context, index) {
                final b = filteredBookings[index];
                final date = DateFormat('dd MMM yyyy, hh:mm a')
                    .format(DateTime.fromMillisecondsSinceEpoch(
                    b['created_at'] * 1000));

                return Card(
                  margin: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // 👤 PATIENT + BOOKING ID
                        Text(
                          '${b['patient_name']}',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Booking ID: ${b['booking_id']}',
                          style: const TextStyle(
                            fontSize: 12,
                            color: Colors.grey,
                          ),
                        ),

                        const SizedBox(height: 6),

                        // 🧪 TEST
                        Text(
                          b['test_name'] ?? '',
                          style: const TextStyle(fontSize: 14),
                        ),

                        const SizedBox(height: 4),

                        // 🕒 DATE
                        Text(
                          date,
                          style: const TextStyle(
                            fontSize: 12,
                            color: Colors.grey,
                          ),
                        ),

                        const SizedBox(height: 8),

                        // Payment Breakdown
                        Builder(
                          builder: (context) {
                            final price = double.tryParse(b['price'].toString()) ?? 0;
                            final agentColl = double.tryParse(b['agent_collected'].toString()) ?? 0;
                            final centerColl = double.tryParse(b['center_collected'].toString()) ?? 0;
                            final totalPaid = agentColl + centerColl;
                            final due = price - totalPaid;

                            return Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: Colors.grey.shade50,
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: Colors.grey.shade200),
                              ),
                              child: Column(
                                children: [
                                  _infoRow('Price', '₹${price.toStringAsFixed(0)}'),
                                  const SizedBox(height: 4),
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      const Text('Paid', style: TextStyle(color: Colors.green)),
                                      Text(
                                        '₹${totalPaid.toStringAsFixed(0)} (Ag: ${agentColl.toInt()} | Ctr: ${centerColl.toInt()})',
                                        style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.green),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 4),
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text('Due', style: TextStyle(color: due > 0 ? Colors.red : Colors.grey)),
                                      Text(
                                        '₹${due.toStringAsFixed(0)}',
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold, 
                                          color: due > 0 ? Colors.red : Colors.grey,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 8),
                                  SizedBox(
                                    width: double.infinity,
                                    height: 32,
                                    child: OutlinedButton.icon(
                                      icon: const Icon(Icons.edit, size: 14),
                                      label: const Text('Update Payment', style: TextStyle(fontSize: 12)),
                                      onPressed: () => _openPaymentDialog(b),
                                    ),
                                  ),
                                ],
                              ),
                            );
                          }
                        ),

                        const SizedBox(height: 12),

                        // ✅ STATUS + ACTION
                        Row(
                          mainAxisAlignment:
                          MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              b['status'] ?? '',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: b['status'] == 'Done'
                                    ? Colors.green
                                    : Colors.orange,
                              ),
                            ),
                            if (b['status'] != 'Done')
                              SizedBox(
                                width: 110,
                                height: 36,
                                child: ElevatedButton(
                                  onPressed: () =>
                                      markDone(b['booking_id']),
                                  child: const Text(
                                    'Mark Done',
                                    style: TextStyle(fontSize: 13),
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
