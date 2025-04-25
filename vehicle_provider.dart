import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:async';
import '../models/vehicle.dart';
import '../models/fuel_entry.dart';

class VehicleProvider with ChangeNotifier {
  List<Vehicle> _vehicles = [];
  Vehicle? _selectedVehicle;
  bool _isLoading = false;
  bool _isInitialized = false;
  StreamSubscription<QuerySnapshot>? _vehicleSubscription;

  List<Vehicle> get vehicles => _vehicles;
  Vehicle? get selectedVehicle => _selectedVehicle;
  bool get isLoading => _isLoading;
  bool get isInitialized => _isInitialized;

  VehicleProvider() {
    debugPrint('VehicleProvider initialized');
    _initialize();
  }

  @override
  void dispose() {
    _vehicleSubscription?.cancel();
    super.dispose();
  }

  Future<void> _initialize() async {
    try {
      debugPrint('Starting initialization...');
      setState(() => _isLoading = true);
      
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        debugPrint('No user logged in during initialization');
        setState(() {
          _vehicles = [];
          _isLoading = false;
          _isInitialized = true;
        });
        return;
      }

      debugPrint('Setting up Firestore listener...');
      _vehicleSubscription?.cancel();
      _vehicleSubscription = FirebaseFirestore.instance
          .collection('vehicles')
          .where('userId', isEqualTo: user.uid)
          .snapshots()
          .listen((snapshot) async {
        debugPrint('Received vehicles update with ${snapshot.docs.length} documents');
        
        if (snapshot.docs.isEmpty) {
          setState(() {
            _vehicles = [];
            _isLoading = false;
            _isInitialized = true;
          });
          return;
        }

        try {
          final vehicles = await Future.wait(
            snapshot.docs.map((doc) async {
              final vehicleData = doc.data();
              try {
                debugPrint('Fetching fuel entries for vehicle ${doc.id}...');
                final fuelEntriesSnapshot = await FirebaseFirestore.instance
                    .collection('fuel_entries')
                    .where('vehicleId', isEqualTo: doc.id)
                    .orderBy('date', descending: true)
                    .get();

                debugPrint('Found ${fuelEntriesSnapshot.docs.length} fuel entries for vehicle ${doc.id}');
                
                final fuelEntries = fuelEntriesSnapshot.docs
                    .map((entryDoc) {
                      debugPrint('Processing fuel entry document: ${entryDoc.id}');
                      debugPrint('Document data: ${entryDoc.data()}');
                      final entryData = entryDoc.data();
                      return FuelEntry.fromMap(entryData, entryDoc.id);
                    })
                    .toList();

                debugPrint('Processed fuel entries: $fuelEntries');

                // Create the vehicle with the fuel entries
                final vehicle = Vehicle.fromFirestore(vehicleData, doc.id);
                return vehicle.copyWith(fuelEntries: fuelEntries);
              } catch (e) {
                debugPrint('Error loading fuel entries for vehicle ${doc.id}: $e');
                return Vehicle.fromFirestore(vehicleData, doc.id);
              }
            }),
          );

          setState(() {
            _vehicles = vehicles;
            _isLoading = false;
            _isInitialized = true;
          });
        } catch (e) {
          debugPrint('Error processing vehicles update: $e');
          setState(() {
            _vehicles = [];
            _isLoading = false;
            _isInitialized = true;
          });
        }
      });
    } catch (e) {
      debugPrint('Error during initialization: $e');
      setState(() {
        _vehicles = [];
        _isLoading = false;
        _isInitialized = true;
      });
    }
  }

  Future<void> refresh() async {
    debugPrint('Refreshing vehicle data...');
    await _initialize();
  }

  void setState(void Function() fn) {
    fn();
    notifyListeners();
  }

  void selectVehicle(Vehicle vehicle) {
    _selectedVehicle = vehicle;
    notifyListeners();
  }

  void clearSelection() {
    _selectedVehicle = null;
    notifyListeners();
  }

  Future<void> addVehicle(Vehicle vehicle) async {
    try {
      debugPrint('Starting addVehicle...');
      setState(() => _isLoading = true);
      
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        debugPrint('No user logged in during addVehicle');
        setState(() => _isLoading = false);
        return;
      }

      debugPrint('Adding vehicle to Firestore...');
      debugPrint('User ID: ${user.uid}');
      debugPrint('Vehicle data: ${vehicle.toMap()}');
      
      final docRef = await FirebaseFirestore.instance
          .collection('vehicles')
          .add(vehicle.toMap());

      debugPrint('Vehicle added with ID: ${docRef.id}');
      debugPrint('Full path: vehicles/${docRef.id}');
      
      // Create a new vehicle instance with the ID instead of modifying the existing one
      final vehicleWithId = vehicle.copyWith(id: docRef.id);
      
      // Update the local state with the new vehicle
      setState(() {
        _vehicles = [..._vehicles, vehicleWithId];
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('Error in addVehicle: $e');
      setState(() {
        _vehicles = [];
        _isLoading = false;
      });
      return;
    } finally {
      debugPrint('Setting loading state to false after addVehicle');
      setState(() => _isLoading = false);
    }
  }

  Future<void> updateVehicle(Vehicle vehicle) async {
    try {
      debugPrint('Starting updateVehicle...');
      setState(() => _isLoading = true);
      
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        debugPrint('No user logged in during updateVehicle');
        setState(() => _isLoading = false);
        return;
      }

      debugPrint('Updating vehicle ${vehicle.id} in Firestore...');
      await FirebaseFirestore.instance
          .collection('vehicles')
          .doc(vehicle.id)
          .update(vehicle.toMap());
    } catch (e) {
      debugPrint('Error in updateVehicle: $e');
      setState(() {
        _vehicles = [];
        _isLoading = false;
      });
      return;
    } finally {
      debugPrint('Setting loading state to false after updateVehicle');
      setState(() => _isLoading = false);
    }
  }

  Future<void> deleteVehicle(String vehicleId) async {
    try {
      debugPrint('Starting deleteVehicle...');
      setState(() => _isLoading = true);
      
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        debugPrint('No user logged in during deleteVehicle');
        setState(() => _isLoading = false);
        return;
      }

      debugPrint('Deleting vehicle $vehicleId from Firestore...');
      
      // First, delete all fuel entries for this vehicle
      final fuelEntriesSnapshot = await FirebaseFirestore.instance
          .collection('fuel_entries')
          .where('vehicleId', isEqualTo: vehicleId)
          .get();

      debugPrint('Found ${fuelEntriesSnapshot.docs.length} fuel entries to delete');
      
      for (var doc in fuelEntriesSnapshot.docs) {
        await doc.reference.delete();
      }

      // Then delete the vehicle
      await FirebaseFirestore.instance
          .collection('vehicles')
          .doc(vehicleId)
          .delete();
    } catch (e) {
      debugPrint('Error in deleteVehicle: $e');
      setState(() {
        _vehicles = [];
        _isLoading = false;
      });
      return;
    } finally {
      debugPrint('Setting loading state to false after deleteVehicle');
      setState(() => _isLoading = false);
    }
  }

  Future<void> updateFuelEntry(FuelEntry entry) async {
    try {
      debugPrint('Starting updateFuelEntry...');
      setState(() => _isLoading = true);
      
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        debugPrint('No user logged in during updateFuelEntry');
        setState(() => _isLoading = false);
        return;
      }

      if (entry.id == null || entry.id!.isEmpty) {
        debugPrint('Invalid fuel entry ID: ${entry.id}');
        setState(() => _isLoading = false);
        return;
      }

      debugPrint('Updating fuel entry ${entry.id} in Firestore...');
      final entryMap = entry.toMap();
      debugPrint('Entry data to update: $entryMap');
      
      await FirebaseFirestore.instance
          .collection('fuel_entries')
          .doc(entry.id)
          .update(entryMap);

      // Update the local state immediately
      final updatedVehicles = _vehicles.map<Vehicle>((vehicle) {
        if (vehicle.id == entry.vehicleId) {
          final updatedEntries = vehicle.fuelEntries.map<FuelEntry>((e) {
            if (e.id == entry.id) {
              return entry;
            }
            return e;
          }).toList();
          return vehicle.copyWith(fuelEntries: updatedEntries);
        }
        return vehicle;
      }).toList();

      setState(() {
        _vehicles = updatedVehicles;
        _isLoading = false;
      });

      // Force a refresh to ensure Firestore data is in sync
      await refresh();

      debugPrint('Fuel entry updated successfully in both local state and Firestore');
    } catch (e) {
      debugPrint('Error in updateFuelEntry: $e');
      setState(() => _isLoading = false);
      rethrow;
    }
  }

  Future<void> deleteFuelEntry(String entryId) async {
    try {
      debugPrint('Starting deleteFuelEntry...');
      setState(() => _isLoading = true);
      
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        debugPrint('No user logged in during deleteFuelEntry');
        setState(() => _isLoading = false);
        return;
      }

      if (entryId.isEmpty) {
        debugPrint('Invalid fuel entry ID: empty string');
        setState(() => _isLoading = false);
        return;
      }

      // First get the entry to find its vehicleId
      final entryDoc = await FirebaseFirestore.instance
          .collection('fuel_entries')
          .doc(entryId)
          .get();
      
      if (!entryDoc.exists) {
        debugPrint('Fuel entry not found with ID: $entryId');
        setState(() => _isLoading = false);
        return;
      }

      final vehicleId = entryDoc.data()!['vehicleId'] as String;
      debugPrint('Found vehicleId: $vehicleId for entry: $entryId');

      debugPrint('Deleting fuel entry $entryId from Firestore...');
      await FirebaseFirestore.instance
          .collection('fuel_entries')
          .doc(entryId)
          .delete();

      // Update the local state immediately
      final updatedVehicles = _vehicles.map<Vehicle>((vehicle) {
        if (vehicle.id == vehicleId) {
          final updatedEntries = vehicle.fuelEntries
              .where((e) => e.id != entryId)
              .toList();
          return vehicle.copyWith(fuelEntries: updatedEntries);
        }
        return vehicle;
      }).toList();

      setState(() {
        _vehicles = updatedVehicles;
        _isLoading = false;
      });

      debugPrint('Fuel entry deleted successfully from both local state and Firestore');
    } catch (e) {
      debugPrint('Error in deleteFuelEntry: $e');
      setState(() => _isLoading = false);
      rethrow;
    }
  }
} 