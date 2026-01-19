import 'package:flutter/material.dart';

class ReceiptDetailScreen extends StatelessWidget {
  final Map receipt;

  const ReceiptDetailScreen({super.key, required this.receipt});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Receipt Details')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    const Icon(
                      Icons.receipt,
                      size: 48,
                      color: Colors.green,
                    ),
                    const SizedBox(height: 12),

                    _row('Booking ID', receipt['booking_id']),
                    _row('Patient', receipt['patient_name']),
                    _row('Test', receipt['test_name']),
                    _row('Center', receipt['center_name']),
                    _row('Amount', '₹${receipt['price']}'),
                    _row('Status', receipt['status']),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 20),

            const Text(
              'Please show this receipt at the center.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 16),
            ),
          ],
        ),
      ),
    );
  }

  Widget _row(String k, String v) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(k),
          Text(
            v,
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }
}
