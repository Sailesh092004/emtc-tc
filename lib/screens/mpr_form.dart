import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:location/location.dart';
import '../models/mpr.dart';
import '../services/db_service.dart';

class MPRFormScreen extends StatefulWidget {
  const MPRFormScreen({super.key});

  @override
  State<MPRFormScreen> createState() => _MPRFormScreenState();
}

class _MPRFormScreenState extends State<MPRFormScreen> {
  final _formKey = GlobalKey<FormState>();

  // Form controllers
  final _householdIdController = TextEditingController();
  final _purchaseDateController = TextEditingController();
  final _textileTypeController = TextEditingController();
  final _quantityController = TextEditingController();
  final _priceController = TextEditingController();
  final _purchaseLocationController = TextEditingController();

  // Location data
  double _latitude = 0.0;
  double _longitude = 0.0;
  bool _isLocationLoading = false;

  // Form state
  bool _isSubmitting = false;
  DateTime? _selectedDate;

  @override
  void initState() {
    super.initState();
    _getCurrentLocation();
    _purchaseDateController.text = DateTime.now().toString().split(' ')[0]; // Set today's date
  }

  @override
  void dispose() {
    _householdIdController.dispose();
    _purchaseDateController.dispose();
    _textileTypeController.dispose();
    _quantityController.dispose();
    _priceController.dispose();
    _purchaseLocationController.dispose();
    super.dispose();
  }

  Future<void> _getCurrentLocation() async {
    setState(() {
      _isLocationLoading = true;
    });

    try {
      Location location = Location();
      
      // Check if location service is enabled
      bool serviceEnabled = await location.serviceEnabled();
      if (!serviceEnabled) {
        serviceEnabled = await location.requestService();
        if (!serviceEnabled) {
          _showLocationError('Location service is disabled');
          return;
        }
      }

      // Check location permission
      PermissionStatus permissionGranted = await location.hasPermission();
      if (permissionGranted == PermissionStatus.denied) {
        permissionGranted = await location.requestPermission();
        if (permissionGranted != PermissionStatus.granted) {
          _showLocationError('Location permission denied');
          return;
        }
      }

      // Get current location
      LocationData currentLocation = await location.getLocation();
      
      setState(() {
        _latitude = currentLocation.latitude ?? 0.0;
        _longitude = currentLocation.longitude ?? 0.0;
        _isLocationLoading = false;
      });

      print('Location captured: $_latitude, $_longitude');
    } catch (e) {
      print('Error getting location: $e');
      _showLocationError('Failed to get location: $e');
    }
  }

  void _showLocationError(String message) {
    setState(() {
      _isLocationLoading = false;
    });
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
      ),
    );
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
        _purchaseDateController.text = picked.toString().split(' ')[0];
      });
    }
  }

  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    try {
      final mpr = MPR(
        householdId: _householdIdController.text,
        purchaseDate: _selectedDate ?? DateTime.now(),
        textileType: _textileTypeController.text,
        quantity: int.parse(_quantityController.text),
        price: double.parse(_priceController.text),
        purchaseLocation: _purchaseLocationController.text,
        latitude: _latitude,
        longitude: _longitude,
        createdAt: DateTime.now(),
      );

      final dbService = Provider.of<DatabaseService>(context, listen: false);
      final id = await dbService.insertMPR(mpr);

      setState(() {
        _isSubmitting = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('MPR form submitted successfully! ID: $id'),
          backgroundColor: Colors.green,
        ),
      );

      // Clear form
      _formKey.currentState!.reset();
      setState(() {
        _selectedDate = null;
        _purchaseDateController.text = DateTime.now().toString().split(' ')[0];
      });

      // Navigate back
      Navigator.pop(context);
    } catch (e) {
      setState(() {
        _isSubmitting = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error submitting form: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('MPR Form'),
        actions: [
          IconButton(
            icon: const Icon(Icons.location_on),
            onPressed: _getCurrentLocation,
            tooltip: 'Refresh Location',
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Location Status
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            _isLocationLoading ? Icons.location_searching : Icons.location_on,
                            color: _isLocationLoading ? Colors.orange : Colors.green,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            _isLocationLoading ? 'Getting Location...' : 'Location Captured',
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                      if (!_isLocationLoading) ...[
                        const SizedBox(height: 8),
                        Text('Latitude: ${_latitude.toStringAsFixed(6)}'),
                        Text('Longitude: ${_longitude.toStringAsFixed(6)}'),
                      ],
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Purchase Information
              const Text(
                'Purchase Information',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),

              TextFormField(
                controller: _householdIdController,
                decoration: const InputDecoration(
                  labelText: 'Household ID *',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter household ID';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Date Picker
              GestureDetector(
                onTap: () => _selectDate(context),
                child: AbsorbPointer(
                  child: TextFormField(
                    controller: _purchaseDateController,
                    decoration: const InputDecoration(
                      labelText: 'Purchase Date *',
                      border: OutlineInputBorder(),
                      suffixIcon: Icon(Icons.calendar_today),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please select purchase date';
                      }
                      return null;
                    },
                  ),
                ),
              ),
              const SizedBox(height: 16),

              TextFormField(
                controller: _textileTypeController,
                decoration: const InputDecoration(
                  labelText: 'Type of Textiles Purchased *',
                  border: OutlineInputBorder(),
                  hintText: 'e.g., Cotton, Silk, Wool, Synthetic',
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter textile type';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _quantityController,
                      decoration: const InputDecoration(
                        labelText: 'Quantity *',
                        border: OutlineInputBorder(),
                        hintText: 'Number of items',
                      ),
                      keyboardType: TextInputType.number,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter quantity';
                        }
                        if (int.tryParse(value) == null) {
                          return 'Please enter a valid number';
                        }
                        return null;
                      },
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: TextFormField(
                      controller: _priceController,
                      decoration: const InputDecoration(
                        labelText: 'Price (₹) *',
                        border: OutlineInputBorder(),
                        hintText: 'Total amount',
                      ),
                      keyboardType: TextInputType.number,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter price';
                        }
                        if (double.tryParse(value) == null) {
                          return 'Please enter a valid amount';
                        }
                        return null;
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              TextFormField(
                controller: _purchaseLocationController,
                decoration: const InputDecoration(
                  labelText: 'Purchase Location *',
                  border: OutlineInputBorder(),
                  hintText: 'e.g., Local Market, Shopping Mall, Online',
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter purchase location';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 32),

              // Submit Button
              ElevatedButton(
                onPressed: _isSubmitting ? null : _submitForm,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.all(16),
                ),
                child: _isSubmitting
                    ? const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          ),
                          SizedBox(width: 16),
                          Text('Submitting...'),
                        ],
                      )
                    : const Text('Submit MPR Form'),
              ),
            ],
          ),
        ),
      ),
    );
  }
} 