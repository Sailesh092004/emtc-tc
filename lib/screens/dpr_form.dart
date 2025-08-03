import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:location/location.dart';
import '../models/dpr.dart';
import '../services/db_service.dart';

class DPRFormScreen extends StatefulWidget {
  final DPR? editingDPR;
  
  const DPRFormScreen({super.key, this.editingDPR});

  @override
  State<DPRFormScreen> createState() => _DPRFormScreenState();
}

class _DPRFormScreenState extends State<DPRFormScreen> {
  final _formKey = GlobalKey<FormState>();

  // Header Form Controllers
  final _nameAndAddressController = TextEditingController();
  final _districtController = TextEditingController();
  final _stateController = TextEditingController();
  final _familySizeController = TextEditingController();
  final _incomeGroupController = TextEditingController();
  final _centreCodeController = TextEditingController();
  final _returnNoController = TextEditingController();
  final _monthAndYearController = TextEditingController();
  final _otpController = TextEditingController();

  // Household Members (up to 8)
  final List<HouseholdMemberForm> _householdMembers = [];

  // Location data
  double _latitude = 0.0;
  double _longitude = 0.0;
  bool _isLocationLoading = false;

  // Form state
  bool _isSubmitting = false;
  bool _isOtpVerified = false;

  // OTP verification
  bool _isOtpLoading = false;

  @override
  void initState() {
    super.initState();
    _getCurrentLocation();
    _monthAndYearController.text = '${DateTime.now().month}/${DateTime.now().year}';
    _addHouseholdMember(); // Add first member by default
    
    // If editing, populate the form with existing data
    if (widget.editingDPR != null) {
      _populateFormWithDPR(widget.editingDPR!);
    }
  }

