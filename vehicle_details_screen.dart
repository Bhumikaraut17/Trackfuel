import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:trackfuel/providers/vehicle_provider.dart';
import 'package:trackfuel/models/vehicle.dart';
import 'package:trackfuel/models/fuel_entry.dart';
import 'package:trackfuel/screens/add_fuel_entry_screen.dart';
import 'package:intl/intl.dart';

class VehicleDetailsScreen extends StatefulWidget {
  final Vehicle vehicle;

  const VehicleDetailsScreen({
    super.key,
    required this.vehicle,
  });

  @override
  State<VehicleDetailsScreen> createState() => _VehicleDetailsScreenState();
}

class _VehicleDetailsScreenState extends State<VehicleDetailsScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.vehicle.name),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Vehicle Information Card
            Card(
              elevation: 4,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Vehicle Information',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    _buildInfoRow('Make', widget.vehicle.make),
                    _buildInfoRow('Model', widget.vehicle.model),
                    _buildInfoRow('Year', widget.vehicle.year.toString()),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            
            // Fuel Entries Card
            Card(
              elevation: 4,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Fuel Entries',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    if (widget.vehicle.fuelEntries.isEmpty)
                      const Center(
                        child: Padding(
                          padding: EdgeInsets.all(16.0),
                          child: Text('No fuel entries available'),
                        ),
                      )
                    else
                      ListView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: widget.vehicle.fuelEntries.length,
                        itemBuilder: (context, index) {
                          final entry = widget.vehicle.fuelEntries[index];
                          return _buildFuelEntryCard(context, entry);
                        },
                      ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 16,
              color: Colors.grey,
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFuelEntryCard(BuildContext context, FuelEntry entry) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8.0),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  DateFormat('MMM dd, yyyy').format(entry.date),
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.edit),
                      onPressed: () => _editFuelEntry(context, entry),
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete),
                      onPressed: () => _deleteFuelEntry(context, entry),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 8),
            _buildEntryRow('Odometer', '${entry.odometer.toStringAsFixed(1)} km'),
            _buildEntryRow('Amount', '${entry.amount.toStringAsFixed(2)} L'),
            _buildEntryRow('Price', '₹${entry.price.toStringAsFixed(2)}'),
            _buildEntryRow('Total Cost', '₹${entry.totalCost.toStringAsFixed(2)}'),
          ],
        ),
      ),
    );
  }

  void _editFuelEntry(BuildContext context, FuelEntry entry) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AddFuelEntryScreen(
          vehicle: widget.vehicle,
          vehicleProvider: Provider.of<VehicleProvider>(context, listen: false),
          existingEntry: entry,
        ),
      ),
    );
  }

  Future<void> _deleteFuelEntry(BuildContext context, FuelEntry entry) async {
    if (entry.id == null || entry.id!.isEmpty) {
      debugPrint('Cannot delete fuel entry: invalid ID');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Cannot delete fuel entry: invalid ID')),
        );
      }
      return;
    }

    // Store the provider before awaiting to avoid context usage after async gap
    final vehicleProvider = Provider.of<VehicleProvider>(context, listen: false);
    
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Entry'),
        content: const Text('Are you sure you want to delete this fuel entry?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    // Check if widget is still mounted after the async gap
    if (!mounted) return;

    if (confirmed == true) {
      try {
        await vehicleProvider.deleteFuelEntry(entry.id!);
        
        // Check if widget is still mounted before using context
        if (!mounted) return;
        
        // Use a local function to safely use the context
        void showSuccessMessage() {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Fuel entry deleted successfully')),
          );
        }
        showSuccessMessage();
      } catch (e) {
        debugPrint('Error deleting fuel entry: $e');
        
        // Check if widget is still mounted before using context
        if (!mounted) return;
        
        // Use a local function to safely use the context
        void showErrorMessage() {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error deleting fuel entry: ${e.toString()}')),
          );
        }
        showErrorMessage();
      }
    }
  }

  Widget _buildEntryRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 14,
              color: Colors.grey,
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
} 