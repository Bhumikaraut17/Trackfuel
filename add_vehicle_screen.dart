import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:trackfuel/models/vehicle.dart';
import 'package:trackfuel/providers/vehicle_provider.dart';
import 'package:firebase_auth/firebase_auth.dart';

class AddVehicleScreen extends StatefulWidget {
  final Vehicle? vehicle;

  const AddVehicleScreen({super.key, this.vehicle});

  @override
  State<AddVehicleScreen> createState() => AddVehicleScreenState();
}

class AddVehicleScreenState extends State<AddVehicleScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _makeController;
  late TextEditingController _modelController;
  late TextEditingController _yearController;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.vehicle?.name ?? '');
    _makeController = TextEditingController(text: widget.vehicle?.make ?? '');
    _modelController = TextEditingController(text: widget.vehicle?.model ?? '');
    _yearController = TextEditingController(
        text: widget.vehicle?.year.toString() ?? '');
  }

  @override
  void dispose() {
    _nameController.dispose();
    _makeController.dispose();
    _modelController.dispose();
    _yearController.dispose();
    super.dispose();
  }

  Future<void> _saveVehicle() async {
    if (_formKey.currentState?.validate() ?? false) {
      setState(() {
        _isLoading = true;
      });

      try {
        final vehicleProvider = Provider.of<VehicleProvider>(context, listen: false);
        final currentUser = FirebaseAuth.instance.currentUser;
        if (currentUser == null) {
          throw Exception('User not logged in');
        }

        final vehicle = Vehicle(
          id: widget.vehicle?.id,
          name: _nameController.text.trim(),
          make: _makeController.text.trim(),
          model: _modelController.text.trim(),
          year: int.parse(_yearController.text),
          userId: currentUser.uid,
        );

        if (widget.vehicle?.id != null) {
          await vehicleProvider.updateVehicle(vehicle);
        } else {
          await vehicleProvider.addVehicle(vehicle);
        }

        if (mounted) {
          Navigator.pop(context);
        }
      } catch (e) {
        debugPrint('Error saving vehicle: $e');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error: ${e.toString()}'),
              backgroundColor: Colors.red,
            ),
          );
        }
      } finally {
        if (mounted) {
          setState(() {
            _isLoading = false;
          });
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.vehicle == null ? 'Add Vehicle' : 'Edit Vehicle'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(labelText: 'Vehicle Name'),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter a name';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _makeController,
                decoration: const InputDecoration(labelText: 'Make'),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter the make';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _modelController,
                decoration: const InputDecoration(labelText: 'Model'),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter the model';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _yearController,
                decoration: const InputDecoration(labelText: 'Year'),
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter the year';
                  }
                  final year = int.tryParse(value);
                  if (year == null || year < 1900 || year > DateTime.now().year) {
                    return 'Please enter a valid year';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 24),
              if (_isLoading)
                const Center(child: CircularProgressIndicator())
              else
                ElevatedButton(
                  onPressed: _saveVehicle,
                  child: Text(widget.vehicle == null ? 'Add Vehicle' : 'Save Changes'),
                ),
            ],
          ),
        ),
      ),
    );
  }
} 