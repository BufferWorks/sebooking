import 'package:flutter/foundation.dart';

class Config {
  static const String _localUrl = "http://147.79.71.199:8000";
  static const String _prodUrl = "https://sebooking.in/api";

  static String get baseUrl => kReleaseMode ? _prodUrl : _localUrl;
}
