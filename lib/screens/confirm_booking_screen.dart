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
  bool _userPaid = false; 
  final _amountController = TextEditingController();
  final _txnController = TextEditingController();
  
  late TextEditingController _nameController;
  late TextEditingController _mobileController;
  final _ageController = TextEditingController();
  final _addressController = TextEditingController();
  String _gender = 'Male';

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.patientName);
    _mobileController = TextEditingController(text: widget.mobile);
    
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
    // Validation
    if (_nameController.text.isEmpty ||
        _mobileController.text.isEmpty ||
        _ageController.text.isEmpty ||
        _addressController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please fill all required fields')));
      return;
    }

    if (!RegExp(r'^\d{10,12}$').hasMatch(_mobileController.text)) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Mobile number must be 10-12 digits')));
      return;
    }

    if (!isAgent && _txnController.text.length < 4) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please enter valid Transaction ID (min 4 chars)')));
      return;
    }

    setState(() => loading = true);

    final bookingId = await ApiService.bookTest(
      name: _nameController.text,
      mobile: _mobileController.text,
      age: _ageController.text,
      gender: _gender,
      address: _addressController.text,
      centerId: widget.centerId,
      testId: widget.testId,
      price: widget.price,
      paymentStatus: isAgent ? widget.paymentStatus : "Pending Verification (Txn: ${_txnController.text})",
      paidAmount: isAgent 
          ? (double.tryParse(_amountController.text) ?? 0.0) 
          : widget.price,
    );
    
    // ... rest of method (showSuccessDialog)

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

            Text(
              (!isAgent && _txnController.text.isNotEmpty)
                  ? 'Payment verification pending.\nPlease show this Booking ID at the center.'
                  : 'Please show this receipt at the center.',
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 14),
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
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    // Patient Form
                    TextField(
                      controller: _nameController, 
                      decoration: const InputDecoration(labelText: 'Patient Name *', border: OutlineInputBorder())
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _mobileController, 
                      keyboardType: TextInputType.phone,
                      decoration: const InputDecoration(labelText: 'Mobile Number (10-12 digits) *', border: OutlineInputBorder())
                    ),
                    const SizedBox(height: 12),
                    Row(
                        children: [
                            Expanded(child: TextField(
                              controller: _ageController, 
                              keyboardType: TextInputType.number, 
                              decoration: const InputDecoration(labelText: 'Age *', border: OutlineInputBorder())
                            )),
                            const SizedBox(width: 12),
                            Expanded(child: DropdownButtonFormField<String>(
                                value: _gender,
                                decoration: const InputDecoration(labelText: 'Gender *', border: OutlineInputBorder()),
                                items: ['Male', 'Female', 'Other'].map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
                                onChanged: (v) => setState(() => _gender = v!),
                            )),
                        ],
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _addressController, 
                      maxLines: 2, 
                      decoration: const InputDecoration(labelText: 'Address *', border: OutlineInputBorder())
                    ),
                    
                    const SizedBox(height: 24),
                    const Text("Test Information", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                    const Divider(),
                    _row('Test', widget.testName),
                    const Divider(),
                    _row('Center', widget.centerName),
                    const Divider(),
                    _row('Price', '₹${widget.price.toStringAsFixed(0)}', bold: true),
                    const Divider(),

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
                         TextField(
                            controller: _txnController,
                            decoration: const InputDecoration(
                              labelText: "Enter UPI Transaction ID / Ref No",
                              hintText: "e.g. 3214xxxxxxx",
                              border: OutlineInputBorder(),
                              helperText: "Required for payment verification",
                            ),
                            onChanged: (val) {
                              setState(() {});
                            },
                         ),
                         const SizedBox(height: 8),
                         const Text("Your booking will be 'Pending Verification' until approved.", style: TextStyle(color: Colors.orange, fontSize: 12)),
                    ],
                  ],
                ),
              ),
            ),
            
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
                 TextField(
                    controller: _txnController,
                    decoration: const InputDecoration(
                      labelText: "Enter UPI Transaction ID / Ref No",
                      hintText: "e.g. 3214xxxxxxx",
                      border: OutlineInputBorder(),
                      helperText: "Required for payment verification",
                    ),
                    onChanged: (val) {
                      setState(() {});
                    },
                 ),
                 const SizedBox(height: 8),
                 const Text("Your booking will be 'Pending Verification' until approved.", style: TextStyle(color: Colors.orange, fontSize: 12)),
            ],

            const Spacer(),

            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                // Agent: standard loading check
                // User: must enter Txn ID
                onPressed: loading || (!isAgent && _txnController.text.length < 4) ? null : book,
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
