import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:location/location.dart';
import 'package:signature/signature.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;
import '../models/dpr.dart';
import '../services/db_service.dart';
import '../services/api_service.dart';

class DPRFormScreen extends StatefulWidget {
  const DPRFormScreen({super.key});

  @override
  State<DPRFormScreen> createState() => _DPRFormScreenState();
}

class _DPRFormScreenState extends State<DPRFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _signatureController = SignatureController(
    penStrokeWidth: 3,
    exportBackgroundColor: Colors.white,
  );

  // Form controllers
  final _householdIdController = TextEditingController();
  final _householdHeadNameController = TextEditingController();
  final _addressController = TextEditingController();
  final _phoneNumberController = TextEditingController();
  final _familySizeController = TextEditingController();
  final _monthlyIncomeController = TextEditingController();
  final _otpController = TextEditingController();

  // Location data
  double _latitude = 0.0;
  double _longitude = 0.0;
  bool _isLocationLoading = false;

  // Form state
  bool _isSubmitting = false;
  bool _isOtpVerified = false;
  String? _signaturePath;

  // OTP verification
  final ApiService _apiService = ApiService();
  bool _isOtpLoading = false;

  @override
  void initState() {
    super.initState();
    _getCurrentLocation();
  }

  @override
  void dispose() {
    _signatureController.dispose();
    _householdIdController.dispose();
    _householdHeadNameController.dispose();
    _addressController.dispose();
    _phoneNumberController.dispose();
    _familySizeController.dispose();
    _monthlyIncomeController.dispose();
    _otpController.dispose();
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

  Future<void> _verifyOTP() async {
    if (_phoneNumberController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter phone number first'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (_otpController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter OTP'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() {
      _isOtpLoading = true;
    });

    try {
      final isValid = await _apiService.verifyOTP(
        _phoneNumberController.text,
        _otpController.text,
      );

      setState(() {
        _isOtpVerified = isValid;
        _isOtpLoading = false;
      });

      if (isValid) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('OTP verified successfully'),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Invalid OTP. Please try again.'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      setState(() {
        _isOtpLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error verifying OTP: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _captureSignature() async {
    final result = await showDialog<Uint8List?>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Digital Signature'),
        content: SizedBox(
          height: 200,
          child: Signature(
            controller: _signatureController,
            backgroundColor: Colors.white,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              _signatureController.clear();
              Navigator.pop(context);
            },
            child: const Text('Clear'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              final signature = await _signatureController.toPngBytes();
              Navigator.pop(context, signature);
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );

    if (result != null) {
      await _saveSignature(result);
    }
  }

  Future<void> _saveSignature(Uint8List signatureBytes) async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      final fileName = 'signature_${DateTime.now().millisecondsSinceEpoch}.png';
      final file = File(path.join(directory.path, fileName));
      
      await file.writeAsBytes(signatureBytes);
      
      setState(() {
        _signaturePath = file.path;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Signature saved successfully'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error saving signature: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (!_isOtpVerified) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please verify OTP before submitting'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (_signaturePath == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please capture signature before submitting'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    try {
      final dpr = DPR(
        householdId: _householdIdController.text,
        householdHeadName: _householdHeadNameController.text,
        address: _addressController.text,
        phoneNumber: _phoneNumberController.text,
        familySize: int.parse(_familySizeController.text),
        monthlyIncome: double.parse(_monthlyIncomeController.text),
        latitude: _latitude,
        longitude: _longitude,
        otpCode: _otpController.text,
        signaturePath: _signaturePath!,
        createdAt: DateTime.now(),
      );

      final dbService = Provider.of<DatabaseService>(context, listen: false);
      final id = await dbService.insertDPR(dpr);

      setState(() {
        _isSubmitting = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('DPR form submitted successfully! ID: $id'),
          backgroundColor: Colors.green,
        ),
      );

      // Clear form
      _formKey.currentState!.reset();
      _signatureController.clear();
      setState(() {
        _signaturePath = null;
        _isOtpVerified = false;
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
        title: const Text('DPR Form'),
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

              // Household Information
              const Text(
                'Household Information',
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

              TextFormField(
                controller: _householdHeadNameController,
                decoration: const InputDecoration(
                  labelText: 'Household Head Name *',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter household head name';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              TextFormField(
                controller: _addressController,
                decoration: const InputDecoration(
                  labelText: 'Address *',
                  border: OutlineInputBorder(),
                ),
                maxLines: 3,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter address';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              TextFormField(
                controller: _phoneNumberController,
                decoration: const InputDecoration(
                  labelText: 'Phone Number *',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.phone,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter phone number';
                  }
                  if (value.length < 10) {
                    return 'Please enter a valid phone number';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _familySizeController,
                      decoration: const InputDecoration(
                        labelText: 'Family Size *',
                        border: OutlineInputBorder(),
                      ),
                      keyboardType: TextInputType.number,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter family size';
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
                      controller: _monthlyIncomeController,
                      decoration: const InputDecoration(
                        labelText: 'Monthly Income (₹) *',
                        border: OutlineInputBorder(),
                      ),
                      keyboardType: TextInputType.number,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter monthly income';
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
              const SizedBox(height: 24),

              // OTP Verification
              const Text(
                'OTP Verification',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),

              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _otpController,
                      decoration: const InputDecoration(
                        labelText: 'OTP *',
                        border: OutlineInputBorder(),
                        hintText: 'Enter 123456 for testing',
                      ),
                      keyboardType: TextInputType.number,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter OTP';
                        }
                        return null;
                      },
                    ),
                  ),
                  const SizedBox(width: 16),
                  ElevatedButton(
                    onPressed: _isOtpLoading ? null : _verifyOTP,
                    child: _isOtpLoading
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Text('Verify'),
                  ),
                ],
              ),
              if (_isOtpVerified) ...[
                const SizedBox(height: 8),
                Row(
                  children: [
                    const Icon(Icons.check_circle, color: Colors.green, size: 16),
                    const SizedBox(width: 8),
                    Text(
                      'OTP verified successfully',
                      style: TextStyle(color: Colors.green[700]),
                    ),
                  ],
                ),
              ],
              const SizedBox(height: 24),

              // Signature
              const Text(
                'Digital Signature',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),

              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    children: [
                      if (_signaturePath != null) ...[
                        Container(
                          height: 100,
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.grey),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: Image.file(
                              File(_signaturePath!),
                              fit: BoxFit.contain,
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),
                      ],
                      ElevatedButton.icon(
                        onPressed: _captureSignature,
                        icon: const Icon(Icons.edit),
                        label: Text(_signaturePath == null ? 'Capture Signature' : 'Re-capture Signature'),
                      ),
                    ],
                  ),
                ),
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
                    : const Text('Submit DPR Form'),
              ),
            ],
          ),
        ),
      ),
    );
  }
} 