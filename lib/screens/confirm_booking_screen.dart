import 'package:flutter/material.dart';
import '../services/api_service.dart';

class ConfirmBookingScreen extends StatefulWidget {
  final int testId;
  final String testName;
  final int centerId;
  final String centerName;
  final double price;
  final String patientName;
  final String mobile;
  final String paymentStatus;

  const ConfirmBookingScreen({
    super.key,
    required this.testId,
    required this.testName,
    required this.centerId,
    required this.centerName,
    required this.price,
    required this.patientName,
    required this.mobile,
    this.paymentStatus = "Unpaid",
  });

  @override
  State<ConfirmBookingScreen> createState() => _ConfirmBookingScreenState();
}

class _ConfirmBookingScreenState extends State<ConfirmBookingScreen> {
  bool loading = false;

  Future<void> book() async {
    setState(() => loading = true);

    final bookingId = await ApiService.bookTest(
      name: widget.patientName,
      mobile: widget.mobile,
      centerId: widget.centerId,
      testId: widget.testId,
      price: widget.price,
      paymentStatus: widget.paymentStatus,
    );

    if (!mounted) return;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        title: const Text('Booking Confirmed'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.check_circle,
              color: Colors.green,
              size: 48,
            ),
            const SizedBox(height: 12),

            const Text(
              'Your Booking ID',
              style: TextStyle(fontSize: 14),
            ),

            const SizedBox(height: 8),

            Container(
              padding: const EdgeInsets.symmetric(
                vertical: 10,
                horizontal: 16,
              ),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.green),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                bookingId,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1,
                ),
              ),
            ),

            const SizedBox(height: 12),

            const Text(
              'Please show this receipt at the center\nand pay the amount there.',
              textAlign: TextAlign.center,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.popUntil(context, (r) => r.isFirst);
            },
            child: const Text('Done'),
          ),
        ],
      ),
    );

    setState(() => loading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Confirm Booking')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    _row('Patient', widget.patientName),
                    _row('Test', widget.testName),
                    _row('Center', widget.centerName),
                    const Divider(),
                    _row(
                      'Amount',
                      '₹${widget.price.toStringAsFixed(0)}',
                      bold: true,
                    ),
                  ],
                ),
              ),
            ),

            const Spacer(),

            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: loading ? null : book,
                child: loading
                    ? const SizedBox(
                  height: 22,
                  width: 22,
                  child: CircularProgressIndicator(
                    color: Colors.white,
                    strokeWidth: 2,
                  ),
                )
                    : const Text(
                  'Confirm & Book',
                  style: TextStyle(fontSize: 16),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _row(String k, String v, {bool bold = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(k),
          Text(
            v,
            style: TextStyle(
              fontWeight: bold ? FontWeight.bold : FontWeight.normal,
            ),
          ),
        ],
      ),
    );
  }
}
