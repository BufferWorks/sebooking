import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../services/api_service.dart';
import 'receipt_detail_screen.dart';

class BookingHistoryScreen extends StatefulWidget {
  const BookingHistoryScreen({super.key});

  @override
  State<BookingHistoryScreen> createState() => _BookingHistoryScreenState();
}

class _BookingHistoryScreenState extends State<BookingHistoryScreen> {
  final mobileCtrl = TextEditingController();
  bool loading = false;
  List history = [];

  Future<void> fetch() async {
    if (mobileCtrl.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Enter mobile number')),
      );
      return;
    }

    setState(() => loading = true);
    history = await ApiService.getHistory(mobileCtrl.text.trim());
    
    // Inject mobile number into history items since API doesn't return it
    for (var item in history) {
      item['mobile'] = mobileCtrl.text.trim();
    }

    setState(() => loading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('My Receipts')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(
              controller: mobileCtrl,
              keyboardType: TextInputType.phone,
              decoration: const InputDecoration(
                labelText: 'Enter Mobile Number',
                border: OutlineInputBorder(),
              ),
            ),

            const SizedBox(height: 10),

            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: loading ? null : fetch,
                child: loading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text('Show Receipts'),
              ),
            ),

            const SizedBox(height: 10),

            Expanded(
              child: history.isEmpty
                  ? const Center(
                child: Text(
                  'No receipts found',
                  style: TextStyle(fontSize: 16),
                ),
              )
                  : ListView.builder(
                itemCount: history.length,
                itemBuilder: (_, i) {
                  final h = history[i];

                  final date = DateFormat('dd MMM yyyy, hh:mm a').format(
                      DateTime.fromMillisecondsSinceEpoch((h['date'] ?? 0) * 1000));

                  return Card(
                    child: ListTile(
                      leading: const Icon(
                        Icons.receipt_long,
                        color: Color(0xFF1E88E5),
                      ),
                      title: Text(
                        h['test_name'],
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      subtitle: Text(
                        'Date: $date\nCenter: ${h['center_name']}\nBooking ID: ${h['booking_id']}',
                      ),
                      trailing: Chip(
                        label: Text(h['status']),
                        backgroundColor: h['status'] == 'Done'
                            ? Colors.green.shade100
                            : Colors.orange.shade100,
                      ),
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) =>
                                ReceiptDetailScreen(receipt: h),
                          ),
                        );
                      },
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
