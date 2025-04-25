import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

class FuelEntry {
  final String? id;
  final String vehicleId;
  final DateTime date;
  final double odometer;
  final double amount;
  final double price;
  final double totalCost;
  final String userId;

  FuelEntry({
    this.id,
    required this.vehicleId,
    required this.date,
    required this.odometer,
    required this.amount,
    required this.price,
    required this.totalCost,
    required this.userId,
  });

  factory FuelEntry.fromMap(Map<String, dynamic> data, String documentId) {
    try {
      return FuelEntry(
        id: documentId,
        vehicleId: data['vehicleId'] as String,
        date: (data['date'] as Timestamp).toDate(),
        odometer: (data['odometer'] as num).toDouble(),
        amount: (data['amount'] as num).toDouble(),
        price: (data['price'] as num).toDouble(),
        totalCost: (data['totalCost'] as num).toDouble(),
        userId: data['userId'] as String,
      );
    } catch (e) {
      debugPrint('Error creating FuelEntry from map: $e');
      debugPrint('Data: $data');
      rethrow;
    }
  }

  Map<String, dynamic> toMap() {
    return {
      'vehicleId': vehicleId,
      'date': Timestamp.fromDate(date),
      'odometer': odometer,
      'amount': amount,
      'price': price,
      'totalCost': totalCost,
      'userId': userId,
    };
  }
} 