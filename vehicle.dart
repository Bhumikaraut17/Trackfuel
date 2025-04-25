import 'package:flutter/foundation.dart';
import 'fuel_entry.dart';

class Vehicle {
  final String? id;
  final String name;
  final String make;
  final String model;
  final int year;
  final String userId;
  final List<FuelEntry> fuelEntries;

  Vehicle({
    this.id,
    required this.name,
    required this.make,
    required this.model,
    required this.year,
    required this.userId,
    this.fuelEntries = const [],
  });

  Vehicle copyWith({
    String? id,
    String? name,
    String? make,
    String? model,
    int? year,
    List<FuelEntry>? fuelEntries,
  }) {
    return Vehicle(
      id: id ?? this.id,
      name: name ?? this.name,
      make: make ?? this.make,
      model: model ?? this.model,
      year: year ?? this.year,
      userId: userId,
      fuelEntries: fuelEntries ?? this.fuelEntries,
    );
  }

  factory Vehicle.fromFirestore(Map<String, dynamic> data, String docId) {
    try {
      final name = data['name'] as String?;
      final make = data['make'] as String?;
      final model = data['model'] as String?;
      final year = data['year'] as int?;
      final userId = data['userId'] as String?;

      if (name == null || make == null || model == null || year == null || userId == null) {
        throw Exception('Missing required vehicle data');
      }

      // Fuel entries are fetched separately, so we don't need to process them here
      return Vehicle(
        id: docId,
        name: name,
        make: make,
        model: model,
        year: year,
        userId: userId,
        fuelEntries: [], // Will be populated by the provider
      );
    } catch (e) {
      // Replace print with debugPrint or remove logging in production
      // Consider using a proper logging framework in the future
      debugPrint('Error creating Vehicle from Firestore: $e');
      debugPrint('Data: $data');
      rethrow;
    }
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'make': make,
      'model': model,
      'year': year,
      'userId': userId,
      'fuelEntries': fuelEntries.map((entry) => entry.toMap()).toList(),
    };
  }
} 