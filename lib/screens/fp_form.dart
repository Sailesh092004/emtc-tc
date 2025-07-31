import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:location/location.dart';
import '../models/fp.dart';
import '../services/db_service.dart';

class FPFormScreen extends StatefulWidget {
  const FPFormScreen({super.key});

  @override
  State<FPFormScreen> createState() => _FPFormScreenState();
}

class _FPFormScreenState extends State<FPFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _centreNameController = TextEditingController();
  final _centreCodeController = TextEditingController();
  final _panelSizeController = TextEditingController();
  final _mprCollectedController = TextEditingController();
  final _notCollectedController = TextEditingController();
  final _withPurchaseDataController = TextEditingController();
  final _nilMPRsController = TextEditingController();
  final _nilSerialNosController = TextEditingController();

  LocationData? _locationData;
  bool _isLoading = false;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _getCurrentLocation();
  }

  @override
  void dispose() {
    _centreNameController.dispose();
    _centreCodeController.dispose();
    _panelSizeController.dispose();
    _mprCollectedController.dispose();
    _notCollectedController.dispose();
    _withPurchaseDataController.dispose();
    _nilMPRsController.dispose();
    _nilSerialNosController.dispose();
    super.dispose();
  }

  Future<void> _getCurrentLocation() async {
    setState(() {
      _isLoading = true;
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
      _locationData = await location.getLocation();
      setState(() {
        _isLoading = false;
      });
    } catch (e) {
      print('Error getting location: $e');
      _showLocationError('Failed to get location: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _showLocationError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
      ),
    );
  }

  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (_locationData == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please wait for location to be captured'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    try {
      final fp = FP(
        centreName: _centreNameController.text.trim(),
        centreCode: _centreCodeController.text.trim(),
        panelSize: int.parse(_panelSizeController.text),
        mprCollected: int.parse(_mprCollectedController.text),
        notCollected: int.parse(_notCollectedController.text),
        withPurchaseData: int.parse(_withPurchaseDataController.text),
        nilMPRs: int.parse(_nilMPRsController.text),
        nilSerialNos: int.parse(_nilSerialNosController.text),
        latitude: _locationData!.latitude!,
        longitude: _locationData!.longitude!,
        createdAt: DateTime.now(),
      );

      final dbService = Provider.of<DatabaseService>(context, listen: false);
      await dbService.insertFP(fp);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('FP form submitted successfully!'),
          backgroundColor: Colors.green,
        ),
      );

      Navigator.pop(context);
    } catch (e) {
      print('Error submitting FP form: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error submitting form: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() {
        _isSubmitting = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Forwarding Performa (FP)'),
        backgroundColor: Colors.purple,
        foregroundColor: Colors.white,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Form(
              key: _formKey,
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Location Status Card
                    Card(
                      color: _locationData != null ? Colors.green.shade50 : Colors.orange.shade50,
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Row(
                          children: [
                            Icon(
                              _locationData != null ? Icons.location_on : Icons.location_off,
                              color: _locationData != null ? Colors.green : Colors.orange,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    _locationData != null ? 'Location Captured' : 'Capturing Location...',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  if (_locationData != null) ...[
                                    const SizedBox(height: 4),
                                    Text(
                                      'Lat: ${_locationData!.latitude!.toStringAsFixed(6)}\nLng: ${_locationData!.longitude!.toStringAsFixed(6)}',
                                      style: const TextStyle(fontSize: 12),
                                    ),
                                  ],
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Centre Information
                    const Text(
                      'Centre Information',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.purple,
                      ),
                    ),
                    const SizedBox(height: 16),

                    TextFormField(
                      controller: _centreNameController,
                      decoration: const InputDecoration(
                        labelText: 'Centre Name *',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.business),
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Please enter centre name';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),

                    TextFormField(
                      controller: _centreCodeController,
                      decoration: const InputDecoration(
                        labelText: 'Centre Code *',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.code),
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Please enter centre code';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),

                    TextFormField(
                      controller: _panelSizeController,
                      decoration: const InputDecoration(
                        labelText: 'Panel Size *',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.people),
                      ),
                      keyboardType: TextInputType.number,
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Please enter panel size';
                        }
                        if (int.tryParse(value) == null) {
                          return 'Please enter a valid number';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 24),

                    // MPR Collection Data
                    const Text(
                      'MPR Collection Data',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.purple,
                      ),
                    ),
                    const SizedBox(height: 16),

                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: _mprCollectedController,
                            decoration: const InputDecoration(
                              labelText: 'MPR Collected *',
                              border: OutlineInputBorder(),
                              prefixIcon: Icon(Icons.check_circle),
                            ),
                            keyboardType: TextInputType.number,
                            validator: (value) {
                              if (value == null || value.trim().isEmpty) {
                                return 'Required';
                              }
                              if (int.tryParse(value) == null) {
                                return 'Invalid';
                              }
                              return null;
                            },
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: TextFormField(
                            controller: _notCollectedController,
                            decoration: const InputDecoration(
                              labelText: 'Not Collected *',
                              border: OutlineInputBorder(),
                              prefixIcon: Icon(Icons.cancel),
                            ),
                            keyboardType: TextInputType.number,
                            validator: (value) {
                              if (value == null || value.trim().isEmpty) {
                                return 'Required';
                              }
                              if (int.tryParse(value) == null) {
                                return 'Invalid';
                              }
                              return null;
                            },
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: _withPurchaseDataController,
                            decoration: const InputDecoration(
                              labelText: 'With Purchase Data *',
                              border: OutlineInputBorder(),
                              prefixIcon: Icon(Icons.shopping_cart),
                            ),
                            keyboardType: TextInputType.number,
                            validator: (value) {
                              if (value == null || value.trim().isEmpty) {
                                return 'Required';
                              }
                              if (int.tryParse(value) == null) {
                                return 'Invalid';
                              }
                              return null;
                            },
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: TextFormField(
                            controller: _nilMPRsController,
                            decoration: const InputDecoration(
                              labelText: 'Nil MPRs *',
                              border: OutlineInputBorder(),
                              prefixIcon: Icon(Icons.block),
                            ),
                            keyboardType: TextInputType.number,
                            validator: (value) {
                              if (value == null || value.trim().isEmpty) {
                                return 'Required';
                              }
                              if (int.tryParse(value) == null) {
                                return 'Invalid';
                              }
                              return null;
                            },
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    TextFormField(
                      controller: _nilSerialNosController,
                      decoration: const InputDecoration(
                        labelText: 'Nil Serial Nos *',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.format_list_numbered),
                      ),
                      keyboardType: TextInputType.number,
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Please enter nil serial numbers';
                        }
                        if (int.tryParse(value) == null) {
                          return 'Please enter a valid number';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 32),

                    // Submit Button
                    ElevatedButton(
                      onPressed: _isSubmitting ? null : _submitForm,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.purple,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: _isSubmitting
                          ? const Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                  ),
                                ),
                                SizedBox(width: 12),
                                Text('Submitting...'),
                              ],
                            )
                          : const Text(
                              'Submit FP Form',
                              style: TextStyle(fontSize: 16),
                            ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
} 