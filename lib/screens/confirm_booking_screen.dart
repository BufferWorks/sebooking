import 'package:flutter/material.dart';
import '../services/api_service.dart';

import 'package:shared_preferences/shared_preferences.dart';

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
  bool isAgent = false;
  bool _userPaid = false; // For direct user payment check
  final _amountController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _checkAgent();
    if (widget.paymentStatus == 'Paid') {
      _amountController.text = widget.price.toStringAsFixed(0);
    } else {
      _amountController.text = "0";
    }
  }

  Future<void> _checkAgent() async {
    final prefs = await SharedPreferences.getInstance();
    if (mounted) {
      setState(() {
        isAgent = prefs.getBool('agent_logged_in') ?? false;
        if (isAgent) {
          _amountController.text = widget.price.toStringAsFixed(0);
        }
      });
    }
  }

  Future<void> book() async {
    setState(() => loading = true);

    final bookingId = await ApiService.bookTest(
      name: widget.patientName,
      mobile: widget.mobile,
      centerId: widget.centerId,
      testId: widget.testId,
      price: widget.price,
      paymentStatus: isAgent ? widget.paymentStatus : "Paid",
      paidAmount: isAgent 
          ? (double.tryParse(_amountController.text) ?? 0.0) 
          : widget.price,
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
            
            if (isAgent) ...[
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.blue.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.blue),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                       const Text("Agent Collection Required", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.blue)),
                       const SizedBox(height: 4),
                       Text("You must collect the full amount of ₹${widget.price.toStringAsFixed(0)} from the patient.", style: const TextStyle(fontSize: 12)),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _amountController,
                  keyboardType: TextInputType.number,
                  readOnly: true, // Enforce full payment
                  decoration: const InputDecoration(
                    labelText: 'Amount Collected (₹)',
                    prefixText: '₹ ',
                    border: OutlineInputBorder(),
                    fillColor: Colors.white,
                    filled: true,
                  ),
                ),
            ] else ...[
                 // USER QR PAYMENT
                 const SizedBox(height: 24),
                 const Center(child: Text("Scan & Pay via UPI", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16))),
                 const SizedBox(height: 12),
                 Center(
                   child: Container(
                     padding: const EdgeInsets.all(8),
                     decoration: BoxDecoration(border: Border.all(color: Colors.grey)),
                     child: Image.network(
                       "https://api.qrserver.com/v1/create-qr-code/?size=200x200&data=upi%3A%2F%2Fpay%3Fpa%3D9669002008%40ybl%26pn%3DSeBooking%26am%3D${widget.price}%26tn%3DBooking",
                       height: 150,
                       width: 150,
                       loadingBuilder: (context, child, loadingProgress) {
                         if (loadingProgress == null) return child;
                         return const SizedBox(height: 150, width: 150, child: Center(child: CircularProgressIndicator()));
                       },
                       errorBuilder: (context, error, stackTrace) {
                         return const SizedBox(height: 150, width: 150, child: Center(child: Icon(Icons.error)));
                       },
                     ),
                   ),
                 ),
                 const SizedBox(height: 16),
                 CheckboxListTile(
                   contentPadding: EdgeInsets.zero,
                   title: Text("I have scanned and paid ₹${widget.price.toStringAsFixed(0)}"),
                   value: _userPaid,
                   onChanged: (val) {
                     setState(() {
                       _userPaid = val ?? false;
                     });
                   },
                   controlAffinity: ListTileControlAffinity.leading,
                 ),
            ],

            const Spacer(),

            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: loading || (!isAgent && !_userPaid) ? null : book,
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
