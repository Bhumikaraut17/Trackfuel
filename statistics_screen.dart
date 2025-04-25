import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:provider/provider.dart';
import 'package:trackfuel/providers/vehicle_provider.dart';
import 'package:trackfuel/providers/fuel_price_provider.dart';
import 'package:trackfuel/models/fuel_entry.dart';
import 'package:intl/intl.dart';

class StatisticsScreen extends StatefulWidget {
  const StatisticsScreen({super.key});

  @override
  State<StatisticsScreen> createState() => _StatisticsScreenState();
}

class _StatisticsScreenState extends State<StatisticsScreen> {
  String _selectedVehicleId = '';
  int _selectedYear = DateTime.now().year;
  List<int> _availableYears = [];

  @override
  void initState() {
    super.initState();
    _loadAvailableYears();
    // Fetch fuel prices when the screen loads
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final fuelPriceProvider = Provider.of<FuelPriceProvider>(context, listen: false);
      fuelPriceProvider.fetchFuelPrices('Mumbai');
    });
  }

  void _loadAvailableYears() {
    final now = DateTime.now();
    _availableYears = List.generate(5, (index) => now.year - index);
  }

  Map<String, List<FuelEntry>> _groupEntriesByMonth(List<FuelEntry> entries) {
    final Map<String, List<FuelEntry>> monthlyEntries = {};
    
    for (var entry in entries) {
      final monthKey = DateFormat('MMM yyyy').format(entry.date);
      if (!monthlyEntries.containsKey(monthKey)) {
        monthlyEntries[monthKey] = [];
      }
      monthlyEntries[monthKey]!.add(entry);
    }
    
    return monthlyEntries;
  }

  List<BarChartGroupData> _getMonthlyExpenseData(List<FuelEntry> entries) {
    final monthlyEntries = _groupEntriesByMonth(entries);
    final List<BarChartGroupData> barGroups = [];
    
    monthlyEntries.forEach((month, entries) {
      final totalExpense = entries.fold<double>(0, (sum, entry) => sum + entry.totalCost);
      barGroups.add(
        BarChartGroupData(
          x: barGroups.length,
          barRods: [
            BarChartRodData(
              toY: totalExpense,
              color: Colors.blue,
              width: 20,
              borderRadius: BorderRadius.circular(4),
            ),
          ],
        ),
      );
    });
    
    return barGroups;
  }

  Widget _buildStatisticsCard(List<FuelEntry> entries) {
    if (entries.isEmpty) {
      return const Card(
        child: Padding(
          padding: EdgeInsets.all(16.0),
          child: Center(
            child: Text('No fuel entries available for the selected year'),
          ),
        ),
      );
    }

    final totalLiters = entries.fold<double>(0, (sum, entry) => sum + entry.amount);
    final totalCost = entries.fold<double>(0, (sum, entry) => sum + entry.totalCost);
    final averagePricePerLiter = totalCost / totalLiters;
    final averageLitersPerMonth = totalLiters / 12;

    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Yearly Statistics',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            _buildStatRow('Total Liters', '${totalLiters.toStringAsFixed(2)} L'),
            _buildStatRow('Total Cost', '₹${totalCost.toStringAsFixed(2)}'),
            _buildStatRow('Average Price/Liter', '₹${averagePricePerLiter.toStringAsFixed(2)}'),
            _buildStatRow('Average Liters/Month', '${averageLitersPerMonth.toStringAsFixed(2)} L'),
          ],
        ),
      ),
    );
  }

  Widget _buildStatRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(fontSize: 16),
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

  @override
  Widget build(BuildContext context) {
    final vehicleProvider = Provider.of<VehicleProvider>(context);
    final fuelPriceProvider = Provider.of<FuelPriceProvider>(context);
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
    
    if (vehicles.isEmpty) {
      return const Center(
        child: Text('No vehicles available. Add a vehicle to view statistics.'),
      );
    }

    // If vehicle ID is empty, use the first vehicle's ID
    if (_selectedVehicleId.isEmpty) {
      _selectedVehicleId = vehicles.first.id!;
    }

    final selectedVehicle = vehicles.firstWhere((v) => v.id == _selectedVehicleId);
    final fuelEntries = selectedVehicle.fuelEntries
        .where((entry) => entry.date.year == _selectedYear)
        .toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Monthly Statistics'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Vehicle and Year Selection
            Row(
              children: [
                Expanded(
                  child: DropdownButtonFormField<String>(
                    value: _selectedVehicleId,
                    items: vehicles.map((vehicle) {
                      return DropdownMenuItem(
                        value: vehicle.id,
                        child: Text(vehicle.name),
                      );
                    }).toList(),
                    onChanged: (value) {
                      setState(() {
                        _selectedVehicleId = value!;
                      });
                    },
                    decoration: const InputDecoration(
                      labelText: 'Select Vehicle',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: DropdownButtonFormField<int>(
                    value: _selectedYear,
                    items: _availableYears.map((year) {
                      return DropdownMenuItem(
                        value: year,
                        child: Text(year.toString()),
                      );
                    }).toList(),
                    onChanged: (value) {
                      setState(() {
                        _selectedYear = value!;
                      });
                    },
                    decoration: const InputDecoration(
                      labelText: 'Select Year',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            
            // Current Fuel Prices Card
            Card(
              elevation: 4,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Current Fuel Prices',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    if (fuelPriceProvider.isLoading)
                      const Center(
                        child: Column(
                          children: [
                            CircularProgressIndicator(),
                            SizedBox(height: 8),
                            Text('Fetching current fuel prices...'),
                          ],
                        ),
                      )
                    else if (fuelPriceProvider.error != null)
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Error: ${fuelPriceProvider.error}',
                            style: const TextStyle(color: Colors.red),
                          ),
                          const SizedBox(height: 8),
                          ElevatedButton(
                            onPressed: () => fuelPriceProvider.fetchFuelPrices('Mumbai'),
                            child: const Text('Retry'),
                          ),
                        ],
                      )
                    else if (fuelPriceProvider.currentFuelPrices != null)
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildPriceComparison(
                            'Petrol',
                            fuelPriceProvider.currentFuelPrices!['petrol'],
                            fuelEntries,
                            'petrol',
                          ),
                          const SizedBox(height: 8),
                          _buildPriceComparison(
                            'Diesel',
                            fuelPriceProvider.currentFuelPrices!['diesel'],
                            fuelEntries,
                            'diesel',
                          ),
                        ],
                      )
                    else
                      Column(
                        children: [
                          const Text('No fuel price data available'),
                          const SizedBox(height: 8),
                          ElevatedButton(
                            onPressed: () => fuelPriceProvider.fetchFuelPrices('Mumbai'),
                            child: const Text('Get Current Fuel Prices'),
                          ),
                        ],
                      ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            
            // Statistics Card
            _buildStatisticsCard(fuelEntries),
            const SizedBox(height: 16),
            
            // Monthly Expense Graph
            Card(
              elevation: 4,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Monthly Fuel Expenses',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    if (fuelEntries.isEmpty)
                      const Center(
                        child: Text('No fuel entries available for the selected year'),
                      )
                    else
                      SizedBox(
                        height: 300,
                        child: BarChart(
                          BarChartData(
                            alignment: BarChartAlignment.spaceAround,
                            maxY: fuelEntries.isEmpty ? 1000 : 
                              (fuelEntries.map((e) => e.totalCost).reduce((a, b) => a > b ? a : b) * 1.2),
                            barGroups: _getMonthlyExpenseData(fuelEntries),
                            titlesData: FlTitlesData(
                              show: true,
                              bottomTitles: AxisTitles(
                                sideTitles: SideTitles(
                                  showTitles: true,
                                  getTitlesWidget: (value, meta) {
                                    final monthlyEntries = _groupEntriesByMonth(fuelEntries);
                                    if (value.toInt() < monthlyEntries.length) {
                                      return Padding(
                                        padding: const EdgeInsets.only(top: 8.0),
                                        child: Text(
                                          monthlyEntries.keys.elementAt(value.toInt()),
                                          style: const TextStyle(fontSize: 10),
                                        ),
                                      );
                                    }
                                    return const Text('');
                                  },
                                ),
                              ),
                              leftTitles: AxisTitles(
                                sideTitles: SideTitles(
                                  showTitles: true,
                                  getTitlesWidget: (value, meta) {
                                    return Text(
                                      '₹${value.toInt()}',
                                      style: const TextStyle(fontSize: 10),
                                    );
                                  },
                                ),
                              ),
                              rightTitles: const AxisTitles(
                                sideTitles: SideTitles(showTitles: false),
                              ),
                              topTitles: const AxisTitles(
                                sideTitles: SideTitles(showTitles: false),
                              ),
                            ),
                            gridData: const FlGridData(show: false),
                            borderData: FlBorderData(show: false),
                          ),
                        ),
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

  Widget _buildPriceComparison(String fuelType, double currentPrice, List<FuelEntry> entries, String fuelTypeKey) {
    if (entries.isEmpty) {
      return Text(
        '$fuelType: ₹${currentPrice.toStringAsFixed(2)}',
        style: const TextStyle(fontSize: 16),
      );
    }

    final relevantEntries = entries.where((entry) => entry.vehicleId.toLowerCase().contains(fuelTypeKey));
    if (relevantEntries.isEmpty) {
      return Text(
        '$fuelType: ₹${currentPrice.toStringAsFixed(2)}',
        style: const TextStyle(fontSize: 16),
      );
    }

    final relevantEntriesList = relevantEntries.toList();
    final averagePrice = relevantEntriesList.fold<double>(0, (sum, entry) => sum + entry.price) / relevantEntriesList.length;
    final priceDifference = currentPrice - averagePrice;
    final priceChangePercentage = (priceDifference / averagePrice) * 100;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '$fuelType: ₹${currentPrice.toStringAsFixed(2)}',
          style: const TextStyle(fontSize: 16),
        ),
        Text(
          'Average: ₹${averagePrice.toStringAsFixed(2)}',
          style: const TextStyle(fontSize: 14, color: Colors.grey),
        ),
        Text(
          'Change: ${priceChangePercentage.toStringAsFixed(1)}%',
          style: TextStyle(
            fontSize: 14,
            color: priceDifference > 0 ? Colors.red : Colors.green,
          ),
        ),
      ],
    );
  }
} 