  @override
  void dispose() {
    _nameAndAddressController.dispose();
    _districtController.dispose();
    _stateController.dispose();
    _familySizeController.dispose();
    _incomeGroupController.dispose();
    _centreCodeController.dispose();
    _returnNoController.dispose();
    _monthAndYearController.dispose();
    _otpController.dispose();
    for (var member in _householdMembers) {
      member.dispose();
    }
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
      // For testing, accept any OTP
      final isValid = _otpController.text.isNotEmpty;

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

  void _addHouseholdMember() {
    if (_householdMembers.length < 8) {
      setState(() {
        _householdMembers.add(HouseholdMemberForm());
      });
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Maximum 8 household members allowed'),
          backgroundColor: Colors.orange,
        ),
      );
    }
  }

  void _removeHouseholdMember(int index) {
    setState(() {
      _householdMembers[index].dispose();
      _householdMembers.removeAt(index);
    });
  }

  void _calculateTotalIncome(HouseholdMemberForm member) {
    final jobIncome = double.tryParse(member.annualIncomeJobController.text) ?? 0.0;
    final otherIncome = double.tryParse(member.annualIncomeOtherController.text) ?? 0.0;
    final total = jobIncome + otherIncome;
    member.totalIncomeController.text = total.toStringAsFixed(2);
  }

  void _populateFormWithDPR(DPR dpr) {
    _nameAndAddressController.text = dpr.nameAndAddress;
    _districtController.text = dpr.district;
    _stateController.text = dpr.state;
    _familySizeController.text = dpr.familySize.toString();
    _incomeGroupController.text = dpr.incomeGroup;
    _centreCodeController.text = dpr.centreCode;
    _returnNoController.text = dpr.returnNo;
    _monthAndYearController.text = dpr.monthAndYear;
    _otpController.text = dpr.otpCode;
    _latitude = dpr.latitude;
    _longitude = dpr.longitude;
    _isOtpVerified = true; // Assume OTP is already verified for existing records
    
    // Clear existing household members and add the ones from DPR
    for (var member in _householdMembers) {
      member.dispose();
    }
    _householdMembers.clear();
    
    for (var member in dpr.householdMembers) {
      final formMember = HouseholdMemberForm();
      formMember.nameController.text = member.name;
      formMember.relationshipController.text = member.relationshipWithHead;
      formMember.genderController.text = member.gender;
      formMember.ageController.text = member.age.toString();
      formMember.educationController.text = member.education;
      formMember.occupationController.text = member.occupation;
      formMember.annualIncomeJobController.text = member.annualIncomeJob.toString();
      formMember.annualIncomeOtherController.text = member.annualIncomeOther.toString();
      formMember.otherIncomeSourceController.text = member.otherIncomeSource;
      formMember.totalIncomeController.text = member.totalIncome.toString();
      _householdMembers.add(formMember);
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

    if (_householdMembers.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please add at least one household member'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    try {
      // Convert form data to HouseholdMember objects
      final members = _householdMembers.map((form) => HouseholdMember(
        name: form.nameController.text,
        relationshipWithHead: form.relationshipController.text,
        gender: form.genderController.text,
        age: int.parse(form.ageController.text),
        education: form.educationController.text,
        occupation: form.occupationController.text,
        annualIncomeJob: double.parse(form.annualIncomeJobController.text),
        annualIncomeOther: double.parse(form.annualIncomeOtherController.text),
        otherIncomeSource: form.otherIncomeSourceController.text,
        totalIncome: double.parse(form.totalIncomeController.text),
      )).toList();

      final dpr = DPR(
        nameAndAddress: _nameAndAddressController.text,
        district: _districtController.text,
        state: _stateController.text,
        familySize: int.parse(_familySizeController.text),
        incomeGroup: _incomeGroupController.text,
        centreCode: _centreCodeController.text,
        returnNo: _returnNoController.text,
        monthAndYear: _monthAndYearController.text,
        householdMembers: members,
        latitude: _latitude,
        longitude: _longitude,
        otpCode: _otpController.text,
        createdAt: DateTime.now(),
      );

      final dbService = Provider.of<DatabaseService>(context, listen: false);
      
      if (widget.editingDPR != null) {
        // Update existing DPR
        final updatedDPR = dpr.copyWith(id: widget.editingDPR!.id);
        await dbService.updateDPR(updatedDPR);
        
        setState(() {
          _isSubmitting = false;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('DPR updated successfully!'),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        // Create new DPR
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
      }

      // Clear form
      _formKey.currentState!.reset();
      setState(() {
        _isOtpVerified = false;
        _householdMembers.clear();
        _addHouseholdMember();
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

  Widget _buildLocationCard() {
    return Card(
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
    );
  }

  Widget _buildHeaderSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Header Information',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 16),
        
        TextFormField(
          controller: _nameAndAddressController,
          decoration: const InputDecoration(
            labelText: 'Name & Address *',
            border: OutlineInputBorder(),
          ),
          maxLines: 3,
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Please enter name and address';
            }
            return null;
          },
        ),
        const SizedBox(height: 16),

        Row(
          children: [
            Expanded(
              child: TextFormField(
                controller: _districtController,
                decoration: const InputDecoration(
                  labelText: 'District *',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter district';
                  }
                  return null;
                },
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: TextFormField(
                controller: _stateController,
                decoration: const InputDecoration(
                  labelText: 'State *',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter state';
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
                controller: _incomeGroupController,
                decoration: const InputDecoration(
                  labelText: 'Income Group *',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter income group';
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
                controller: _centreCodeController,
                decoration: const InputDecoration(
                  labelText: 'Centre Code *',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter centre code';
                  }
                  return null;
                },
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: TextFormField(
                controller: _returnNoController,
                decoration: const InputDecoration(
                  labelText: 'Return No. *',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter return number';
                  }
                  return null;
                },
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),

        TextFormField(
          controller: _monthAndYearController,
          decoration: const InputDecoration(
            labelText: 'Month & Year *',
            border: OutlineInputBorder(),
            hintText: 'MM/YYYY',
          ),
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Please enter month and year';
            }
            return null;
          },
        ),
      ],
    );
  }

  Widget _buildHouseholdMembersSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Household Members (Max 8)',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            ElevatedButton.icon(
              onPressed: _addHouseholdMember,
              icon: const Icon(Icons.add),
              label: const Text('Add Member'),
            ),
          ],
        ),
        const SizedBox(height: 16),

        if (_householdMembers.isEmpty)
          const Card(
            child: Padding(
              padding: EdgeInsets.all(16.0),
              child: Text(
                'No household members added yet. Click "Add Member" to start.',
                style: TextStyle(fontStyle: FontStyle.italic),
              ),
            ),
          )
        else
          ..._householdMembers.asMap().entries.map((entry) {
            final index = entry.key;
            final member = entry.value;
            return Card(
              margin: const EdgeInsets.only(bottom: 16),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Member ${index + 1}',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        if (_householdMembers.length > 1)
                          IconButton(
                            onPressed: () => _removeHouseholdMember(index),
                            icon: const Icon(Icons.delete, color: Colors.red),
                            tooltip: 'Remove Member',
                          ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: member.nameController,
                            decoration: const InputDecoration(
                              labelText: 'Name *',
                              border: OutlineInputBorder(),
                            ),
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Please enter name';
                              }
                              return null;
                            },
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: TextFormField(
                            controller: member.relationshipController,
                            decoration: const InputDecoration(
                              labelText: 'Relationship with Head *',
                              border: OutlineInputBorder(),
                            ),
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Please enter relationship';
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
                            controller: member.genderController,
                            decoration: const InputDecoration(
                              labelText: 'Gender (M/F/Other) *',
                              border: OutlineInputBorder(),
                            ),
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Please enter gender';
                              }
                              return null;
                            },
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: TextFormField(
                            controller: member.ageController,
                            decoration: const InputDecoration(
                              labelText: 'Age *',
                              border: OutlineInputBorder(),
                            ),
                            keyboardType: TextInputType.number,
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Please enter age';
                              }
                              if (int.tryParse(value) == null) {
                                return 'Please enter a valid age';
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
                            controller: member.educationController,
                            decoration: const InputDecoration(
                              labelText: 'Education *',
                              border: OutlineInputBorder(),
                            ),
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Please enter education';
                              }
                              return null;
                            },
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: TextFormField(
                            controller: member.occupationController,
                            decoration: const InputDecoration(
                              labelText: 'Occupation *',
                              border: OutlineInputBorder(),
                            ),
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Please enter occupation';
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
                            controller: member.annualIncomeJobController,
                            decoration: const InputDecoration(
                              labelText: 'Annual Income (Job) *',
                              border: OutlineInputBorder(),
                            ),
                            keyboardType: TextInputType.number,
                            onChanged: (_) => _calculateTotalIncome(member),
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Please enter job income';
                              }
                              if (double.tryParse(value) == null) {
                                return 'Please enter a valid amount';
                              }
                              return null;
                            },
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: TextFormField(
                            controller: member.annualIncomeOtherController,
                            decoration: const InputDecoration(
                              labelText: 'Annual Income (Other) *',
                              border: OutlineInputBorder(),
                            ),
                            keyboardType: TextInputType.number,
                            onChanged: (_) => _calculateTotalIncome(member),
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Please enter other income';
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
                      controller: member.otherIncomeSourceController,
                      decoration: const InputDecoration(
                        labelText: 'Other Income Source Name *',
                        border: OutlineInputBorder(),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter other income source';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),

                    TextFormField(
                      controller: member.totalIncomeController,
                      decoration: const InputDecoration(
                        labelText: 'Total Income (Auto-calculated) *',
                        border: OutlineInputBorder(),
                      ),
                      readOnly: true,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Total income is required';
                        }
                        return null;
                      },
                    ),
                  ],
                ),
              ),
            );
          }).toList(),
      ],
    );
  }

  Widget _buildOTPSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
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
                  hintText: 'Enter any OTP for testing',
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
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.editingDPR != null ? 'Edit DPR' : 'DPR Form'),
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
         child: Scrollbar(
           thumbVisibility: true,
           trackVisibility: true,
           child: SingleChildScrollView(
             padding: const EdgeInsets.all(16.0),
             physics: const BouncingScrollPhysics(),
             child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Location Status
              _buildLocationCard(),
              const SizedBox(height: 24),

              // Header Information
              _buildHeaderSection(),
              const SizedBox(height: 32),

              // Household Members
              _buildHouseholdMembersSection(),
              const SizedBox(height: 32),

              // OTP Verification
              _buildOTPSection(),
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
                                         : Text(widget.editingDPR != null ? 'Save Changes' : 'Submit DPR Form'),
              ),
                             const SizedBox(height: 32), // Extra padding at bottom
             ],
           ),
         ),
       ),
     ),
    );
  }
}

class HouseholdMemberForm {
  final TextEditingController nameController = TextEditingController();
  final TextEditingController relationshipController = TextEditingController();
  final TextEditingController genderController = TextEditingController();
  final TextEditingController ageController = TextEditingController();
  final TextEditingController educationController = TextEditingController();
  final TextEditingController occupationController = TextEditingController();
  final TextEditingController annualIncomeJobController = TextEditingController();
  final TextEditingController annualIncomeOtherController = TextEditingController();
  final TextEditingController otherIncomeSourceController = TextEditingController();
  final TextEditingController totalIncomeController = TextEditingController();

  void dispose() {
    nameController.dispose();
    relationshipController.dispose();
    genderController.dispose();
    ageController.dispose();
    educationController.dispose();
    occupationController.dispose();
    annualIncomeJobController.dispose();
    annualIncomeOtherController.dispose();
    otherIncomeSourceController.dispose();
    totalIncomeController.dispose();
  }
} 