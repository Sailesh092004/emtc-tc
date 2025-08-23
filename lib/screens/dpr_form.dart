import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:location/location.dart';
import '../models/dpr.dart';
import '../services/db_service.dart';
import '../services/api_service.dart';
import '../data/codebook.dart';

class DPRFormScreen extends StatefulWidget {
  final DPR? editingDPR;
  
  const DPRFormScreen({super.key, this.editingDPR});

  @override
  State<DPRFormScreen> createState() => _DPRFormScreenState();
}

class _DPRFormScreenState extends State<DPRFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _apiService = ApiService();

  // Header Form Controllers
  final _nameAndAddressController = TextEditingController();
  final _districtController = TextEditingController();
  final _stateController = TextEditingController();
  final _familySizeController = TextEditingController();
  final _incomeGroupController = TextEditingController();
  final _centreCodeController = TextEditingController();
  final _returnNoController = TextEditingController();
  final _monthAndYearController = TextEditingController();
  final _mobileNumberController = TextEditingController();
  final _otpController = TextEditingController();

  // Household Members
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
    
    // Add listener to family size field for auto-creation of members
    _familySizeController.addListener(_onFamilySizeChanged);
    
    // If editing, populate the form with existing data
    if (widget.editingDPR != null) {
      _populateFormWithDPR(widget.editingDPR!);
    } else {
      // Add first member by default for new forms
      _addHouseholdMember();
    }
  }

  @override
  void dispose() {
    _nameAndAddressController.dispose();
    _districtController.dispose();
    _stateController.dispose();
    _familySizeController.removeListener(_onFamilySizeChanged);
    _familySizeController.dispose();
    _incomeGroupController.dispose();
    _centreCodeController.dispose();
    _returnNoController.dispose();
    _monthAndYearController.dispose();
    _mobileNumberController.dispose();
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

  Future<void> _sendOTP() async {
    // Check if all required fields are filled before allowing OTP sending
    if (_nameAndAddressController.text.isEmpty ||
        _districtController.text.isEmpty ||
        _stateController.text.isEmpty ||
        _familySizeController.text.isEmpty ||
        _incomeGroupController.text.isEmpty ||
        _centreCodeController.text.isEmpty ||
        _returnNoController.text.isEmpty ||
        _monthAndYearController.text.isEmpty ||
        _mobileNumberController.text.isEmpty ||
        _householdMembers.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please fill all required fields before sending OTP'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // Check if all household members have required fields
    for (int i = 0; i < _householdMembers.length; i++) {
      final member = _householdMembers[i];
      if (member.nameController.text.isEmpty ||
          member.relationshipController.text.isEmpty ||
          member.genderController.text.isEmpty ||
          member.ageController.text.isEmpty ||
          member.educationController.text.isEmpty ||
          member.occupationController.text.isEmpty ||
          member.annualIncomeJobController.text.isEmpty ||
          member.annualIncomeOtherController.text.isEmpty ||
          member.otherIncomeSourceController.text.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Please fill all required fields for household member ${i + 1}'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }
    }

    setState(() {
      _isOtpLoading = true;
    });

    try {
      final success = await _apiService.sendOTP(_mobileNumberController.text, 'dpr');

      setState(() {
        _isOtpLoading = false;
      });

      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('OTP sent to ${_mobileNumberController.text}'),
            backgroundColor: const Color(0xFF795548), // Brown 600 for success
            duration: const Duration(seconds: 3),
          ),
        );
        
        // Show testing dialog
        _showOtpTestingDialog();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Using offline mode. For testing, use OTP: 123456'),
            backgroundColor: const Color(0xFFFF8A65), // Deep Orange 300 for warning
            duration: const Duration(seconds: 5),
          ),
        );
      }
    } catch (e) {
      setState(() {
        _isOtpLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Network error. Using offline mode. Use OTP: 123456'),
          backgroundColor: const Color(0xFFFF8A65), // Deep Orange 300 for warning
          duration: const Duration(seconds: 5),
        ),
      );
    }
  }

  void _showOtpTestingDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('OTP Sent'),
        content: const Text(
          'OTP has been sent to your phone number.\n\n'
          'For testing purposes, you can use:\n'
          '• OTP: 123456\n'
          '• Or any 6-digit number\n\n'
          'In production, you would receive the OTP via SMS.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  Future<void> _verifyOTP() async {
    // Check if all required fields are filled before allowing OTP verification
    if (_nameAndAddressController.text.isEmpty ||
        _districtController.text.isEmpty ||
        _stateController.text.isEmpty ||
        _familySizeController.text.isEmpty ||
        _incomeGroupController.text.isEmpty ||
        _centreCodeController.text.isEmpty ||
        _returnNoController.text.isEmpty ||
        _monthAndYearController.text.isEmpty ||
        _mobileNumberController.text.isEmpty ||
        _householdMembers.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please fill all required fields before OTP verification'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // Check if all household members have required fields
    for (int i = 0; i < _householdMembers.length; i++) {
      final member = _householdMembers[i];
      if (member.nameController.text.isEmpty ||
          member.relationshipController.text.isEmpty ||
          member.genderController.text.isEmpty ||
          member.ageController.text.isEmpty ||
          member.educationController.text.isEmpty ||
          member.occupationController.text.isEmpty ||
          member.annualIncomeJobController.text.isEmpty ||
          member.annualIncomeOtherController.text.isEmpty ||
          member.otherIncomeSourceController.text.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Please fill all required fields for household member ${i + 1}'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }
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
      // Try the actual OTP first
      bool isValid = await _apiService.verifyOTP(_mobileNumberController.text, _otpController.text, 'dpr');
      
      // If that fails, allow "123456" as a fallback for testing
      if (!isValid && _otpController.text == '123456') {
        isValid = true;
      }

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
    setState(() {
      _householdMembers.add(HouseholdMemberForm());
    });
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

  void _onFamilySizeChanged() {
    final familySize = int.tryParse(_familySizeController.text);
    if (familySize != null && familySize > 0) {
      _adjustMemberCount(familySize);
    }
  }

  void _adjustMemberCount(int targetCount) {
    setState(() {
      // Remove excess members if current count is more than target
      while (_householdMembers.length > targetCount) {
        final member = _householdMembers.removeLast();
        member.dispose();
      }
      
      // Add new members if current count is less than target
      while (_householdMembers.length < targetCount) {
        _householdMembers.add(HouseholdMemberForm());
      }
    });
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
    _mobileNumberController.text = dpr.mobileNumber;
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

    // Validate that member count matches family size
    final familySize = int.tryParse(_familySizeController.text);
    if (familySize == null || familySize <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter a valid family size'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (_householdMembers.length != familySize) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Number of household members (${_householdMembers.length}) must match family size ($familySize)'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    try {
      // Get current LO phone number
      final prefs = await SharedPreferences.getInstance();
      final currentLoPhone = prefs.getString('lo_phone');

      // Convert form data to HouseholdMember objects
      final members = _householdMembers.map((form) => HouseholdMember(
        name: form.nameController.text.isNotEmpty ? form.nameController.text : 'Member',
        relationshipWithHead: form.relationshipController.text.isNotEmpty ? form.relationshipController.text : '',
        gender: form.genderController.text.isNotEmpty ? form.genderController.text : '',
        age: int.tryParse(form.ageController.text) ?? 0,
        education: form.educationController.text.isNotEmpty ? form.educationController.text : '',
        occupation: form.occupationController.text.isNotEmpty ? form.occupationController.text : '',
        annualIncomeJob: double.tryParse(form.annualIncomeJobController.text) ?? 0.0,
        annualIncomeOther: double.tryParse(form.annualIncomeOtherController.text) ?? 0.0,
        otherIncomeSource: form.otherIncomeSourceController.text.isNotEmpty ? form.otherIncomeSourceController.text : '',
        totalIncome: double.tryParse(form.totalIncomeController.text) ?? 0.0,
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
        mobileNumber: _mobileNumberController.text,
        householdMembers: members,
        latitude: _latitude,
        longitude: _longitude,
        otpCode: _otpController.text,
        createdAt: DateTime.now(),
        loPhone: currentLoPhone,
      );

      final dbService = Provider.of<DatabaseService>(context, listen: false);
      
      if (widget.editingDPR != null) {
        // Update existing DPR
        final updatedDPR = dpr.copyWith(
          id: widget.editingDPR!.id,
          backendId: widget.editingDPR!.backendId,
        );
        await dbService.updateDPR(updatedDPR);
        
        // Also update members separately using upsertMembers
        await dbService.upsertMembers(widget.editingDPR!.id!, members);
        
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
              child: DropdownButtonFormField<String>(
                value: _incomeGroupController.text.isNotEmpty ? _incomeGroupController.text : null,
                decoration: const InputDecoration(
                  labelText: 'Income Group *',
                  border: OutlineInputBorder(),
                  helperText: 'Select income group',
                ),
                items: incomeGroupCodes.entries.map((entry) => 
                  DropdownMenuItem(
                    value: entry.key,
                    child: Text('${entry.key} - ${entry.value}'),
                  ),
                ).toList(),
                onChanged: (value) {
                  setState(() {
                    _incomeGroupController.text = value ?? '';
                  });
                },
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please select income group';
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
          controller: _mobileNumberController,
          decoration: const InputDecoration(
            labelText: 'Mobile Number of Head of Household *',
            border: OutlineInputBorder(),
            helperText: 'Enter 10-digit mobile number',
            prefixIcon: Icon(Icons.phone),
          ),
          keyboardType: TextInputType.phone,
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Please enter mobile number';
            }
            if (value.length != 10 || !RegExp(r'^[0-9]+$').hasMatch(value)) {
              return 'Please enter a valid 10-digit mobile number';
            }
            return null;
          },
        ),
        const SizedBox(height: 16),

        Row(
          children: [
                         Expanded(
               child: DropdownButtonFormField<String>(
                 value: _monthAndYearController.text.split('/').isNotEmpty ? 
                   _monthAndYearController.text.split('/')[0].padLeft(2, '0') : null,
                 decoration: const InputDecoration(
                   labelText: 'Month *',
                   border: OutlineInputBorder(),
                   helperText: 'Select month',
                 ),
                 items: monthCodes.entries.map((entry) => 
                   DropdownMenuItem(
                     value: entry.key,
                     child: Text('${entry.key} - ${entry.value}'),
                   ),
                 ).toList(),
                 onChanged: (value) {
                   if (value != null) {
                     final currentYear = _monthAndYearController.text.split('/').length > 1 ? 
                       _monthAndYearController.text.split('/')[1] : DateTime.now().year.toString();
                     _monthAndYearController.text = '$value/$currentYear';
                   }
                 },
                 validator: (value) {
                   if (value == null || value.isEmpty) {
                     return 'Please select month';
                   }
                   return null;
                 },
               ),
             ),
            const SizedBox(width: 16),
            Expanded(
              child: TextFormField(
                controller: TextEditingController(
                  text: _monthAndYearController.text.split('/').length > 1 ? _monthAndYearController.text.split('/')[1] : DateTime.now().year.toString()
                ),
                decoration: const InputDecoration(
                  labelText: 'Year *',
                  border: OutlineInputBorder(),
                  helperText: 'Enter year (YYYY)',
                ),
                keyboardType: TextInputType.number,
                onChanged: (value) {
                  final currentMonth = _monthAndYearController.text.split('/').isNotEmpty ? _monthAndYearController.text.split('/')[0] : '01';
                  _monthAndYearController.text = '$currentMonth/$value';
                },
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter year';
                  }
                  final year = int.tryParse(value);
                  if (year == null || year < 2000 || year > 2030) {
                    return 'Please enter a valid year (2000-2030)';
                  }
                  return null;
                },
              ),
            ),
          ],
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
              'Household Members',
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
                          child: DropdownButtonFormField<String>(
                            value: member.relationshipController.text.isNotEmpty ? 
                              member.relationshipController.text : null,
                            decoration: const InputDecoration(
                              labelText: 'Relationship with Head *',
                              border: OutlineInputBorder(),
                              helperText: 'Select relationship',
                            ),
                            items: relationshipCodes.entries.map((entry) => 
                              DropdownMenuItem(
                                value: entry.key,
                                child: Text('${entry.key} - ${entry.value}'),
                              ),
                            ).toList(),
                            onChanged: (value) {
                              setState(() {
                                member.relationshipController.text = value ?? '';
                              });
                            },
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Please select relationship';
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
                          child: DropdownButtonFormField<String>(
                            value: member.genderController.text.isNotEmpty ? 
                              member.genderController.text : null,
                            decoration: const InputDecoration(
                              labelText: 'Gender *',
                              border: OutlineInputBorder(),
                              helperText: 'Select gender',
                            ),
                            items: genderCodes.entries.map((entry) => 
                              DropdownMenuItem(
                                value: entry.key,
                                child: Text('${entry.key} - ${entry.value}'),
                              ),
                            ).toList(),
                            onChanged: (value) {
                              setState(() {
                                member.genderController.text = value ?? '';
                              });
                            },
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Please select gender';
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
                              helperText: 'Enter age (0-120)',
                            ),
                            keyboardType: TextInputType.number,
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Please enter age';
                              }
                              final age = int.tryParse(value);
                              if (age == null) {
                                return 'Please enter a valid age';
                              }
                              if (age < 0 || age > 120) {
                                return 'Age must be between 0 and 120';
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
                          child: DropdownButtonFormField<String>(
                            value: member.educationController.text.isNotEmpty ? 
                              member.educationController.text : null,
                            decoration: const InputDecoration(
                              labelText: 'Education *',
                              border: OutlineInputBorder(),
                              helperText: 'Select education level',
                            ),
                            items: educationCodes.entries.map((entry) => 
                              DropdownMenuItem(
                                value: entry.key,
                                child: Text('${entry.key} - ${entry.value}'),
                              ),
                            ).toList(),
                            onChanged: (value) {
                              setState(() {
                                member.educationController.text = value ?? '';
                              });
                            },
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Please select education level';
                              }
                              return null;
                            },
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: DropdownButtonFormField<String>(
                            value: member.occupationController.text.isNotEmpty ? 
                              member.occupationController.text : null,
                            decoration: const InputDecoration(
                              labelText: 'Occupation *',
                              border: OutlineInputBorder(),
                              helperText: 'Select occupation',
                            ),
                            items: dprOccupationCodes.entries.map((entry) => 
                              DropdownMenuItem(
                                value: entry.key,
                                child: Text('${entry.key} - ${entry.value}'),
                              ),
                            ).toList(),
                            onChanged: (value) {
                              setState(() {
                                member.occupationController.text = value ?? '';
                              });
                            },
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Please select occupation';
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
              child: ElevatedButton.icon(
                onPressed: _isOtpLoading ? null : _sendOTP,
                icon: _isOtpLoading 
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.send),
                label: Text(_isOtpLoading ? 'Sending...' : 'Send OTP'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFD84315),
                  foregroundColor: Colors.white,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),

        Row(
          children: [
            Expanded(
              child: TextFormField(
                controller: _otpController,
                decoration: const InputDecoration(
                  labelText: 'Enter OTP *',
                  border: OutlineInputBorder(),
                  hintText: 'Enter 6-digit OTP',
                  helperText: 'Check your mobile for OTP',
                ),
                keyboardType: TextInputType.number,
                maxLength: 6,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter OTP';
                  }
                  if (value.length != 6 || !RegExp(r'^[0-9]+$').hasMatch(value)) {
                    return 'Please enter a valid 6-digit OTP';
                  }
                  return null;
                },
              ),
            ),
            const SizedBox(width: 16),
            ElevatedButton(
              onPressed: _isOtpLoading ? null : _verifyOTP,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                foregroundColor: Colors.white,
              ),
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