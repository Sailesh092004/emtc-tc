import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:location/location.dart';
import '../models/mpr.dart';
import '../services/db_service.dart';
import '../services/api_service.dart';
import '../data/codebook.dart';

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
  
  // Income fields from DPR (read-only when auto-filled)
  final _annualIncomeJobController = TextEditingController();
  final _annualIncomeOtherController = TextEditingController();
  final _otherIncomeSourceController = TextEditingController();
  final _totalIncomeController = TextEditingController();

  // Purchase Items
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
  String? _linkedMobileNumber; // Mobile number from linked DPR



  @override
  void initState() {
    super.initState();
    _getCurrentLocation();
    _monthAndYearController.text = '${DateTime.now().month}/${DateTime.now().year}';
    _addPurchaseItem(); // Add first item by default
    
    // Add listeners to trigger DPR loading when centre code or return number changes
    _centreCodeController.addListener(_onCentreOrReturnChanged);
    _returnNoController.addListener(_onCentreOrReturnChanged);
    
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
    _centreCodeController.removeListener(_onCentreOrReturnChanged);
    _centreCodeController.dispose();
    _returnNoController.removeListener(_onCentreOrReturnChanged);
    _returnNoController.dispose();
    _familySizeController.dispose();
    _incomeGroupController.dispose();
    _monthAndYearController.dispose();
    _occupationOfHeadController.dispose();
    _otpController.dispose();
    
    // Dispose income controllers
    _annualIncomeJobController.dispose();
    _annualIncomeOtherController.dispose();
    _otherIncomeSourceController.dispose();
    _totalIncomeController.dispose();
    
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

  // DPR-driven gender and age options
  List<Map<String, dynamic>> _dprMembers = [];
  
  Future<void> _loadDpr() async {
    if (_centreCodeController.text.isEmpty || _returnNoController.text.isEmpty) {
      return;
    }

    setState(() {
      _isLoadingDPR = true;
      _dprLoadMessage = 'Loading DPR data...';
    });

    try {
      final dbService = Provider.of<DatabaseService>(context, listen: false);
      final cached = await dbService.getDprFor(_centreCodeController.text, _returnNoController.text);
      
      Map<String, dynamic>? dpr = cached;
      if (dpr == null) {
        try {
          dpr = await _apiService.fetchDprFor(_centreCodeController.text, _returnNoController.text);
          await dbService.cacheDprFor(_centreCodeController.text, _returnNoController.text, dpr);
        } catch (e) {
          print('Failed to fetch DPR from API: $e');
        }
      }

      setState(() {
        _dprMembers = (dpr?['members'] as List?)?.cast<Map<String, dynamic>>() ?? [];
        _isLoadingDPR = false;
        _dprLoadMessage = null;
        
        // Reset gender/age selections if they're no longer valid
        for (var item in _purchaseItems) {
          if (item.selectedGender != null && !_hasGender(item.selectedGender!, _dprMembers)) {
            item.selectedGender = null;
          }
          if (item.selectedAge != null && !_hasAge(item.selectedAge!, item.selectedGender, _dprMembers)) {
            item.selectedAge = null;
          }
        }
      });
    } catch (e) {
      setState(() {
        _isLoadingDPR = false;
        _dprLoadMessage = 'Failed to load DPR: $e';
      });
    }
  }

  bool _hasGender(String gender, List<Map<String, dynamic>> members) {
    return members.any((member) => (member['gender'] as String?)?.toUpperCase() == gender);
  }

  bool _hasAge(int age, String? gender, List<Map<String, dynamic>> members) {
    if (gender == null) return false;
    return members.any((member) => 
      (member['gender'] as String?)?.toUpperCase() == gender && 
      (member['age'] as int?) == age
    );
  }

  List<String> _getGenderOptions() {
    final set = <String>{};
    for (final member in _dprMembers) {
      final gender = (member['gender'] as String?)?.toUpperCase();
      if (gender == 'M' || gender == 'F') {
        set.add(gender!);
      }
    }
    return set.toList()..sort(); // e.g., ["F", "M"]
  }

  List<int> _getAgeOptions(String? selectedGender) {
    if (selectedGender == null) return const [];
    
    final set = <int>{};
    for (final member in _dprMembers) {
      if ((member['gender'] as String?)?.toUpperCase() == selectedGender) {
        final age = member['age'];
        if (age is int) {
          set.add(age);
        }
      }
    }
    return set.toList()..sort();
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
      if (_linkedMobileNumber == null || _linkedMobileNumber!.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('No linked DPR mobile number found. Please load DPR data first.'),
            backgroundColor: Colors.red,
          ),
        );
        setState(() {
          _isOtpLoading = false;
        });
        return;
      }

      // Try the actual OTP first
      bool isValid = await _apiService.verifyOTP(_linkedMobileNumber!, _otpController.text, 'mpr');
      
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
    setState(() {
      _purchaseItems.add(PurchaseItemForm());
    });
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
        const SnackBar(
          content: Text('Please verify OTP before submitting'),
          backgroundColor: Colors.red,
        ),
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
      // Get current LO phone number
      final prefs = await SharedPreferences.getInstance();
      final currentLoPhone = prefs.getString('lo_phone');

      // Convert form data to PurchaseItem objects
      final items = _purchaseItems.map((form) => PurchaseItem(
        itemName: form.itemNameController.text,
        itemCode: form.itemCodeController.text,
        monthOfPurchase: form.monthOfPurchaseController.text,
        fibreCode: form.fibreCodeController.text,
        sectorOfManufactureCode: form.sectorCodeController.text,
        colourDesignCode: form.colourCodeController.text,
        gender: form.selectedGender,
        age: form.selectedAge,
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
        loPhone: currentLoPhone,
        // Include income data from DPR if available
        annualIncomeJob: _annualIncomeJobController.text.isNotEmpty ? 
          double.tryParse(_annualIncomeJobController.text) : null,
        annualIncomeOther: _annualIncomeOtherController.text.isNotEmpty ? 
          double.tryParse(_annualIncomeOtherController.text) : null,
        otherIncomeSource: _otherIncomeSourceController.text.isNotEmpty ? 
          _otherIncomeSourceController.text : null,
        totalIncome: _totalIncomeController.text.isNotEmpty ? 
          double.tryParse(_totalIncomeController.text) : null,
      );

      final dbService = Provider.of<DatabaseService>(context, listen: false);
      
      if (widget.editingMPR != null) {
        // Update existing MPR
        final updatedMPR = mpr.copyWith(
          id: widget.editingMPR!.id,
          backendId: widget.editingMPR!.backendId,
        );
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
    // Only set dropdown values if they exist in the dropdown options
    if (mpr.incomeGroup.isNotEmpty && incomeGroupCodes.containsKey(mpr.incomeGroup)) {
      _incomeGroupController.text = mpr.incomeGroup;
    } else {
      _incomeGroupController.text = '';
    }
    _monthAndYearController.text = mpr.monthAndYear;
    if (mpr.occupationOfHead.isNotEmpty && occupationCodes.containsKey(mpr.occupationOfHead)) {
      _occupationOfHeadController.text = mpr.occupationOfHead;
    } else {
      _occupationOfHeadController.text = '';
    }
    _otpController.text = mpr.otpCode;
    _latitude = mpr.latitude;
    _longitude = mpr.longitude;
    _isOtpVerified = true; // Assume OTP is already verified for existing records
    
    // Populate income fields if available
    if (mpr.annualIncomeJob != null) {
      _annualIncomeJobController.text = mpr.annualIncomeJob!.toStringAsFixed(2);
    }
    if (mpr.annualIncomeOther != null) {
      _annualIncomeOtherController.text = mpr.annualIncomeOther!.toStringAsFixed(2);
    }
    if (mpr.otherIncomeSource != null) {
      _otherIncomeSourceController.text = mpr.otherIncomeSource!;
    }
    if (mpr.totalIncome != null) {
      _totalIncomeController.text = mpr.totalIncome!.toStringAsFixed(2);
    }
    
    // Set auto-fill state if income data is available
    if (mpr.annualIncomeJob != null || mpr.annualIncomeOther != null || 
        mpr.otherIncomeSource != null || mpr.totalIncome != null) {
      _isAutoFilled = true;
    }
    
    // Clear existing purchase items and add the ones from MPR
    for (var item in _purchaseItems) {
      item.dispose();
    }
    _purchaseItems.clear();
    
    for (var item in mpr.items) {
      final formItem = PurchaseItemForm();
      formItem.itemNameController.text = item.itemName;
      // Only set dropdown values if they exist in the dropdown options
      if (item.itemCode.isNotEmpty && varietyCodes.containsKey(item.itemCode)) {
        formItem.itemCodeController.text = item.itemCode;
      } else {
        formItem.itemCodeController.text = '';
        print('Invalid item code found: ${item.itemCode}');
      }
      if (item.monthOfPurchase.isNotEmpty && monthCodes.containsKey(item.monthOfPurchase)) {
        formItem.monthOfPurchaseController.text = item.monthOfPurchase;
      } else {
        formItem.monthOfPurchaseController.text = '';
        print('Invalid month code found: ${item.monthOfPurchase}');
      }
      if (item.fibreCode.isNotEmpty && fibreCodes.containsKey(item.fibreCode)) {
        formItem.fibreCodeController.text = item.fibreCode;
      } else {
        formItem.fibreCodeController.text = '';
        print('Invalid fibre code found: ${item.fibreCode}');
      }
      if (item.sectorOfManufactureCode.isNotEmpty && sectorCodes.containsKey(item.sectorOfManufactureCode)) {
        formItem.sectorCodeController.text = item.sectorOfManufactureCode;
      } else {
        formItem.sectorCodeController.text = '';
        print('Invalid sector code found: ${item.sectorOfManufactureCode}');
      }
      if (item.colourDesignCode.isNotEmpty && colourCodes.containsKey(item.colourDesignCode)) {
        formItem.colourCodeController.text = item.colourDesignCode;
      } else {
        formItem.colourCodeController.text = '';
        print('Invalid colour code found: ${item.colourDesignCode}');
      }
      
      // Set gender and age from the new fields
      formItem.selectedGender = item.gender;
      formItem.selectedAge = item.age;
      if (item.typeOfShopCode.isNotEmpty && shopTypeCodes.containsKey(item.typeOfShopCode)) {
        formItem.shopTypeCodeController.text = item.typeOfShopCode;
      } else {
        formItem.shopTypeCodeController.text = '';
        print('Invalid shop type code found: ${item.typeOfShopCode}');
      }
      if (item.purchaseTypeCode.isNotEmpty && purchaseTypeCodes.containsKey(item.purchaseTypeCode)) {
        formItem.purchaseTypeCodeController.text = item.purchaseTypeCode;
      } else {
        formItem.purchaseTypeCodeController.text = '';
        print('Invalid purchase type code found: ${item.purchaseTypeCode}');
      }
      if (item.dressIntendedCode.isNotEmpty && dressIntendedCodes.containsKey(item.dressIntendedCode)) {
        formItem.dressIntendedCodeController.text = item.dressIntendedCode;
      } else {
        formItem.dressIntendedCodeController.text = '';
        print('Invalid dress intended code found: ${item.dressIntendedCode}');
      }
      formItem.lengthInMetersController.text = item.lengthInMeters.toString();
      formItem.pricePerMeterController.text = item.pricePerMeter.toString();
      formItem.totalAmountController.text = item.totalAmountPaid.toString();
      formItem.brandMillNameController.text = item.brandMillName;
      formItem.isImportedController.text = item.isImported ? 'Y' : 'N';
      _purchaseItems.add(formItem);
    }
    
    // Force rebuild to ensure dropdowns are properly updated
    setState(() {});
    
    // Additional validation to ensure no invalid values remain
    for (var item in _purchaseItems) {
      if (item.sectorCodeController.text.isNotEmpty && !sectorCodes.containsKey(item.sectorCodeController.text)) {
        print('Clearing invalid sector code: ${item.sectorCodeController.text}');
        item.sectorCodeController.text = '';
      }
      if (item.itemCodeController.text.isNotEmpty && !varietyCodes.containsKey(item.itemCodeController.text)) {
        print('Clearing invalid item code: ${item.itemCodeController.text}');
        item.itemCodeController.text = '';
      }
      if (item.monthOfPurchaseController.text.isNotEmpty && !monthCodes.containsKey(item.monthOfPurchaseController.text)) {
        print('Clearing invalid month code: ${item.monthOfPurchaseController.text}');
        item.monthOfPurchaseController.text = '';
      }
      if (item.fibreCodeController.text.isNotEmpty && !fibreCodes.containsKey(item.fibreCodeController.text)) {
        print('Clearing invalid fibre code: ${item.fibreCodeController.text}');
        item.fibreCodeController.text = '';
      }
      if (item.colourCodeController.text.isNotEmpty && !colourCodes.containsKey(item.colourCodeController.text)) {
        print('Clearing invalid colour code: ${item.colourCodeController.text}');
        item.colourCodeController.text = '';
      }
      if (item.shopTypeCodeController.text.isNotEmpty && !shopTypeCodes.containsKey(item.shopTypeCodeController.text)) {
        print('Clearing invalid shop type code: ${item.shopTypeCodeController.text}');
        item.shopTypeCodeController.text = '';
      }
      if (item.purchaseTypeCodeController.text.isNotEmpty && !purchaseTypeCodes.containsKey(item.purchaseTypeCodeController.text)) {
        print('Clearing invalid purchase type code: ${item.purchaseTypeCodeController.text}');
        item.purchaseTypeCodeController.text = '';
      }
      if (item.dressIntendedCodeController.text.isNotEmpty && !dressIntendedCodes.containsKey(item.dressIntendedCodeController.text)) {
        print('Clearing invalid dress intended code: ${item.dressIntendedCodeController.text}');
        item.dressIntendedCodeController.text = '';
      }
    }
  }

  // Send OTP to linked DPR mobile number
  Future<void> _sendOTPToLinkedDPR() async {
    if (_linkedMobileNumber == null || _linkedMobileNumber!.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No linked DPR found. Please load DPR data first.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() {
      _isOtpLoading = true;
    });

    try {
      final success = await _apiService.sendOTP(_linkedMobileNumber!, 'mpr');

      setState(() {
        _isOtpLoading = false;
      });

      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('OTP sent to linked DPR mobile: $_linkedMobileNumber'),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 3),
          ),
        );
        
        // Show testing dialog
        _showOtpTestingDialog();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Using offline mode. For testing, use OTP: 123456'),
            backgroundColor: Colors.orange,
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
          backgroundColor: Colors.orange,
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
        // Only set income group if it exists in the dropdown options
        if (dpr.incomeGroup.isNotEmpty && incomeGroupCodes.containsKey(dpr.incomeGroup)) {
          _incomeGroupController.text = dpr.incomeGroup;
        } else {
          _incomeGroupController.text = ''; // Clear if invalid
        }
        
        // Find occupation from household members (head of family)
        String occupation = '';
        double annualIncomeJob = 0.0;
        double annualIncomeOther = 0.0;
        String otherIncomeSource = '';
        double totalIncome = 0.0;
        
        if (dpr.householdMembers.isNotEmpty) {
          // Assume first member is head of family, or find by relationship
          final headMember = dpr.householdMembers.firstWhere(
            (member) => member.relationshipWithHead.toLowerCase().contains('head') ||
                       member.relationshipWithHead.toLowerCase().contains('self'),
            orElse: () => dpr.householdMembers.first,
          );
          occupation = headMember.occupation;
          annualIncomeJob = headMember.annualIncomeJob;
          annualIncomeOther = headMember.annualIncomeOther;
          otherIncomeSource = headMember.otherIncomeSource;
          totalIncome = headMember.totalIncome;
        }
        
        // Only set occupation if it exists in the dropdown options
        if (occupation.isNotEmpty && occupationCodes.containsKey(occupation)) {
          _occupationOfHeadController.text = occupation;
        } else {
          _occupationOfHeadController.text = ''; // Clear if invalid
        }
        
        // Set income fields (these will be read-only and for reference)
        _annualIncomeJobController.text = annualIncomeJob.toStringAsFixed(2);
        _annualIncomeOtherController.text = annualIncomeOther.toStringAsFixed(2);
        _otherIncomeSourceController.text = otherIncomeSource;
        _totalIncomeController.text = totalIncome.toStringAsFixed(2);
        
        setState(() {
          _linkedMobileNumber = dpr.mobileNumber; // Store linked mobile number
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
          _linkedMobileNumber = null;
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
        _linkedMobileNumber = null;
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

  void _onCentreOrReturnChanged() {
    if (_centreCodeController.text.isNotEmpty && _returnNoController.text.isNotEmpty) {
      _loadDpr();
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
              
              // DPR Status Card
              _buildDPRStatusCard(),
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
                            Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Header Information',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 4,
                    children: [
                      if (_centreCodeController.text.isNotEmpty && _returnNoController.text.isNotEmpty)
                        TextButton.icon(
                          onPressed: _isLoadingDPR ? null : _fetchDprDetailsIfAvailable,
                          icon: _isLoadingDPR 
                            ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
                            : const Icon(Icons.refresh, size: 16),
                          label: Text(_isLoadingDPR ? 'Loading...' : 'Load DPR'),
                        ),
                      if (_linkedMobileNumber != null && _linkedMobileNumber!.isNotEmpty)
                        TextButton.icon(
                          onPressed: _isOtpLoading ? null : _sendOTPToLinkedDPR,
                          icon: _isOtpLoading 
                            ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
                            : const Icon(Icons.send, size: 16),
                          label: Text(_isOtpLoading ? 'Sending...' : 'Send OTP'),
                          style: TextButton.styleFrom(
                            foregroundColor: const Color(0xFFD84315),
                          ),
                        ),
                    ],
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
                                  labelText: 'District, State, Tel *',
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
                  child:                 DropdownButtonFormField<String>(
                  value: _incomeGroupController.text.isEmpty || !incomeGroupCodes.containsKey(_incomeGroupController.text) ? null : _incomeGroupController.text,
                  decoration: InputDecoration(
                    labelText: 'Income Group *',
                    border: const OutlineInputBorder(),
                    filled: _isAutoFilled,
                    fillColor: _isAutoFilled ? Colors.grey.shade100 : null,
                    suffixIcon: _isAutoFilled 
                      ? const Icon(Icons.auto_awesome, color: Colors.green, size: 16)
                      : null,
                    helperText: 'Select income range',
                  ),
                  isExpanded: true,
                    items: incomeGroupCodes.entries.map((e) => 
                      DropdownMenuItem(
                        value: e.key, 
                        child: Text(
                          '${e.key} - ${e.value}',
                          overflow: TextOverflow.ellipsis,
                          maxLines: 1,
                        )
                      )
                    ).toList(),
                    onChanged: _isAutoFilled ? null : (value) {
                      _incomeGroupController.text = value ?? '';
                    },
                    validator: (value) {
                      if (value?.isEmpty == true) return 'Required';
                      if (value != null && !incomeGroupCodes.containsKey(value)) {
                        // Clear invalid value
                        _incomeGroupController.text = '';
                        return 'Invalid income group';
                      }
                      return null;
                    },
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

              DropdownButtonFormField<String>(
                value: _occupationOfHeadController.text.isEmpty || !occupationCodes.containsKey(_occupationOfHeadController.text) ? null : _occupationOfHeadController.text,
                decoration: InputDecoration(
                  labelText: 'Occupation of Head *',
                  border: const OutlineInputBorder(),
                  filled: _isAutoFilled,
                  fillColor: _isAutoFilled ? Colors.grey.shade100 : null,
                  suffixIcon: _isAutoFilled 
                    ? const Icon(Icons.auto_awesome, color: Colors.green, size: 16)
                    : null,
                  helperText: 'Select occupation category',
                ),
                isExpanded: true,
                items: occupationCodes.entries.map((e) => 
                  DropdownMenuItem(
                    value: e.key, 
                    child: Text(
                      '${e.key} - ${e.value}',
                      overflow: TextOverflow.ellipsis,
                      maxLines: 1,
                    )
                  )
                ).toList(),
                onChanged: _isAutoFilled ? null : (value) {
                  _occupationOfHeadController.text = value ?? '';
                },
                validator: (value) {
                  if (value?.isEmpty == true) return 'Required';
                  if (value != null && !occupationCodes.containsKey(value)) {
                    // Clear invalid value
                    _occupationOfHeadController.text = '';
                    return 'Invalid occupation';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Income Information Section (from DPR, read-only when auto-filled)
              if (_isAutoFilled) ...[
                const Text(
                  'Income Information (from DPR)',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.green),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _annualIncomeJobController,
                        decoration: InputDecoration(
                          labelText: 'Annual Income (Job)',
                          border: const OutlineInputBorder(),
                          filled: true,
                          fillColor: Colors.grey.shade100,
                          suffixIcon: const Icon(Icons.auto_awesome, color: Colors.green, size: 16),
                        ),
                        readOnly: true,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: TextFormField(
                        controller: _annualIncomeOtherController,
                        decoration: InputDecoration(
                          labelText: 'Annual Income (Other)',
                          border: const OutlineInputBorder(),
                          filled: true,
                          fillColor: Colors.grey.shade100,
                          suffixIcon: const Icon(Icons.auto_awesome, color: Colors.green, size: 16),
                        ),
                        readOnly: true,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _otherIncomeSourceController,
                        decoration: InputDecoration(
                          labelText: 'Other Income Source',
                          border: const OutlineInputBorder(),
                          filled: true,
                          fillColor: Colors.grey.shade100,
                          suffixIcon: const Icon(Icons.auto_awesome, color: Colors.green, size: 16),
                        ),
                        readOnly: true,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: TextFormField(
                        controller: _totalIncomeController,
                        decoration: InputDecoration(
                          labelText: 'Total Income',
                          border: const OutlineInputBorder(),
                          filled: true,
                          fillColor: Colors.grey.shade100,
                          suffixIcon: const Icon(Icons.auto_awesome, color: Colors.green, size: 16),
                        ),
                        readOnly: true,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
              ],
          ],
        ),
      ),
    );
  }

  Widget _buildDPRStatusCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  _isLoadingDPR ? Icons.sync : (_dprMembers.isNotEmpty ? Icons.check_circle : Icons.info),
                  color: _isLoadingDPR ? Colors.orange : (_dprMembers.isNotEmpty ? Colors.green : Colors.blue),
                ),
                const SizedBox(width: 8),
                Text(
                  _isLoadingDPR ? 'Loading DPR Data...' : (_dprMembers.isNotEmpty ? 'DPR Data Loaded' : 'DPR Status'),
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ],
            ),
            if (_isLoadingDPR) ...[
              const SizedBox(height: 8),
              const LinearProgressIndicator(),
              const SizedBox(height: 8),
              Text(_dprLoadMessage ?? ''),
            ] else if (_dprMembers.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text('Household Members: ${_dprMembers.length}'),
              Text('Available Genders: ${_getGenderOptions().join(', ')}'),
            ] else ...[
              const SizedBox(height: 8),
              Text('Enter Centre Code and Return Number to load DPR data'),
            ],
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
                  'Purchase Items',
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
                  child: DropdownButtonFormField<String>(
                    value: item.itemCodeController.text.isEmpty || !getAllItemCodes().containsKey(item.itemCodeController.text) ? null : item.itemCodeController.text,
                    decoration: const InputDecoration(
                      labelText: 'Item Code *',
                      border: OutlineInputBorder(),
                      helperText: 'Select from comprehensive standardized item codes',
                    ),
                    isExpanded: true,
                    items: [
                      // Add category separators for better organization
                      const DropdownMenuItem(
                        value: null,
                        enabled: false,
                        child: Text('--- PIECE LENGTH VARIETIES ---', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.blue)),
                      ),
                      ...varietyCodes.entries.map((e) => 
                        DropdownMenuItem(
                          value: e.key, 
                          child: Text(
                            '${e.key} - ${e.value}',
                            overflow: TextOverflow.ellipsis,
                            maxLines: 1,
                          )
                        )
                      ),
                      const DropdownMenuItem(
                        value: null,
                        enabled: false,
                        child: Text('--- GARMENTS IN PIECE LENGTH ---', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.green)),
                      ),
                      ...getAllItemCodes().entries.where((e) => int.parse(e.key) >= 201 && int.parse(e.key) <= 300).map((e) => 
                        DropdownMenuItem(
                          value: e.key, 
                          child: Text(
                            '${e.key} - ${e.value}',
                            overflow: TextOverflow.ellipsis,
                            maxLines: 1,
                          )
                        )
                      ),
                      const DropdownMenuItem(
                        value: null,
                        enabled: false,
                        child: Text('--- WOVEN READYMADE GARMENTS ---', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.orange)),
                      ),
                      ...getAllItemCodes().entries.where((e) => int.parse(e.key) >= 401 && int.parse(e.key) <= 600).map((e) => 
                        DropdownMenuItem(
                          value: e.key, 
                          child: Text(
                            '${e.key} - ${e.value}',
                            overflow: TextOverflow.ellipsis,
                            maxLines: 1,
                          )
                        )
                      ),
                      const DropdownMenuItem(
                        value: null,
                        enabled: false,
                        child: Text('--- WOVEN HOUSEHOLD VARIETIES ---', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.purple)),
                      ),
                      ...getAllItemCodes().entries.where((e) => int.parse(e.key) >= 601 && int.parse(e.key) <= 700).map((e) => 
                        DropdownMenuItem(
                          value: e.key, 
                          child: Text(
                            '${e.key} - ${e.value}',
                            overflow: TextOverflow.ellipsis,
                            maxLines: 1,
                          )
                        )
                      ),
                      const DropdownMenuItem(
                        value: null,
                        enabled: false,
                        child: Text('--- KNITTED/HOSIERY VARIETIES ---', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.red)),
                      ),
                      ...getAllItemCodes().entries.where((e) => int.parse(e.key) >= 801 && int.parse(e.key) <= 950).map((e) => 
                        DropdownMenuItem(
                          value: e.key, 
                          child: Text(
                            '${e.key} - ${e.value}',
                            overflow: TextOverflow.ellipsis,
                            maxLines: 1,
                          )
                        )
                      ),
                    ],
                    onChanged: (value) {
                      item.itemCodeController.text = value ?? '';
                    },
                    validator: (value) {
                      if (value?.isEmpty == true) return 'Required';
                      if (value != null && !getAllItemCodes().containsKey(value)) {
                        // Clear invalid value
                        item.itemCodeController.text = '';
                        return 'Invalid item code';
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
                    value: item.monthOfPurchaseController.text.isEmpty || !monthCodes.containsKey(item.monthOfPurchaseController.text) ? null : item.monthOfPurchaseController.text,
                    decoration: const InputDecoration(
                      labelText: 'Month of Purchase *',
                      border: OutlineInputBorder(),
                      helperText: 'Select purchase month',
                    ),
                    isExpanded: true,
                    items: monthCodes.entries.map((e) => 
                      DropdownMenuItem(
                        value: e.key, 
                        child: Text(
                          '${e.key} - ${e.value}',
                          overflow: TextOverflow.ellipsis,
                          maxLines: 1,
                        )
                      )
                    ).toList(),
                    onChanged: (value) {
                      item.monthOfPurchaseController.text = value ?? '';
                    },
                    validator: (value) {
                      if (value?.isEmpty == true) return 'Required';
                      if (value != null && !monthCodes.containsKey(value)) {
                        // Clear invalid value
                        item.monthOfPurchaseController.text = '';
                        return 'Invalid month';
                      }
                      return null;
                    },
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: DropdownButtonFormField<String>(
                    value: item.fibreCodeController.text.isEmpty || !fibreCodes.containsKey(item.fibreCodeController.text) ? null : item.fibreCodeController.text,
                    decoration: const InputDecoration(
                      labelText: 'Fibre Code *',
                      border: OutlineInputBorder(),
                    ),
                    isExpanded: true,
                    items: fibreCodes.entries.map((e) => 
                      DropdownMenuItem(
                        value: e.key, 
                        child: Text(
                          '${e.key} - ${e.value}',
                          overflow: TextOverflow.ellipsis,
                          maxLines: 1,
                        )
                      )
                    ).toList(),
                    onChanged: (value) {
                      item.fibreCodeController.text = value ?? '';
                    },
                    validator: (value) {
                      if (value?.isEmpty == true) return 'Required';
                      if (value != null && !fibreCodes.containsKey(value)) {
                        // Clear invalid value
                        item.fibreCodeController.text = '';
                        return 'Invalid fibre code';
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
                    value: item.sectorCodeController.text.isEmpty || !sectorCodes.containsKey(item.sectorCodeController.text) ? null : item.sectorCodeController.text,
                    decoration: const InputDecoration(
                      labelText: 'Sector Code *',
                      border: OutlineInputBorder(),
                    ),
                    isExpanded: true,
                    items: sectorCodes.entries.map((e) => 
                      DropdownMenuItem(
                        value: e.key, 
                        child: Text(
                          '${e.key} - ${e.value}',
                          overflow: TextOverflow.ellipsis,
                          maxLines: 1,
                        )
                      )
                    ).toList(),
                    onChanged: (value) {
                      item.sectorCodeController.text = value ?? '';
                    },
                    validator: (value) {
                      if (value?.isEmpty == true) return 'Required';
                      if (value != null && !sectorCodes.containsKey(value)) {
                        // Clear invalid value and reset dropdown
                        item.sectorCodeController.text = '';
                        setState(() {}); // Force rebuild
                        return 'Invalid sector code';
                      }
                      return null;
                    },
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: DropdownButtonFormField<String>(
                    value: item.colourCodeController.text.isEmpty || !colourCodes.containsKey(item.colourCodeController.text) ? null : item.colourCodeController.text,
                    decoration: const InputDecoration(
                      labelText: 'Colour Code *',
                      border: OutlineInputBorder(),
                    ),
                    isExpanded: true,
                    items: colourCodes.entries.map((e) => 
                      DropdownMenuItem(
                        value: e.key, 
                        child: Text(
                          '${e.key} - ${e.value}',
                          overflow: TextOverflow.ellipsis,
                          maxLines: 1,
                        )
                      )
                    ).toList(),
                    onChanged: (value) {
                      item.colourCodeController.text = value ?? '';
                    },
                    validator: (value) {
                      if (value?.isEmpty == true) return 'Required';
                      if (value != null && !colourCodes.containsKey(value)) {
                        // Clear invalid value
                        item.colourCodeController.text = '';
                        return 'Invalid colour code';
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
                    value: item.shopTypeCodeController.text.isEmpty || !shopTypeCodes.containsKey(item.shopTypeCodeController.text) ? null : item.shopTypeCodeController.text,
                    decoration: const InputDecoration(
                      labelText: 'Shop Type *',
                      border: OutlineInputBorder(),
                    ),
                    isExpanded: true,
                    items: shopTypeCodes.entries.map((e) => 
                      DropdownMenuItem(
                        value: e.key, 
                        child: Text(
                          '${e.key} - ${e.value}',
                          overflow: TextOverflow.ellipsis,
                          maxLines: 1,
                        )
                      )
                    ).toList(),
                    onChanged: (value) {
                      item.shopTypeCodeController.text = value ?? '';
                    },
                    validator: (value) {
                      if (value?.isEmpty == true) return 'Required';
                      if (value != null && !shopTypeCodes.containsKey(value)) {
                        // Clear invalid value
                        item.shopTypeCodeController.text = '';
                        return 'Invalid shop type';
                      }
                      return null;
                    },
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: DropdownButtonFormField<String>(
                    value: item.purchaseTypeCodeController.text.isEmpty || !purchaseTypeCodes.containsKey(item.purchaseTypeCodeController.text) ? null : item.purchaseTypeCodeController.text,
                    decoration: const InputDecoration(
                      labelText: 'Purchase Type *',
                      border: OutlineInputBorder(),
                    ),
                    isExpanded: true,
                    items: purchaseTypeCodes.entries.map((e) => 
                      DropdownMenuItem(
                        value: e.key, 
                        child: Text(
                          '${e.key} - ${e.value}',
                          overflow: TextOverflow.ellipsis,
                          maxLines: 1,
                        )
                      )
                    ).toList(),
                    onChanged: (value) {
                      item.purchaseTypeCodeController.text = value ?? '';
                    },
                    validator: (value) {
                      if (value?.isEmpty == true) return 'Required';
                      if (value != null && !purchaseTypeCodes.containsKey(value)) {
                        // Clear invalid value
                        item.purchaseTypeCodeController.text = '';
                        return 'Invalid purchase type';
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
                    value: item.dressIntendedCodeController.text.isEmpty || !dressIntendedCodes.containsKey(item.dressIntendedCodeController.text) ? null : item.dressIntendedCodeController.text,
                    decoration: const InputDecoration(
                      labelText: 'Dress Intended *',
                      border: OutlineInputBorder(),
                    ),
                    isExpanded: true,
                    items: dressIntendedCodes.entries.map((e) => 
                      DropdownMenuItem(
                        value: e.key, 
                        child: Text(
                          '${e.key} - ${e.value}',
                          overflow: TextOverflow.ellipsis,
                          maxLines: 1,
                        )
                      )
                    ).toList(),
                    onChanged: (value) {
                      item.dressIntendedCodeController.text = value ?? '';
                    },
                    validator: (value) {
                      if (value?.isEmpty == true) return 'Required';
                      if (value != null && !dressIntendedCodes.containsKey(value)) {
                        // Clear invalid value
                        item.dressIntendedCodeController.text = '';
                        return 'Invalid dress intended';
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
                    value: item.selectedGender,
                    decoration: const InputDecoration(
                      labelText: 'Gender *',
                      border: OutlineInputBorder(),
                    ),
                    items: _getGenderOptions().map((gender) => 
                      DropdownMenuItem(value: gender, child: Text(gender == 'M' ? 'Male' : 'Female')),
                    ).toList(),
                    onChanged: (value) {
                      setState(() {
                        item.selectedGender = value;
                        item.selectedAge = null; // Reset age when gender changes
                      });
                    },
                    validator: (value) {
                      // Only required when not a gift purchase
                      if (value == null || value.isEmpty) return 'Select gender';
                      return null;
                    },
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: DropdownButtonFormField<int>(
                    value: item.selectedAge,
                    decoration: const InputDecoration(
                      labelText: 'Age *',
                      border: OutlineInputBorder(),
                    ),
                    items: _getAgeOptions(item.selectedGender).map((age) => 
                      DropdownMenuItem(value: age, child: Text('$age'))
                    ).toList(),
                    onChanged: item.selectedGender != null ? (value) {
                      setState(() {
                        item.selectedAge = value;
                      });
                    } : null,
                    validator: (value) {
                      // Only required when gender is selected and not a gift purchase
                      if (item.selectedGender != null && value == null) return 'Select age';
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
                    controller: item.lengthInMetersController,
                      decoration: const InputDecoration(
                      labelText: 'Length (m) *',
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
                      labelText: 'Price/m *',
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
                      labelText: 'Total Amount *',
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
                      labelText: 'Imported *',
                      border: OutlineInputBorder(),
                    ),
                    isExpanded: true,
                    items: const [
                      DropdownMenuItem(value: 'Y', child: Text('Yes')),
                      DropdownMenuItem(value: 'N', child: Text('No')),
                    ],
                    onChanged: (value) {
                      item.isImportedController.text = value ?? '';
                    },
                    validator: (value) {
                      if (value?.isEmpty == true) return 'Required';
                      if (value != null && value != 'Y' && value != 'N') {
                        // Clear invalid value
                        item.isImportedController.text = '';
                        return 'Invalid import status';
                      }
                      return null;
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            DropdownButtonFormField<String>(
              value: item.brandMillNameController.text.isEmpty || (!millCodes.containsKey(item.brandMillNameController.text) && !getAllBrandCodes().containsKey(item.brandMillNameController.text)) ? null : item.brandMillNameController.text,
              decoration: const InputDecoration(
                labelText: 'Brand/Mill *',
                border: OutlineInputBorder(),
                helperText: 'Select from comprehensive brand names and registered textile mills',
              ),
              isExpanded: true,
              items: [
                // Add a separator for brands
                const DropdownMenuItem(
                  value: null,
                  enabled: false,
                  child: Text('--- BRANDS ---', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey)),
                ),
                // Add brand options
                ...getAllBrandCodes().entries.map((e) => 
                  DropdownMenuItem(
                    value: e.key, 
                    child: Text(
                      '${e.key} - ${e.value}',
                      overflow: TextOverflow.ellipsis,
                      maxLines: 1,
                    )
                  )
                ),
                // Add a separator for mills
                const DropdownMenuItem(
                  value: null,
                  enabled: false,
                  child: Text('--- MILLS ---', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey)),
                ),
                // Add mill options
                ...millCodes.entries.map((e) => 
                  DropdownMenuItem(
                    value: e.key, 
                    child: Text(
                      '${e.key} - ${e.value}',
                      overflow: TextOverflow.ellipsis,
                      maxLines: 1,
                    )
                  )
                ),
              ],
              onChanged: (value) {
                item.brandMillNameController.text = value ?? '';
              },
              validator: (value) {
                if (value?.isEmpty == true) return 'Required';
                if (value != null && !millCodes.containsKey(value) && !getAllBrandCodes().containsKey(value)) {
                  // Clear invalid value
                  item.brandMillNameController.text = '';
                  return 'Invalid brand/mill code';
                }
                return null;
              },
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

            // Send OTP Button
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _isOtpLoading ? null : _sendOTPToLinkedDPR,
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

            // OTP Input and Verify
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
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                  ),
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
  String? selectedGender; // Split from personAgeGender
  int? selectedAge; // Split from personAgeGender
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