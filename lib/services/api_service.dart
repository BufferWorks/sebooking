import 'dart:convert';
import 'package:http/http.dart' as http;

import 'package:se_booking/config.dart';

class ApiService {
  static const String baseUrl = Config.baseUrl;

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
  }) async {
    final res = await http.post(
      Uri.parse('$baseUrl/add_booking'),
      headers: {'Content-Type': 'application/json'},
      body: json.encode({
        "name": name,
        "mobile": mobile,
        "center_id": centerId,
        "test_id": testId,
        "price": price,
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
}
