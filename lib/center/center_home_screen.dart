import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:se_booking/config.dart';
import '../screens/home_screen.dart';

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
  String dateFilter = 'today'; // today | all

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

      final matchesDate = dateFilter == 'all'
          ? true
          : bookingTime.year == now.year &&
              bookingTime.month == now.month &&
              bookingTime.day == now.day;

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

  Future<void> markDone(String bookingId) async {
    await http.post(
      Uri.parse('${Config.baseUrl}/center/mark_done'),
      headers: {'Content-Type': 'application/json'},
      body: json.encode({"booking_id": bookingId}),
    );

    loadBookings();
  }

  Future<void> togglePayment(String bookingId) async {
    bool? confirm = await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Mark as Paid?'),
        content: const Text('Are you sure you want to mark this booking as PAID?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancel')),
          ElevatedButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Yes, Paid')),
        ],
      ),
    );

    if (confirm == true) {
      await http.post(
        Uri.parse('${Config.baseUrl}/center/update_payment_status'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          "booking_id": bookingId,
          "payment_status": "Paid"
        }),
      );
      loadBookings();
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

                        // Payment Status with Toggle (Only show status, hide Agent Name)
                        Row(
                          mainAxisAlignment: MainAxisAlignment.end, // Align to right since we removed the left text
                          children: [
                            InkWell(
                              onTap: (b['payment_status'] ?? 'Unpaid') == 'Paid'
                                  ? null
                                  : () => togglePayment(b['booking_id']),
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: (b['payment_status'] ?? 'Unpaid') ==
                                          'Paid'
                                      ? Colors.green.withOpacity(0.1)
                                      : Colors.red.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(4),
                                  border: Border.all(
                                    color: (b['payment_status'] ?? 'Unpaid') ==
                                            'Paid'
                                        ? Colors.green
                                        : Colors.red,
                                    width: 0.5,
                                  ),
                                ),
                                child: Row(
                                  children: [
                                    Text(
                                      b['payment_status'] ?? 'Unpaid',
                                      style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.bold,
                                        color:
                                            (b['payment_status'] ?? 'Unpaid') ==
                                                    'Paid'
                                                ? Colors.green
                                                : Colors.red,
                                      ),
                                    ),
                                    if ((b['payment_status'] ?? 'Unpaid') == 'Unpaid')
                                      const Padding(
                                        padding: EdgeInsets.only(left: 4),
                                        child: Icon(Icons.edit, size: 10, color: Colors.red),
                                      ),
                                    if ((b['payment_status'] ?? 'Unpaid') == 'Paid')
                                      const Padding(
                                        padding: EdgeInsets.only(left: 4),
                                        child: Icon(Icons.lock, size: 10, color: Colors.green),
                                      ),
                                  ],
                                ),
                              ),
                            ),
                          ],
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
