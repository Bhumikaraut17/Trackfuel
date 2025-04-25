import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:trackfuel/providers/vehicle_provider.dart';
import 'package:trackfuel/screens/vehicle_details_screen.dart';
import 'package:trackfuel/screens/add_vehicle_screen.dart';

class VehiclesScreen extends StatelessWidget {
  const VehiclesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final vehicleProvider = Provider.of<VehicleProvider>(context);
    final vehicles = vehicleProvider.vehicles;

    if (vehicleProvider.isLoading) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('Loading vehicles...'),
          ],
        ),
      );
    }

    return Scaffold(
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const AddVehicleScreen(),
            ),
          );
        },
        child: const Icon(Icons.add),
      ),
      body: vehicles.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text('No vehicles available.'),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const AddVehicleScreen(),
                        ),
                      );
                    },
                    child: const Text('Add Vehicle'),
                  ),
                ],
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(16.0),
              itemCount: vehicles.length,
              itemBuilder: (context, index) {
                final vehicle = vehicles[index];
                return Card(
                  elevation: 4,
                  margin: const EdgeInsets.only(bottom: 16.0),
                  child: ListTile(
                    title: Text(
                      vehicle.name,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    subtitle: Text('${vehicle.make} ${vehicle.model} (${vehicle.year})'),
                    trailing: Text(
                      '${vehicle.fuelEntries.length} entries',
                      style: const TextStyle(
                        color: Colors.blue,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => VehicleDetailsScreen(vehicle: vehicle),
                        ),
                      );
                    },
                  ),
                );
              },
            ),
    );
  }
} 