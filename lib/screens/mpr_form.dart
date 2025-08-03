import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:location/location.dart';
import '../models/mpr.dart';
import '../services/db_service.dart';
import '../services/api_service.dart';

class MPRFormScreen extends StatefulWidget {
  final MPR? editingMPR;
  
  const MPRFormScreen({super.key, this.editingMPR});

  @override
  State<MPRFormScreen> createState() => _MPRFormScreenState();
}

class _MPRFormScreenState extends State<MPRFormScreen> {
  final _formKey = GlobalKey<FormState>();

  // Header Form Controllers
  final _nameAndAddressController = TextEditingController();
  final _districtStateTelController = TextEditingController();
  final _panelCentreController = TextEditingController();
  final _centreCodeController = TextEditingController();
  final _returnNoController = TextEditingController();
  final _familySizeController = TextEditingController();
  final _incomeGroupController = TextEditingController();
  final _monthAndYearController = TextEditingController();
  final _occupationOfHeadController = TextEditingController();
  final _otpController = TextEditingController();

  // Purchase Items (up to 10)
  final List<PurchaseItemForm> _purchaseItems = [];

  // Location data
  double _latitude = 0.0;
  double _longitude = 0.0;
  bool _isLocationLoading = false;

  // Form state
  bool _isSubmitting = false;
  bool _isOtpVerified = false;
  final ApiService _apiService = ApiService();
  bool _isOtpLoading = false;

  // Auto-fill state
  bool _isAutoFilled = false;
  bool _isLoadingDPR = false;
  String? _dprLoadMessage;

  // Dropdown options
  final List<String> _fibreCodes = ['01', '02', '03', '04', '05', '06', '07', '08', '09', '10'];
  final List<String> _sectorCodes = ['01', '02', '03', '04', '05'];
  final List<String> _colourCodes = ['01', '02', '03', '04', '05', '06', '07', '08', '09', '10'];
  final List<String> _shopTypeCodes = ['01', '02', '03', '04', '05'];
  final List<String> _purchaseTypeCodes = ['01', '02', '03', '04'];
  final List<String> _dressIntendedCodes = ['01', '02', '03', '04', '05', '06'];

  @override
  void initState() {
    super.initState();
    _getCurrentLocation();
    _monthAndYearController.text = '${DateTime.now().month}/${DateTime.now().year}';
    _addPurchaseItem(); // Add first item by default
    
    // If editing, populate the form with existing data
    if (widget.editingMPR != null) {
      _populateFormWithMPR(widget.editingMPR!);
    }
  }

  @override
  void dispose() {
    _nameAndAddressController.dispose();
    _districtStateTelController.dispose();
    _panelCentreController.dispose();
    _centreCodeController.dispose();
    _returnNoController.dispose();
    _familySizeController.dispose();
    _incomeGroupController.dispose();
    _monthAndYearController.dispose();
    _occupationOfHeadController.dispose();
    _otpController.dispose();
    super.dispose();
  }

  Future<void> _getCurrentLocation() async {
    setState(() {
      _isLocationLoading = true;
    });

    try {
      Location location = Location();
      
      bool serviceEnabled = await location.serviceEnabled();
      if (!serviceEnabled) {
        serviceEnabled = await location.requestService();
        if (!serviceEnabled) {
          _showLocationError('Location service is disabled');
          return;
        }
      }

      PermissionStatus permissionGranted = await location.hasPermission();
      if (permissionGranted == PermissionStatus.denied) {
        permissionGranted = await location.requestPermission();
        if (permissionGranted != PermissionStatus.granted) {
          _showLocationError('Location permission denied');
          return;
        }
      }

      LocationData currentLocation = await location.getLocation();
      
      setState(() {
        _latitude = currentLocation.latitude ?? 0.0;
        _longitude = currentLocation.longitude ?? 0.0;
        _isLocationLoading = false;
      });
    } catch (e) {
      _showLocationError('Failed to get location: $e');
    }
  }

