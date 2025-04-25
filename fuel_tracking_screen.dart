import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import 'package:trackfuel/services/auth_service.dart';
import 'package:intl/intl.dart';

class FuelTrackingScreen extends StatefulWidget {
  const FuelTrackingScreen({super.key});

  @override
  State<FuelTrackingScreen> createState() => _FuelTrackingScreenState();
}

class _FuelTrackingScreenState extends State<FuelTrackingScreen> {
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  final _priceController = TextEditingController();
  final _odometerController = TextEditingController();
  DateTime _selectedDate = DateTime.now();
  String? _selectedVehicle;

  @override
  void dispose() {
    _amountController.dispose();
    _priceController.dispose();
    _odometerController.dispose();
    super.dispose();
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
    );
    if (picked != null && picked != _selectedDate && mounted) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  Future<void> _submitForm() async {
    if (_formKey.currentState!.validate() && _selectedVehicle != null) {
      try {
        final user = Provider.of<AuthService>(context, listen: false).user;
        await FirebaseFirestore.instance.collection('fuel_entries').add({
          'userId': user!.uid,
          'vehicleId': _selectedVehicle,
          'amount': double.parse(_amountController.text),
          'price': double.parse(_priceController.text),
          'odometer': double.parse(_odometerController.text),
          'date': _selectedDate,
          'totalCost': double.parse(_amountController.text) *
              double.parse(_priceController.text),
        });

        // Clear form only if still mounted
        if (!mounted) return;
        
        _amountController.clear();
        _priceController.clear();
        _odometerController.clear();
        setState(() {
          _selectedDate = DateTime.now();
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Fuel entry added successfully')),
        );
      } catch (e) {
        if (!mounted) return;
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: ${e.toString()}')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Text(
                      'Add Fuel Entry',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    StreamBuilder<QuerySnapshot>(
                      stream: FirebaseFirestore.instance
                          .collection('vehicles')
                          .where('userId',
                              isEqualTo: Provider.of<AuthService>(context)
                                  .user
                                  ?.uid)
                          .snapshots(),
                      builder: (context, snapshot) {
                        if (!snapshot.hasData) {
                          return const CircularProgressIndicator();
                        }
                        final vehicles = snapshot.data!.docs;
                        return DropdownButtonFormField<String>(
                          value: _selectedVehicle,
                          decoration: const InputDecoration(
                            labelText: 'Select Vehicle',
                            border: OutlineInputBorder(),
                          ),
                          items: vehicles.map((vehicle) {
                            return DropdownMenuItem<String>(
                              value: vehicle.id,
                              child: Text(vehicle['name']),
                            );
                          }).toList(),
                          onChanged: (value) {
                            setState(() {
                              _selectedVehicle = value;
                            });
                          },
                          validator: (value) {
                            if (value == null) {
                              return 'Please select a vehicle';
                            }
                            return null;
                          },
                        );
                      },
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _amountController,
                      decoration: const InputDecoration(
                        labelText: 'Amount (Liters)',
                        border: OutlineInputBorder(),
                      ),
                      keyboardType: TextInputType.number,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter the amount';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _priceController,
                      decoration: const InputDecoration(
                        labelText: 'Price per Liter',
                        border: OutlineInputBorder(),
                      ),
                      keyboardType: TextInputType.number,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter the price';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _odometerController,
                      decoration: const InputDecoration(
                        labelText: 'Odometer Reading',
                        border: OutlineInputBorder(),
                      ),
                      keyboardType: TextInputType.number,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter the odometer reading';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    ListTile(
                      title: const Text('Date'),
                      subtitle: Text(
                        DateFormat('yyyy-MM-dd').format(_selectedDate),
                      ),
                      trailing: IconButton(
                        icon: const Icon(Icons.calendar_today),
                        onPressed: () => _selectDate(context),
                      ),
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: _submitForm,
                      child: const Text('Add Entry'),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('fuel_entries')
                  .where('userId',
                      isEqualTo: Provider.of<AuthService>(context).user?.uid)
                  .orderBy('date', descending: true)
                  .snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }

                final entries = snapshot.data!.docs;

                return ListView.builder(
                  itemCount: entries.length,
                  itemBuilder: (context, index) {
                    final entry = entries[index];
                    return Card(
                      child: ListTile(
                        title: Text(
                          '${entry['amount']}L @ ${entry['price']} per L',
                        ),
                        subtitle: Text(
                          'Odometer: ${entry['odometer']}km\n'
                          'Total: \$${entry['totalCost'].toStringAsFixed(2)}\n'
                          'Date: ${DateFormat('yyyy-MM-dd').format(entry['date'].toDate())}',
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
} 