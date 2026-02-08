import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import 'package:se_booking/config.dart';

class ApiService {
  static String get baseUrl => Config.baseUrl;

  static Future<List> getTests(String category) async {
    final res = await http.get(
      Uri.parse('$baseUrl/get_tests?category=$category'),
    );
    return json.decode(res.body);
  }

  static Future<List> getCenters(int testId) async {
    final res = await http.get(
      Uri.parse('$baseUrl/get_centers?test_id=$testId'),
    );
    return json.decode(res.body);
  }

  static Future<String> bookTest({
    required String name,
    required String mobile,
    required int centerId,
    required int testId,
    required double price,
    String paymentStatus = "Unpaid",
    double paidAmount = 0.0,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final isAgent = prefs.getBool('agent_logged_in') ?? false;
    final agentName = prefs.getString('agent_name') ?? "Agent";

    final res = await http.post(
      Uri.parse('$baseUrl/add_booking'),
      headers: {'Content-Type': 'application/json'},
      body: json.encode({
        "name": name,
        "mobile": mobile,
        "center_id": centerId,
        "test_id": testId,
        "price": price,
        "booked_by": isAgent ? agentName : "Customer",
        "payment_status": paymentStatus,
        "paid_amount": paidAmount,
      }),
    );

    return json.decode(res.body)["booking_id"];
  }

  static Future<List> getHistory(String mobile) async {
    final res = await http.get(
      Uri.parse('$baseUrl/bookings_by_mobile?mobile=$mobile'),
    );
    return json.decode(res.body);
  }

  static Future<void> updatePaymentDetails({
    required String bookingId,
    required double agentCollected,
    required double centerCollected,
    double adminCollected = 0.0,
    required String updatedByName,
  }) async {
    await http.post(
      Uri.parse('$baseUrl/update_payment_details'),
      headers: {'Content-Type': 'application/json'},
      body: json.encode({
        "booking_id": bookingId,
        "agent_collected": agentCollected,
        "center_collected": centerCollected,
        "admin_collected": adminCollected,
        "updated_by_name": updatedByName,
      }),
    );
  }

  static Future<List> getCenterStats({int? startTs, int? endTs}) async {
    String url = '$baseUrl/admin/center_stats';
    if (startTs != null && endTs != null) {
      url += '?start_ts=$startTs&end_ts=$endTs';
    }
    
    final res = await http.get(Uri.parse(url));
    return json.decode(res.body);
  }
}