  void _showLocationError(String message) {
    setState(() {
      _isLocationLoading = false;
    });
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red),
    );
  }

  Future<void> _verifyOTP() async {
    if (_otpController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter OTP'), backgroundColor: Colors.red),
      );
      return;
    }

    setState(() {
      _isOtpLoading = true;
    });

    try {
      final isValid = await _apiService.verifyOTP('', _otpController.text);
      setState(() {
        _isOtpVerified = isValid;
        _isOtpLoading = false;
      });

      if (isValid) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('OTP verified successfully'), backgroundColor: Colors.green),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Invalid OTP. Please try again.'), backgroundColor: Colors.red),
        );
      }
    } catch (e) {
      setState(() {
        _isOtpLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error verifying OTP: $e'), backgroundColor: Colors.red),
      );
    }
  }

  void _addPurchaseItem() {
    if (_purchaseItems.length < 10) {
      setState(() {
        _purchaseItems.add(PurchaseItemForm());
      });
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Maximum 10 purchase items allowed'), backgroundColor: Colors.orange),
      );
    }
  }

  void _removePurchaseItem(int index) {
    setState(() {
      _purchaseItems.removeAt(index);
    });
  }

  void _calculateTotalAmount(PurchaseItemForm item) {
    final length = double.tryParse(item.lengthInMetersController.text) ?? 0.0;
    final pricePerMeter = double.tryParse(item.pricePerMeterController.text) ?? 0.0;
    final total = length * pricePerMeter;
    item.totalAmountController.text = total.toStringAsFixed(2);
  }

  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (!_isOtpVerified) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please verify OTP before submitting'), backgroundColor: Colors.red),
      );
      return;
    }

    if (_purchaseItems.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please add at least one purchase item'), backgroundColor: Colors.red),
      );
      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    try {
      // Convert form data to PurchaseItem objects
      final items = _purchaseItems.map((form) => PurchaseItem(
        itemName: form.itemNameController.text,
        itemCode: form.itemCodeController.text,
        monthOfPurchase: form.monthOfPurchaseController.text,
        fibreCode: form.fibreCodeController.text,
        sectorOfManufactureCode: form.sectorCodeController.text,
        colourDesignCode: form.colourCodeController.text,
        personAgeGender: form.personAgeGenderController.text,
        typeOfShopCode: form.shopTypeCodeController.text,
        purchaseTypeCode: form.purchaseTypeCodeController.text,
        dressIntendedCode: form.dressIntendedCodeController.text,
        lengthInMeters: double.parse(form.lengthInMetersController.text),
        pricePerMeter: double.parse(form.pricePerMeterController.text),
        totalAmountPaid: double.parse(form.totalAmountController.text),
        brandMillName: form.brandMillNameController.text,
        isImported: form.isImportedController.text == 'Y',
      )).toList();

      final mpr = MPR(
        nameAndAddress: _nameAndAddressController.text,
        districtStateTel: _districtStateTelController.text,
        panelCentre: _panelCentreController.text,
        centreCode: _centreCodeController.text,
        returnNo: _returnNoController.text,
        familySize: int.parse(_familySizeController.text),
        incomeGroup: _incomeGroupController.text,
        monthAndYear: _monthAndYearController.text,
        occupationOfHead: _occupationOfHeadController.text,
        items: items,
        latitude: _latitude,
        longitude: _longitude,
        otpCode: _otpController.text,
        createdAt: DateTime.now(),
      );

      final dbService = Provider.of<DatabaseService>(context, listen: false);
      
      if (widget.editingMPR != null) {
        // Update existing MPR
        final updatedMPR = mpr.copyWith(id: widget.editingMPR!.id);
        await dbService.updateMPR(updatedMPR);
        
        setState(() {
          _isSubmitting = false;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('MPR updated successfully!'),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        // Create new MPR
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
      }

      // Clear form
      _formKey.currentState!.reset();
      setState(() {
        _purchaseItems.clear();
        _addPurchaseItem();
        _isOtpVerified = false;
        _isAutoFilled = false;
        _dprLoadMessage = null;
      });

      Navigator.pop(context);
    } catch (e) {
      setState(() {
        _isSubmitting = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error submitting form: $e'), backgroundColor: Colors.red),
      );
    }
  }

  void _populateFormWithMPR(MPR mpr) {
    _nameAndAddressController.text = mpr.nameAndAddress;
    _districtStateTelController.text = mpr.districtStateTel;
    _panelCentreController.text = mpr.panelCentre;
    _centreCodeController.text = mpr.centreCode;
    _returnNoController.text = mpr.returnNo;
    _familySizeController.text = mpr.familySize.toString();
    _incomeGroupController.text = mpr.incomeGroup;
    _monthAndYearController.text = mpr.monthAndYear;
    _occupationOfHeadController.text = mpr.occupationOfHead;
    _otpController.text = mpr.otpCode;
    _latitude = mpr.latitude;
    _longitude = mpr.longitude;
    _isOtpVerified = true; // Assume OTP is already verified for existing records
    
    // Clear existing purchase items and add the ones from MPR
    for (var item in _purchaseItems) {
      item.dispose();
    }
    _purchaseItems.clear();
    
    for (var item in mpr.items) {
      final formItem = PurchaseItemForm();
      formItem.itemNameController.text = item.itemName;
      formItem.itemCodeController.text = item.itemCode;
      formItem.monthOfPurchaseController.text = item.monthOfPurchase;
      formItem.fibreCodeController.text = item.fibreCode;
      formItem.sectorCodeController.text = item.sectorOfManufactureCode;
      formItem.colourCodeController.text = item.colourDesignCode;
      formItem.personAgeGenderController.text = item.personAgeGender;
      formItem.shopTypeCodeController.text = item.typeOfShopCode;
      formItem.purchaseTypeCodeController.text = item.purchaseTypeCode;
      formItem.dressIntendedCodeController.text = item.dressIntendedCode;
      formItem.lengthInMetersController.text = item.lengthInMeters.toString();
      formItem.pricePerMeterController.text = item.pricePerMeter.toString();
      formItem.totalAmountController.text = item.totalAmountPaid.toString();
      formItem.brandMillNameController.text = item.brandMillName;
      formItem.isImportedController.text = item.isImported ? 'Y' : 'N';
      _purchaseItems.add(formItem);
    }
  }

  // Auto-fill MPR fields from DPR data
  Future<void> _fetchDprDetailsIfAvailable() async {
    final centreCode = _centreCodeController.text.trim();
    final returnNo = _returnNoController.text.trim();
    
    // Only proceed if both fields are filled
    if (centreCode.isEmpty || returnNo.isEmpty) {
      return;
    }

    setState(() {
      _isLoadingDPR = true;
      _dprLoadMessage = null;
    });

    try {
      final dbService = Provider.of<DatabaseService>(context, listen: false);
      final dpr = await dbService.getDPRByCentreAndReturn(centreCode, returnNo);
      
      if (dpr != null) {
        // Auto-fill the fields
        _nameAndAddressController.text = dpr.nameAndAddress;
        _districtStateTelController.text = '${dpr.district}, ${dpr.state}';
        _familySizeController.text = dpr.familySize.toString();
        _incomeGroupController.text = dpr.incomeGroup;
        
        // Find occupation from household members (head of family)
        String occupation = '';
        if (dpr.householdMembers.isNotEmpty) {
          // Assume first member is head of family, or find by relationship
          final headMember = dpr.householdMembers.firstWhere(
            (member) => member.relationshipWithHead.toLowerCase().contains('head') ||
                       member.relationshipWithHead.toLowerCase().contains('self'),
            orElse: () => dpr.householdMembers.first,
          );
          occupation = headMember.occupation;
        }
        _occupationOfHeadController.text = occupation;
        
        setState(() {
          _isAutoFilled = true;
          _dprLoadMessage = '✔ DPR data loaded for Return No: $returnNo';
        });
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('DPR data auto-filled successfully!'),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 3),
          ),
        );
      } else {
        setState(() {
          _isAutoFilled = false;
          _dprLoadMessage = '⚠ No DPR found for Centre Code: $centreCode, Return No: $returnNo';
        });
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('No DPR record found for the entered Centre Code and Return Number'),
            backgroundColor: Colors.orange,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    } catch (e) {
      setState(() {
        _dprLoadMessage = '❌ Error loading DPR data: $e';
      });
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error loading DPR data: $e'),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 3),
        ),
      );
    } finally {
      setState(() {
        _isLoadingDPR = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.editingMPR != null ? 'Edit MPR' : 'MPR Form - Monthly Purchase Return'),
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
            child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Location Status
              _buildLocationCard(),
              const SizedBox(height: 16),

              // Header Information
              _buildHeaderSection(),
              const SizedBox(height: 16),
              
              // DPR Auto-fill Status
              if (_dprLoadMessage != null)
                Card(
                  color: _isAutoFilled ? Colors.green.shade50 : Colors.orange.shade50,
                  child: Padding(
                    padding: const EdgeInsets.all(12.0),
                    child: Row(
                      children: [
                        Icon(
                          _isAutoFilled ? Icons.check_circle : Icons.warning,
                          color: _isAutoFilled ? Colors.green : Colors.orange,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            _dprLoadMessage!,
                            style: TextStyle(
                              color: _isAutoFilled ? Colors.green.shade800 : Colors.orange.shade800,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              const SizedBox(height: 24),

              // Purchase Items Section
              _buildPurchaseItemsSection(),
              const SizedBox(height: 24),

              // OTP Verification
              _buildOTPSection(),
              const SizedBox(height: 32),

              // Submit Button
              ElevatedButton(
                onPressed: _isSubmitting ? null : _submitForm,
                style: ElevatedButton.styleFrom(padding: const EdgeInsets.all(16)),
                child: _isSubmitting
                    ? const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2)),
                          SizedBox(width: 16),
                          Text('Submitting...'),
                        ],
                      )
                    : Text(widget.editingMPR != null ? 'Save Changes' : 'Submit MPR Form'),
              ),
            ],
          ),
        ),
      ),
    ),
    );
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
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
                            Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Header Information',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  if (_centreCodeController.text.isNotEmpty && _returnNoController.text.isNotEmpty)
                    TextButton.icon(
                      onPressed: _isLoadingDPR ? null : _fetchDprDetailsIfAvailable,
                      icon: _isLoadingDPR 
                        ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
                        : const Icon(Icons.refresh, size: 16),
                      label: Text(_isLoadingDPR ? 'Loading...' : 'Load DPR Data'),
                    ),
                ],
              ),
              const SizedBox(height: 16),

              TextFormField(
                controller: _nameAndAddressController,
                decoration: InputDecoration(
                  labelText: 'Name & Address *',
                  border: const OutlineInputBorder(),
                  filled: _isAutoFilled,
                  fillColor: _isAutoFilled ? Colors.grey.shade100 : null,
                  suffixIcon: _isAutoFilled 
                    ? const Icon(Icons.auto_awesome, color: Colors.green, size: 16)
                    : null,
                ),
                maxLines: 3,
                validator: (value) => value?.isEmpty == true ? 'Required' : null,
                readOnly: _isAutoFilled,
              ),
            const SizedBox(height: 16),

            TextFormField(
              controller: _districtStateTelController,
              decoration: InputDecoration(
                labelText: 'District, State, Tel No. *',
                border: const OutlineInputBorder(),
                filled: _isAutoFilled,
                fillColor: _isAutoFilled ? Colors.grey.shade100 : null,
                suffixIcon: _isAutoFilled 
                  ? const Icon(Icons.auto_awesome, color: Colors.green, size: 16)
                  : null,
              ),
              validator: (value) => value?.isEmpty == true ? 'Required' : null,
              readOnly: _isAutoFilled,
            ),
            const SizedBox(height: 16),

            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _panelCentreController,
                    decoration: const InputDecoration(
                      labelText: 'Panel Centre *',
                      border: OutlineInputBorder(),
                    ),
                    validator: (value) => value?.isEmpty == true ? 'Required' : null,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: TextFormField(
                    controller: _centreCodeController,
                    decoration: InputDecoration(
                      labelText: 'Centre Code *',
                      border: const OutlineInputBorder(),
                      suffixIcon: _isLoadingDPR 
                        ? const SizedBox(
                            width: 20, 
                            height: 20, 
                            child: Padding(
                              padding: EdgeInsets.all(8.0),
                              child: CircularProgressIndicator(strokeWidth: 2),
                            ),
                          )
                        : null,
                    ),
                    validator: (value) => value?.isEmpty == true ? 'Required' : null,
                    onChanged: (value) {
                      if (value.isNotEmpty && _returnNoController.text.isNotEmpty) {
                        _fetchDprDetailsIfAvailable();
                      }
                    },
                    onFieldSubmitted: (value) {
                      if (value.isNotEmpty && _returnNoController.text.isNotEmpty) {
                        _fetchDprDetailsIfAvailable();
                      }
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
                    controller: _returnNoController,
                    decoration: InputDecoration(
                      labelText: 'Return No. *',
                      border: const OutlineInputBorder(),
                      suffixIcon: _isLoadingDPR 
                        ? const SizedBox(
                            width: 20, 
                            height: 20, 
                            child: Padding(
                              padding: EdgeInsets.all(8.0),
                              child: CircularProgressIndicator(strokeWidth: 2),
                            ),
                          )
                        : null,
                    ),
                    validator: (value) => value?.isEmpty == true ? 'Required' : null,
                    onChanged: (value) {
                      if (value.isNotEmpty && _centreCodeController.text.isNotEmpty) {
                        _fetchDprDetailsIfAvailable();
                      }
                    },
                    onFieldSubmitted: (value) {
                      if (value.isNotEmpty && _centreCodeController.text.isNotEmpty) {
                        _fetchDprDetailsIfAvailable();
                      }
                    },
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: TextFormField(
                    controller: _familySizeController,
                    decoration: InputDecoration(
                      labelText: 'Family Size *',
                      border: const OutlineInputBorder(),
                      filled: _isAutoFilled,
                      fillColor: _isAutoFilled ? Colors.grey.shade100 : null,
                      suffixIcon: _isAutoFilled 
                        ? const Icon(Icons.auto_awesome, color: Colors.green, size: 16)
                        : null,
                    ),
                    keyboardType: TextInputType.number,
                    validator: (value) {
                      if (value?.isEmpty == true) return 'Required';
                      if (int.tryParse(value!) == null) return 'Invalid number';
                      return null;
                    },
                    readOnly: _isAutoFilled,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _incomeGroupController,
                    decoration: InputDecoration(
                      labelText: 'Income Group *',
                      border: const OutlineInputBorder(),
                      filled: _isAutoFilled,
                      fillColor: _isAutoFilled ? Colors.grey.shade100 : null,
                      suffixIcon: _isAutoFilled 
                        ? const Icon(Icons.auto_awesome, color: Colors.green, size: 16)
                        : null,
                    ),
                    validator: (value) => value?.isEmpty == true ? 'Required' : null,
                    readOnly: _isAutoFilled,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: TextFormField(
                    controller: _monthAndYearController,
                    decoration: const InputDecoration(
                      labelText: 'Month & Year *',
                      border: OutlineInputBorder(),
                    ),
                    validator: (value) => value?.isEmpty == true ? 'Required' : null,
                  ),
                ),
              ],
              ),
              const SizedBox(height: 16),

              TextFormField(
                controller: _occupationOfHeadController,
                decoration: InputDecoration(
                  labelText: 'Occupation of Head of Family *',
                  border: const OutlineInputBorder(),
                  filled: _isAutoFilled,
                  fillColor: _isAutoFilled ? Colors.grey.shade100 : null,
                  suffixIcon: _isAutoFilled 
                    ? const Icon(Icons.auto_awesome, color: Colors.green, size: 16)
                    : null,
                ),
                validator: (value) => value?.isEmpty == true ? 'Required' : null,
                readOnly: _isAutoFilled,
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildPurchaseItemsSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Purchase Items (Max 10)',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                ElevatedButton.icon(
                  onPressed: _addPurchaseItem,
                  icon: const Icon(Icons.add),
                  label: const Text('Add Item'),
                ),
              ],
            ),
            const SizedBox(height: 16),
            
            ..._purchaseItems.asMap().entries.map((entry) {
              final index = entry.key;
              final item = entry.value;
              return _buildPurchaseItemForm(index, item);
            }).toList(),
          ],
        ),
      ),
    );
  }

  Widget _buildPurchaseItemForm(int index, PurchaseItemForm item) {
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
                  'Item ${index + 1}',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                if (_purchaseItems.length > 1)
                  IconButton(
                    onPressed: () => _removePurchaseItem(index),
                    icon: const Icon(Icons.delete, color: Colors.red),
                    tooltip: 'Remove Item',
                  ),
              ],
            ),
            const SizedBox(height: 16),

            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: item.itemNameController,
                    decoration: const InputDecoration(
                      labelText: 'Item Name *',
                      border: OutlineInputBorder(),
                    ),
                    validator: (value) => value?.isEmpty == true ? 'Required' : null,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: TextFormField(
                    controller: item.itemCodeController,
                    decoration: const InputDecoration(
                      labelText: 'Item Code *',
                      border: OutlineInputBorder(),
                    ),
                    validator: (value) => value?.isEmpty == true ? 'Required' : null,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: item.monthOfPurchaseController,
                    decoration: const InputDecoration(
                      labelText: 'Month of Purchase *',
                      border: OutlineInputBorder(),
                    ),
                    validator: (value) => value?.isEmpty == true ? 'Required' : null,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: DropdownButtonFormField<String>(
                    value: item.fibreCodeController.text.isEmpty ? null : item.fibreCodeController.text,
                    decoration: const InputDecoration(
                      labelText: 'Fibre Code *',
                      border: OutlineInputBorder(),
                    ),
                    items: _fibreCodes.map((code) => DropdownMenuItem(value: code, child: Text(code))).toList(),
                    onChanged: (value) {
                      item.fibreCodeController.text = value ?? '';
                    },
                    validator: (value) => value?.isEmpty == true ? 'Required' : null,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            Row(
              children: [
                Expanded(
                  child: DropdownButtonFormField<String>(
                    value: item.sectorCodeController.text.isEmpty ? null : item.sectorCodeController.text,
                    decoration: const InputDecoration(
                      labelText: 'Sector of Manufacture Code *',
                      border: OutlineInputBorder(),
                    ),
                    items: _sectorCodes.map((code) => DropdownMenuItem(value: code, child: Text(code))).toList(),
                    onChanged: (value) {
                      item.sectorCodeController.text = value ?? '';
                    },
                    validator: (value) => value?.isEmpty == true ? 'Required' : null,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: DropdownButtonFormField<String>(
                    value: item.colourCodeController.text.isEmpty ? null : item.colourCodeController.text,
                    decoration: const InputDecoration(
                      labelText: 'Colour/Design Code *',
                      border: OutlineInputBorder(),
                    ),
                    items: _colourCodes.map((code) => DropdownMenuItem(value: code, child: Text(code))).toList(),
                    onChanged: (value) {
                      item.colourCodeController.text = value ?? '';
                    },
                    validator: (value) => value?.isEmpty == true ? 'Required' : null,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: item.personAgeGenderController,
                    decoration: const InputDecoration(
                      labelText: 'Person Age & Gender *',
                      border: OutlineInputBorder(),
                      hintText: 'e.g., 25M, 30F',
                    ),
                    validator: (value) => value?.isEmpty == true ? 'Required' : null,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: DropdownButtonFormField<String>(
                    value: item.shopTypeCodeController.text.isEmpty ? null : item.shopTypeCodeController.text,
                    decoration: const InputDecoration(
                      labelText: 'Type of Shop Code *',
                      border: OutlineInputBorder(),
                    ),
                    items: _shopTypeCodes.map((code) => DropdownMenuItem(value: code, child: Text(code))).toList(),
                    onChanged: (value) {
                      item.shopTypeCodeController.text = value ?? '';
                    },
                    validator: (value) => value?.isEmpty == true ? 'Required' : null,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            Row(
              children: [
                Expanded(
                  child: DropdownButtonFormField<String>(
                    value: item.purchaseTypeCodeController.text.isEmpty ? null : item.purchaseTypeCodeController.text,
                    decoration: const InputDecoration(
                      labelText: 'Purchase Type Code *',
                      border: OutlineInputBorder(),
                    ),
                    items: _purchaseTypeCodes.map((code) => DropdownMenuItem(value: code, child: Text(code))).toList(),
                    onChanged: (value) {
                      item.purchaseTypeCodeController.text = value ?? '';
                    },
                    validator: (value) => value?.isEmpty == true ? 'Required' : null,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: DropdownButtonFormField<String>(
                    value: item.dressIntendedCodeController.text.isEmpty ? null : item.dressIntendedCodeController.text,
                    decoration: const InputDecoration(
                      labelText: 'Dress Intended Code *',
                      border: OutlineInputBorder(),
                    ),
                    items: _dressIntendedCodes.map((code) => DropdownMenuItem(value: code, child: Text(code))).toList(),
                    onChanged: (value) {
                      item.dressIntendedCodeController.text = value ?? '';
                    },
                    validator: (value) => value?.isEmpty == true ? 'Required' : null,
                  ),
                ),
              ],
              ),
              const SizedBox(height: 16),

              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                    controller: item.lengthInMetersController,
                      decoration: const InputDecoration(
                      labelText: 'Length in Meters *',
                        border: OutlineInputBorder(),
                      ),
                      keyboardType: TextInputType.number,
                    onChanged: (value) => _calculateTotalAmount(item),
                      validator: (value) {
                      if (value?.isEmpty == true) return 'Required';
                      if (double.tryParse(value!) == null) return 'Invalid number';
                        return null;
                      },
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: TextFormField(
                    controller: item.pricePerMeterController,
                      decoration: const InputDecoration(
                      labelText: 'Price per Meter *',
                        border: OutlineInputBorder(),
                      ),
                      keyboardType: TextInputType.number,
                    onChanged: (value) => _calculateTotalAmount(item),
                      validator: (value) {
                      if (value?.isEmpty == true) return 'Required';
                      if (double.tryParse(value!) == null) return 'Invalid amount';
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
                    controller: item.totalAmountController,
                decoration: const InputDecoration(
                      labelText: 'Total Amount Paid *',
                  border: OutlineInputBorder(),
                    ),
                    keyboardType: TextInputType.number,
                    readOnly: true,
                    validator: (value) => value?.isEmpty == true ? 'Required' : null,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: DropdownButtonFormField<String>(
                    value: item.isImportedController.text.isEmpty ? null : item.isImportedController.text,
                    decoration: const InputDecoration(
                      labelText: 'Imported (Y/N) *',
                      border: OutlineInputBorder(),
                    ),
                    items: const [
                      DropdownMenuItem(value: 'Y', child: Text('Yes')),
                      DropdownMenuItem(value: 'N', child: Text('No')),
                    ],
                    onChanged: (value) {
                      item.isImportedController.text = value ?? '';
                    },
                    validator: (value) => value?.isEmpty == true ? 'Required' : null,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            TextFormField(
              controller: item.brandMillNameController,
              decoration: const InputDecoration(
                labelText: 'Brand/Mill Name *',
                border: OutlineInputBorder(),
              ),
              validator: (value) => value?.isEmpty == true ? 'Required' : null,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOTPSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
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
                      hintText: 'Enter 123456 for testing',
                    ),
                    keyboardType: TextInputType.number,
                    validator: (value) => value?.isEmpty == true ? 'Required' : null,
                  ),
                ),
                const SizedBox(width: 16),
              ElevatedButton(
                  onPressed: _isOtpLoading ? null : _verifyOTP,
                  child: _isOtpLoading
                      ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
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
                  Text('OTP verified successfully', style: TextStyle(color: Colors.green[700])),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class PurchaseItemForm {
  final TextEditingController itemNameController = TextEditingController();
  final TextEditingController itemCodeController = TextEditingController();
  final TextEditingController monthOfPurchaseController = TextEditingController();
  final TextEditingController fibreCodeController = TextEditingController();
  final TextEditingController sectorCodeController = TextEditingController();
  final TextEditingController colourCodeController = TextEditingController();
  final TextEditingController personAgeGenderController = TextEditingController();
  final TextEditingController shopTypeCodeController = TextEditingController();
  final TextEditingController purchaseTypeCodeController = TextEditingController();
  final TextEditingController dressIntendedCodeController = TextEditingController();
  final TextEditingController lengthInMetersController = TextEditingController();
  final TextEditingController pricePerMeterController = TextEditingController();
  final TextEditingController totalAmountController = TextEditingController();
  final TextEditingController brandMillNameController = TextEditingController();
  final TextEditingController isImportedController = TextEditingController();

  void dispose() {
    itemNameController.dispose();
    itemCodeController.dispose();
    monthOfPurchaseController.dispose();
    fibreCodeController.dispose();
    sectorCodeController.dispose();
    colourCodeController.dispose();
    personAgeGenderController.dispose();
    shopTypeCodeController.dispose();
    purchaseTypeCodeController.dispose();
    dressIntendedCodeController.dispose();
    lengthInMetersController.dispose();
    pricePerMeterController.dispose();
    totalAmountController.dispose();
    brandMillNameController.dispose();
    isImportedController.dispose();
  }
} 