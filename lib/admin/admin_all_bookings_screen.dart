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
  String dateFilter = 'today'; // today | all | custom
  DateTime? selectedDate;
  String? agentFilter;
  String? centerFilter;

  List<String> uniqueAgents = [];
  List<String> uniqueCenters = [];

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
      
      uniqueAgents = allBookings
          .map((e) => e['booked_by'].toString())
          .toSet()
          .toList();
      uniqueCenters = allBookings
          .map((e) => e['center_name'].toString())
          .toSet()
          .toList();
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
          b['mobile']
              .toString()
              .toLowerCase()
              .contains(searchText.toLowerCase()) ||
          b['booking_id']
              .toString()
              .toLowerCase()
              .contains(searchText.toLowerCase());

      final matchesAgent = agentFilter == null || b['booked_by'] == agentFilter;
      final matchesCenter = centerFilter == null || b['center_name'] == centerFilter;

      return matchesDate && matchesSearch && matchesAgent && matchesCenter;
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
          
          const SizedBox(height: 12),

          // 🧹 ADDITIONAL FILTERS (Agent & Center)
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Row(
              children: [
                _buildDropdown(
                    "Agent",
                    agentFilter,
                    uniqueAgents,
                    (v) => setState(() {
                      agentFilter = v;
                      applyFilters();
                    })),
                const SizedBox(width: 8),
                _buildDropdown(
                    'Center',
                    centerFilter,
                    uniqueCenters,
                    (v) => setState(() {
                      centerFilter = v;
                      applyFilters();
                    })),
                if (agentFilter != null || centerFilter != null)
                  IconButton(
                      onPressed: () {
                        setState(() {
                          agentFilter = null;
                          centerFilter = null;
                          applyFilters();
                        });
                      },
                      icon: const Icon(Icons.clear, color: Colors.red)),
              ],
            ),
          ),

          
          const SizedBox(height: 12),

          // 📊 SUMMARY CARD
          if (!loading)
            Builder(
              builder: (_) {
                int total = filteredBookings.length;
                int paidByAgent = 0;
                int paidByCenter = 0;
                int unpaid = 0;

                for (var b in filteredBookings) {
                  String status = b['payment_status'] ?? 'Unpaid';
                  String updatedBy = b['payment_updated_by'] ?? '';

                  if (status == 'Unpaid') {
                    unpaid++;
                  } else {
                    if (updatedBy == 'Center') {
                      paidByCenter++;
                    } else {
                      // If updated_by is missing but paid, assume Agent/Booker
                      paidByAgent++;
                    }
                  }
                }

                return SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: Row(
                    children: [
                      _summaryCard('Total', '$total', Colors.blue),
                      _summaryCard('Paid (Agent)', '$paidByAgent', Colors.purple),
                      _summaryCard('Paid (Center)', '$paidByCenter', Colors.green),
                      _summaryCard('Unpaid', '$unpaid', Colors.orange),
                    ],
                  ),
                );
              },
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
                            
                        // 🆕 Booked By & Payment Details
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  'By: ${b['booked_by'] ?? 'Customer'}',
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: (b['booked_by'] ?? 'Customer') == 'Customer' 
                                        ? Colors.blueGrey 
                                        : Colors.purple,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                InkWell(
                                  onTap: () => toggleAdminPayment(b['booking_id'], b['payment_status'] ?? 'Unpaid'),
                                  child: Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: (b['payment_status'] ?? 'Unpaid') == 'Paid' 
                                            ? Colors.green.withOpacity(0.1) 
                                            : Colors.red.withOpacity(0.1),
                                        borderRadius: BorderRadius.circular(4),
                                        border: Border.all(
                                           color: (b['payment_status'] ?? 'Unpaid') == 'Paid' 
                                            ? Colors.green 
                                            : Colors.red,
                                           width: 0.5
                                        )
                                      ),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Text(
                                            b['payment_status'] ?? 'Unpaid',
                                            style: TextStyle(
                                              fontSize: 12,
                                              fontWeight: FontWeight.bold,
                                              color: (b['payment_status'] ?? 'Unpaid') == 'Paid' 
                                                  ? Colors.green 
                                                  : Colors.red,
                                            ),
                                          ),
                                          const SizedBox(width: 4),
                                          const Icon(Icons.edit, size: 10, color: Colors.blueGrey),
                                        ],
                                      ),
                                  ),
                                ),
                              ],
                            ),
                            
                            // Show WHO collected payment if Paid
                            if ((b['payment_status'] ?? 'Unpaid') == 'Paid')
                              Padding(
                                padding: const EdgeInsets.only(top: 4),
                                child: Text(
                                  'Collected by: ${b['payment_updated_by'] ?? b['booked_by'] ?? 'Agent'}',
                                  style: const TextStyle(
                                    fontSize: 11,
                                    color: Colors.green,
                                    fontStyle: FontStyle.italic
                                  ),
                                ),
                              ),
                          ],
                        ),

                        const SizedBox(height: 8),

                        // ✅ STATUS
                        Text(
                          'Status: ${b['status']}',
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
  Widget _buildDropdown(String label, String? value, List<String> items, Function(String?) onChanged) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 0),
      decoration: BoxDecoration(
        color: Colors.grey[200],
        borderRadius: BorderRadius.circular(8),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          hint: Text(label),
          value: value,
          isDense: true,
          items: items.map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
          onChanged: onChanged,
        ),
      ),
    );
  }

  // Admin Toggle Payment (Same as Center but uses "Admin" as updater implicitly via 'updated_by_name')
  Future<void> toggleAdminPayment(String bookingId, String currentStatus) async {
    // Logic: Toggle Unpaid <-> Paid
    final newStatus = currentStatus == 'Paid' ? 'Unpaid' : 'Paid';
    
    // Confirm dialog
    bool? confirm = await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Mark as $newStatus?'),
        content: Text('Set status to $newStatus for this booking?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          ElevatedButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Yes')),
        ],
      ),
    );

    if (confirm == true) {
      await http.post(
        Uri.parse('${Config.baseUrl}/center/update_payment_status'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          "booking_id": bookingId,
          "payment_status": newStatus,
          "updated_by_name": "Admin" 
        }),
      );
      loadBookings();
    }
  }

  Widget _summaryCard(String title, String count, Color color) {
    return Card(
      elevation: 2,
      margin: const EdgeInsets.only(right: 8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          border: Border(top: BorderSide(color: color, width: 3)),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          children: [
            Text(title, style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.w600)),
            const SizedBox(height: 4),
            Text(count, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }
}
