import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';

class FuelPriceService {
  static const String _baseUrl = 'https://fuel-price-india-diesel-petrol-price-api-free.p.rapidapi.com';
  static const String _apiKey = 'c76c8255d1msh7f113ddd042e1e4p1776e4jsn689d7fc6e6f4';

  Future<Map<String, dynamic>> getFuelPrice(String city) async {
    final url = Uri.parse('$_baseUrl/price_in_india_by_city?city=$city');

    debugPrint('Fetching fuel prices for city: $city');
    debugPrint('API URL: $url');

    try {
      final response = await http.get(
        url,
        headers: {
          'X-RapidAPI-Key': _apiKey,
          'X-RapidAPI-Host': 'fuel-price-india-diesel-petrol-price-api-free.p.rapidapi.com',
        },
      );

      debugPrint('API Response Status: ${response.statusCode}');
      debugPrint('API Response Body: ${response.body}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data is Map<String, dynamic>) {
          return {
            'petrol': data['petrol'] ?? 0.0,
            'diesel': data['diesel'] ?? 0.0,
          };
        } else {
          throw Exception('Invalid response format');
        }
      } else {
        throw Exception('Failed to load fuel prices: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      debugPrint('Error fetching fuel prices: $e');
      throw Exception('Error fetching fuel prices: $e');
    }
  }
} 