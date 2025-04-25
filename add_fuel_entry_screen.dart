import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:trackfuel/models/fuel_entry.dart';
import 'package:trackfuel/providers/vehicle_provider.dart';
import 'package:trackfuel/models/vehicle.dart';

class AddFuelEntryScreen extends StatefulWidget {
  final Vehicle vehicle;
  final VehicleProvider vehicleProvider;
  final FuelEntry? existingEntry;

  const AddFuelEntryScreen({
    super.key,
    required this.vehicle,
    required this.vehicleProvider,
    this.existingEntry,
  });

  @override
  State<AddFuelEntryScreen> createState() => _AddFuelEntryScreenState();
}

class _AddFuelEntryScreenState extends State<AddFuelEntryScreen> {
  final _formKey = GlobalKey<FormState>();
  final _dateController = TextEditingController();
  final _odometerController = TextEditingController();
  final _litersController = TextEditingController();
  final _pricePerLiterController = TextEditingController();
  final _totalCostController = TextEditingController();
  final _notesController = TextEditingController();
  DateTime _selectedDate = DateTime.now();
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    if (widget.existingEntry != null) {
      _selectedDate = widget.existingEntry!.date;
      _odometerController.text = widget.existingEntry!.odometer.toString();
      _litersController.text = widget.existingEntry!.amount.toString();
      _pricePerLiterController.text = widget.existingEntry!.price.toString();
      _totalCostController.text = widget.existingEntry!.totalCost.toString();
    }
    _dateController.text = _formatDate(_selectedDate);
  }

  @override
  void dispose() {
    _dateController.dispose();
    _odometerController.dispose();
    _litersController.dispose();
    _pricePerLiterController.dispose();
    _totalCostController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
        _dateController.text = _formatDate(picked);
      });
    }
  }

  Future<void> _saveFuelEntry() async {
    if (!_formKey.currentState!.validate()) {
      debugPrint('Form validation failed');
      return;
    }

    try {
      debugPrint('Starting _saveFuelEntry...');
      setState(() => _isLoading = true);

      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        debugPrint('No user logged in during _saveFuelEntry');
        setState(() => _isLoading = false);
        return;
      }

      final fuelEntry = FuelEntry(
        id: widget.existingEntry?.id,
        vehicleId: widget.vehicle.id!,
        date: _selectedDate,
        odometer: double.parse(_odometerController.text),
        amount: double.parse(_litersController.text),
        price: double.parse(_pricePerLiterController.text),
        totalCost: double.parse(_totalCostController.text),
        userId: user.uid,
      );

      if (widget.existingEntry != null) {
        // Updating existing entry
        debugPrint('Updating existing fuel entry with ID: ${fuelEntry.id}');
        await widget.vehicleProvider.updateFuelEntry(fuelEntry);
      } else {
        // Creating new entry
        debugPrint('Creating new fuel entry...');
        final docRef = await FirebaseFirestore.instance
            .collection('fuel_entries')
            .add(fuelEntry.toMap());
        debugPrint('New fuel entry added with ID: ${docRef.id}');
      }

      debugPrint('Refreshing vehicle data...');
      await widget.vehicleProvider.refresh();

      debugPrint('Fuel entry saved successfully');
      if (mounted) {
        Navigator.pop(context);
      }
    } catch (e) {
      debugPrint('Error in _saveFuelEntry: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error saving fuel entry: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        debugPrint('Setting loading state to false');
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.existingEntry != null ? 'Edit Fuel Entry' : 'Add Fuel Entry'),
        elevation: 0,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Card(
                      elevation: 2,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Entry Details',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 16),
                            TextFormField(
                              controller: _dateController,
                              decoration: InputDecoration(
                                labelText: 'Date',
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                prefixIcon: const Icon(Icons.calendar_today),
                                filled: true,
                                fillColor: Colors.grey[50],
                              ),
                              readOnly: true,
                              onTap: () => _selectDate(context),
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Please select a date';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 16),
                            TextFormField(
                              controller: _odometerController,
                              decoration: InputDecoration(
                                labelText: 'Odometer Reading',
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                prefixIcon: const Icon(Icons.speed),
                                suffixText: 'km',
                                filled: true,
                                fillColor: Colors.grey[50],
                              ),
                              keyboardType: TextInputType.number,
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Please enter the odometer reading';
                                }
                                if (double.tryParse(value) == null) {
                                  return 'Please enter a valid number';
                                }
                                return null;
                              },
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Card(
                      elevation: 2,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Fuel Details',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 16),
                            TextFormField(
                              controller: _litersController,
                              decoration: InputDecoration(
                                labelText: 'Liters',
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                prefixIcon: const Icon(Icons.local_gas_station),
                                suffixText: 'L',
                                filled: true,
                                fillColor: Colors.grey[50],
                              ),
                              keyboardType: TextInputType.number,
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Please enter the amount of fuel';
                                }
                                if (double.tryParse(value) == null) {
                                  return 'Please enter a valid number';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 16),
                            TextFormField(
                              controller: _pricePerLiterController,
                              decoration: InputDecoration(
                                labelText: 'Price per Liter',
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                prefixIcon: const Icon(Icons.attach_money),
                                suffixText: '₹/L',
                                filled: true,
                                fillColor: Colors.grey[50],
                              ),
                              keyboardType: TextInputType.number,
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Please enter the price per liter';
                                }
                                if (double.tryParse(value) == null) {
                                  return 'Please enter a valid number';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 16),
                            TextFormField(
                              controller: _totalCostController,
                              decoration: InputDecoration(
                                labelText: 'Total Cost',
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                prefixIcon: const Icon(Icons.payments),
                                suffixText: '₹',
                                filled: true,
                                fillColor: Colors.grey[50],
                              ),
                              keyboardType: TextInputType.number,
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Please enter the total cost';
                                }
                                if (double.tryParse(value) == null) {
                                  return 'Please enter a valid number';
                                }
                                return null;
                              },
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Card(
                      elevation: 2,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Additional Notes',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 16),
                            TextFormField(
                              controller: _notesController,
                              decoration: InputDecoration(
                                labelText: 'Notes (optional)',
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                prefixIcon: const Icon(Icons.note),
                                filled: true,
                                fillColor: Colors.grey[50],
                              ),
                              maxLines: 3,
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    ElevatedButton(
                      onPressed: _saveFuelEntry,
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: Text(
                        widget.existingEntry != null ? 'Update Entry' : 'Save Entry',
                        style: const TextStyle(fontSize: 16),
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
} 