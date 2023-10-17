import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class LaravelPassport {
  static Future<void> exchangeToken(
      String? token, Map<String, dynamic> parameters) async {
    if (token != null) {
      Map<String, dynamic> defaultParameters = {
        'provider': 'google',
        'token': token
      };

      Map<String, dynamic> mergedParameters = {
        ...defaultParameters,
        ...parameters
      };

      const url = 'http://localhost:8000/api/login';
      final response = await http.post(
        Uri.parse(url),
        headers: {'Content-Type': 'application/json'},
        body: json.encode(mergedParameters),
      );

      if (response.statusCode == 200) {
        debugPrint(response.body.toString());
      } else {
        debugPrint('Token Exchange Failed');
      }
    }
  }
}
