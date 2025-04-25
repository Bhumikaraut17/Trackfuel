import 'package:flutter/foundation.dart';
import '../services/fuel_price_service.dart';

class FuelPriceProvider with ChangeNotifier {
  final FuelPriceService _fuelPriceService = FuelPriceService();
  Map<String, dynamic>? _currentFuelPrices;
  bool _isLoading = false;
  String? _error;

  Map<String, dynamic>? get currentFuelPrices => _currentFuelPrices;
  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<void> fetchFuelPrices(String city) async {
    debugPrint('Starting to fetch fuel prices for city: $city');
    
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      debugPrint('Calling fuel price service...');
      _currentFuelPrices = await _fuelPriceService.getFuelPrice(city);
      debugPrint('Successfully fetched fuel prices: $_currentFuelPrices');
    } catch (e) {
      debugPrint('Error in fetchFuelPrices: $e');
      _error = e.toString();
      _currentFuelPrices = null;
    } finally {
      _isLoading = false;
      debugPrint('Finished fetching fuel prices. Loading: $_isLoading, Error: $_error');
      notifyListeners();
    }
  }
} 