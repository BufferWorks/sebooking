import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';

import 'package:se_booking/config.dart';

class AdminAllBookingsScreen extends StatefulWidget {
  const AdminAllBookingsScreen({super.key});

  @override
  State<AdminAllBookingsScreen> createState() =>
      _AdminAllBookingsScreenState();
}

class _AdminAllBookingsScreenState extends State<AdminAllBookingsScreen> {
  List allBookings = [];
  List filteredBookings = [];
  bool loading = true;

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
      Uri.parse('${Config.baseUrl}/admin/bookings'),
    );

    if (res.statusCode == 200) {
      allBookings = jsonDecode(res.body);
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
          b['mobile']
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('All Center Bookings'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: loadBookings,
          ),
        ],
      ),
      body: Column(
        children: [
          // 🔍 SEARCH
          Padding(
            padding: const EdgeInsets.all(12),
            child: TextField(
              decoration: const InputDecoration(
                hintText: 'Search by name / mobile / booking ID',
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

          // 📋 BOOKINGS
          Expanded(
            child: loading
                ? const Center(child: CircularProgressIndicator())
                : filteredBookings.isEmpty
                ? const Center(child: Text('No bookings found'))
                : ListView.builder(
              itemCount: filteredBookings.length,
              itemBuilder: (_, i) {
                final b = filteredBookings[i];
                final date = DateFormat('dd MMM yyyy, hh:mm a')
                    .format(
                  DateTime.fromMillisecondsSinceEpoch(
                      b['created_at'] * 1000),
                );

                return Card(
                  margin: const EdgeInsets.symmetric(
                      horizontal: 12, vertical: 8),
                  child: Padding(
                    padding: const EdgeInsets.all(14),
                    child: Column(
                      crossAxisAlignment:
                      CrossAxisAlignment.start,
                      children: [
                        // 🏥 CENTER
                        Text(
                          b['center_name'],
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 15,
                          ),
                        ),
                        const Divider(),

                        // 👤 PATIENT
                        Text(
                          b['patient_name'],
                          style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600),
                        ),
                        Text(
                          'Mobile: ${b['mobile']}',
                          style: const TextStyle(fontSize: 13),
                        ),

                        const SizedBox(height: 6),

                        // 🧪 TEST
                        Text(
                          b['test_name'],
                          style: const TextStyle(fontSize: 13),
                        ),

                        const SizedBox(height: 6),

                        // 🆔 BOOKING ID + DATE
                        Text(
                          'Booking ID: ${b['booking_id']}',
                          style: const TextStyle(
                              fontSize: 12, color: Colors.grey),
                        ),
                        Text(
                          date,
                          style: const TextStyle(
                              fontSize: 12, color: Colors.grey),
                        ),

                        const SizedBox(height: 8),

                        // ✅ STATUS
                        Text(
                          b['status'],
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: b['status'] == 'Done'
                                ? Colors.green
                                : Colors.orange,
                          ),
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
