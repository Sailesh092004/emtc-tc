import 'package:flutter/material.dart';
import '../models/forwarding_proforma.dart';
import '../services/forwarding_handoff_service.dart';
import '../services/db_service.dart';
import '../services/location_service.dart';
// import '../services/api_service.dart'; // TODO: Uncomment when implementing submission

class ForwardingProformaScreen extends StatefulWidget {
  const ForwardingProformaScreen({super.key});

  @override
  State<ForwardingProformaScreen> createState() => _ForwardingProformaScreenState();
}

class _ForwardingProformaScreenState extends State<ForwardingProformaScreen> {
  final _formKey = GlobalKey<FormState>();
  
  // Form controllers
  final _centerCodeController = TextEditingController();
  final _loIdController = TextEditingController();
  final _loNameController = TextEditingController();
  final _panelSizeController = TextEditingController();
  
  // State variables
  String? _selectedPeriod;
  String? _selectedCenterCode;
  String? _centerName = '';
  ForwardingProforma? _currentFP;
  bool _isLoading = false;
  bool _isDraftSaved = false;
  LocationFix? _locationFix;
  
  // Services
  late final ForwardingHandoffService _fpService;
  late final DatabaseService _dbService;
  late final LocationService _locationService;
  // TODO: Will be used for API communication when implementing submission
  // late final ApiService _apiService;
  
  // Not collected table controllers
  final List<TextEditingController> _reasonControllers = [];
  final List<TextEditingController> _dateControllers = [];
  final List<bool> _substituteRequired = [];
  
  // Panel changes
  bool _substitution = false;
  bool _addressChange = false;
  bool _familyAddDelete = false;
  final _panelChangesNotesController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _dbService = DatabaseService();
    _locationService = LocationService();
    // _apiService = ApiService(); // TODO: Uncomment when implementing submission
    _fpService = ForwardingHandoffService(
      dbService: _dbService,
    );
    _initializeForm();
    _captureLocation(); // Capture location on screen open
  }

  @override
  void dispose() {
    _centerCodeController.dispose();
    _loIdController.dispose();
    _loNameController.dispose();
    _panelSizeController.dispose();
    _panelChangesNotesController.dispose();
    
    // Dispose reason and date controllers
    for (final controller in _reasonControllers) {
      controller.dispose();
    }
    for (final controller in _dateControllers) {
      controller.dispose();
    }
    
    super.dispose();
  }

  Future<void> _initializeForm() async {
    // Load LO information
    final loInfo = await _fpService.getLOInfo();
    _loIdController.text = loInfo['loId'] ?? '';
    _loNameController.text = loInfo['loName'] ?? '';
    
    // Set default panel size
    _panelSizeController.text = '20';
    
    // Load available periods
    setState(() {});
  }

  Future<void> _loadCenterInfo() async {
    if (_centerCodeController.text.isEmpty) return;
    
    setState(() => _isLoading = true);
    
    try {
      final centerInfo = await _fpService.getCenterInfo(_centerCodeController.text);
      if (centerInfo != null) {
        setState(() {
          _centerName = centerInfo['centerName'];
          _selectedCenterCode = centerInfo['centerCode'];
        });
        
        // Check for existing draft
        await _loadExistingDraft();
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error loading center info: $e')),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _captureLocation() async {
    final fix = await _locationService.getOnce();
    if (fix != null) {
      setState(() => _locationFix = fix);
    }
  }

  Future<void> _loadExistingDraft() async {
    if (_selectedCenterCode == null || _selectedPeriod == null) return;
    
    final draft = await _fpService.getDraft(
      _selectedCenterCode!,
      _selectedPeriod!,
      _loIdController.text,
    );
    
    if (draft != null) {
      setState(() {
        _currentFP = draft;
        _isDraftSaved = true;
      });
      _populateFormFromDraft(draft);
    }
  }

  void _populateFormFromDraft(ForwardingProforma fp) {
    // Populate not collected table
    _reasonControllers.clear();
    _dateControllers.clear();
    _substituteRequired.clear();
    
    for (final row in fp.notCollected) {
      _reasonControllers.add(TextEditingController(text: row.reason));
      _dateControllers.add(TextEditingController(text: row.dataCollectionDate));
      _substituteRequired.add(row.substituteRequired ?? false);
    }
    
    // Populate panel changes
    _substitution = fp.panelChanges.substitution;
    _addressChange = fp.panelChanges.addressChange;
    _familyAddDelete = fp.panelChanges.familyAddDelete;
    _panelChangesNotesController.text = fp.panelChanges.notes ?? '';
    
    setState(() {});
  }

  Future<void> _buildForwardingProforma() async {
    if (_selectedCenterCode == null || _selectedPeriod == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select center and period')),
      );
      return;
    }
    
    setState(() => _isLoading = true);
    
    try {
      final panelSize = int.tryParse(_panelSizeController.text) ?? 20;
      final serialRange = List.generate(panelSize, (index) => index + 1);
      
      final fp = await _fpService.buildFromDprMpr(
        centerCode: _selectedCenterCode!,
        centerName: _centerName ?? 'Unknown Center',
        periodId: _selectedPeriod!,
        loId: _loIdController.text,
        loName: _loNameController.text,
        serialRange: serialRange,
        loLocation: _locationFix?.toJson(),
      );
      
      setState(() {
        _currentFP = fp;
        _isDraftSaved = false;
      });
      
      // Initialize controllers for not collected table
      _reasonControllers.clear();
      _dateControllers.clear();
      _substituteRequired.clear();
      
             for (int i = 0; i < fp.notCollected.length; i++) {
         _reasonControllers.add(TextEditingController());
         _dateControllers.add(TextEditingController());
         _substituteRequired.add(false);
       }
      
      setState(() {});
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Forwarding Proforma built successfully')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error building FP: $e')),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _saveDraft() async {
    if (_currentFP == null) return;
    
    try {
      // Update FP with current form data
      final updatedFP = _currentFP!.copyWith(
        notCollected: _buildNotCollectedList(),
        panelChanges: PanelChanges(
          substitution: _substitution,
          addressChange: _addressChange,
          familyAddDelete: _familyAddDelete,
          notes: _panelChangesNotesController.text.isEmpty ? null : _panelChangesNotesController.text,
        ),
      );
      
      await _fpService.saveDraft(updatedFP);
      
      setState(() => _isDraftSaved = true);
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Draft saved successfully')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error saving draft: $e')),
      );
    }
  }

  List<NotCollectedRow> _buildNotCollectedList() {
    final List<NotCollectedRow> notCollected = [];
    
    for (int i = 0; i < _reasonControllers.length; i++) {
      notCollected.add(NotCollectedRow(
        serialNo: _currentFP!.notCollected[i].serialNo,
        reason: _reasonControllers[i].text.isEmpty ? null : _reasonControllers[i].text,
        dataCollectionDate: _dateControllers[i].text.isEmpty ? null : _dateControllers[i].text,
        substituteRequired: _substituteRequired[i],
      ));
    }
    
    return notCollected;
  }

  bool _canSubmit() {
    if (_currentFP == null) return false;
    
    // Check if all NOT_COLLECTED rows have reason and date
    for (int i = 0; i < _reasonControllers.length; i++) {
      if (_reasonControllers[i].text.isEmpty || _dateControllers[i].text.isEmpty) {
        return false;
      }
    }
    
    // Check if panel changes notes are provided when flags are true
    if ((_substitution || _addressChange || _familyAddDelete) &&
        _panelChangesNotesController.text.isEmpty) {
      return false;
    }
    
    return true;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Forwarding Proforma'),
        backgroundColor: Colors.blue[800],
        foregroundColor: Colors.white,
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeaderSection(),
              const SizedBox(height: 24),
              if (_currentFP != null) ...[
                _buildKPISection(),
                const SizedBox(height: 24),
                _buildNotCollectedSection(),
                const SizedBox(height: 24),
                _buildPanelChangesSection(),
                const SizedBox(height: 24),
                _buildActionButtons(),
              ],
            ],
          ),
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
            const Text(
              'Period & Center Selection',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            
            // Period selector
            DropdownButtonFormField<String>(
              value: _selectedPeriod,
              decoration: const InputDecoration(
                labelText: 'Period *',
                border: OutlineInputBorder(),
                helperText: 'Select bi-monthly period',
              ),
              items: _fpService.getBiMonthlyPeriods().map((period) => 
                DropdownMenuItem(value: period, child: Text(period))
              ).toList(),
              onChanged: (value) {
                setState(() {
                  _selectedPeriod = value;
                  _isDraftSaved = false;
                });
                if (value != null) _loadExistingDraft();
              },
              validator: (value) => value == null ? 'Required' : null,
            ),
            const SizedBox(height: 16),
            
            // Center code input
            TextFormField(
              controller: _centerCodeController,
              decoration: const InputDecoration(
                labelText: 'Center Code *',
                border: OutlineInputBorder(),
                helperText: 'Enter the center code',
              ),
              onChanged: (value) {
                if (value.isNotEmpty) _loadCenterInfo();
              },
              validator: (value) => value?.isEmpty == true ? 'Required' : null,
            ),
            const SizedBox(height: 16),
            
            // Center name display
            if (_centerName!.isNotEmpty)
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.location_on, color: Colors.blue),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Center: $_centerName',
                        style: const TextStyle(fontWeight: FontWeight.w500),
                      ),
                    ),
                  ],
                ),
              ),
            const SizedBox(height: 16),
            
            // Location capture
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (_locationFix != null) 
                  Container(
                    width: double.infinity,
                    child: Chip(
                      label: Text(
                        'Location: ${_locationFix!.latitude.toStringAsFixed(5)}, '
                        '${_locationFix!.longitude.toStringAsFixed(5)} @ '
                        '${_locationFix!.timestamp.hour.toString().padLeft(2, '0')}:'
                        '${_locationFix!.timestamp.minute.toString().padLeft(2, '0')}',
                      ),
                      avatar: const Icon(Icons.gps_fixed, size: 18),
                    ),
                  ),
                const SizedBox(height: 8),
                SizedBox(
                  width: double.infinity,
                  child: TextButton.icon(
                    onPressed: _captureLocation,
                    icon: const Icon(Icons.my_location),
                    label: const Text('Capture location'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            
            // LO information
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _loIdController,
                    decoration: const InputDecoration(
                      labelText: 'LO ID *',
                      border: OutlineInputBorder(),
                    ),
                    validator: (value) => value?.isEmpty == true ? 'Required' : null,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: TextFormField(
                    controller: _loNameController,
                    decoration: const InputDecoration(
                      labelText: 'LO Name *',
                      border: OutlineInputBorder(),
                    ),
                    validator: (value) => value?.isEmpty == true ? 'Required' : null,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            
            // Panel size
            TextFormField(
              controller: _panelSizeController,
              decoration: const InputDecoration(
                labelText: 'Panel Size *',
                border: OutlineInputBorder(),
                helperText: 'Number of households in the panel',
              ),
              keyboardType: TextInputType.number,
              validator: (value) {
                if (value?.isEmpty == true) return 'Required';
                final size = int.tryParse(value!);
                if (size == null || size <= 0) return 'Must be a positive number';
                return null;
              },
            ),
            const SizedBox(height: 16),
            
            // Build FP button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _isLoading ? null : _buildForwardingProforma,
                icon: _isLoading 
                  ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
                  : const Icon(Icons.build),
                label: Text(_isLoading ? 'Building...' : 'Build Forwarding Proforma'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue[600],
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildKPISection() {
    if (_currentFP == null) return const SizedBox.shrink();
    
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Key Performance Indicators',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            
            Row(
              children: [
                Expanded(
                  child: _buildKPITile(
                    'Collected',
                    '${_currentFP!.countCollected}',
                    Colors.green,
                    Icons.check_circle,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _buildKPITile(
                    'Not Collected',
                    '${_currentFP!.countNotCollected}',
                    Colors.orange,
                    Icons.pending,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: _buildKPITile(
                    'With Purchase',
                    '${_currentFP!.countWithPurchase}',
                    Colors.blue,
                    Icons.shopping_cart,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _buildKPITile(
                    'NIL MPRs',
                    '${_currentFP!.countNilMpr}',
                    Colors.grey,
                    Icons.remove_circle,
                  ),
                ),
              ],
            ),
            
            if (_currentFP!.serialsNilMpr.isNotEmpty) ...[
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'NIL Serial Numbers:',
                      style: TextStyle(fontWeight: FontWeight.w500),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      children: _currentFP!.serialsNilMpr.map((serial) => 
                        Chip(
                          label: Text('$serial'),
                          backgroundColor: Colors.grey[300],
                        )
                      ).toList(),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildKPITile(String title, String value, Color color, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 32),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          Text(
            title,
            style: TextStyle(
              color: color.withOpacity(0.8),
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNotCollectedSection() {
    if (_currentFP == null || _currentFP!.notCollected.isEmpty) {
      return const SizedBox.shrink();
    }
    
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Not Collected - Data Collection Details',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            
            // Table header
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: Colors.grey[200],
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(8),
                  topRight: Radius.circular(8),
                ),
              ),
              child: const Row(
                children: [
                  Expanded(flex: 1, child: Text('Serial', style: TextStyle(fontWeight: FontWeight.bold))),
                  Expanded(flex: 3, child: Text('Reason', style: TextStyle(fontWeight: FontWeight.bold))),
                  Expanded(flex: 2, child: Text('Date', style: TextStyle(fontWeight: FontWeight.bold))),
                  Expanded(flex: 2, child: Text('Substitute?', style: TextStyle(fontWeight: FontWeight.bold))),
                ],
              ),
            ),
            
            // Table rows
            ...List.generate(_currentFP!.notCollected.length, (index) {
              return Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  border: Border(
                    bottom: BorderSide(color: Colors.grey[300]!),
                  ),
                ),
                child: Row(
                  children: [
                    Expanded(
                      flex: 1,
                      child: Text('${_currentFP!.notCollected[index].serialNo}'),
                    ),
                    Expanded(
                      flex: 3,
                      child: TextFormField(
                        controller: _reasonControllers[index],
                        decoration: const InputDecoration(
                          hintText: 'Enter reason',
                          border: InputBorder.none,
                          isDense: true,
                        ),
                        validator: (value) => value?.isEmpty == true ? 'Required' : null,
                      ),
                    ),
                    Expanded(
                      flex: 2,
                      child: TextFormField(
                        controller: _dateControllers[index],
                        decoration: const InputDecoration(
                          hintText: 'DD/MM/YYYY',
                          border: InputBorder.none,
                          isDense: true,
                        ),
                        validator: (value) => value?.isEmpty == true ? 'Required' : null,
                      ),
                    ),
                    Expanded(
                      flex: 2,
                      child: Checkbox(
                        value: _substituteRequired[index],
                        onChanged: (value) {
                          setState(() {
                            _substituteRequired[index] = value ?? false;
                          });
                        },
                      ),
                    ),
                  ],
                ),
              );
            }),
          ],
        ),
      ),
    );
  }

  Widget _buildPanelChangesSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Panel Changes',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            
            CheckboxListTile(
              title: const Text('Substitution'),
              value: _substitution,
              onChanged: (value) {
                setState(() {
                  _substitution = value ?? false;
                });
              },
            ),
            CheckboxListTile(
              title: const Text('Address Change'),
              value: _addressChange,
              onChanged: (value) {
                setState(() {
                  _addressChange = value ?? false;
                });
              },
            ),
            CheckboxListTile(
              title: const Text('Family Add/Delete'),
              value: _familyAddDelete,
              onChanged: (value) {
                setState(() {
                  _familyAddDelete = value ?? false;
                });
              },
            ),
            
            if (_substitution || _addressChange || _familyAddDelete) ...[
              const SizedBox(height: 16),
              TextFormField(
                controller: _panelChangesNotesController,
                decoration: const InputDecoration(
                  labelText: 'Change Details *',
                  border: OutlineInputBorder(),
                  helperText: 'Describe the changes in detail',
                ),
                maxLines: 3,
                validator: (value) {
                  if ((_substitution || _addressChange || _familyAddDelete) &&
                      (value == null || value.isEmpty)) {
                    return 'Required when changes are selected';
                  }
                  return null;
                },
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildActionButtons() {
    return Row(
      children: [
        Expanded(
          child: ElevatedButton.icon(
            onPressed: _currentFP == null ? null : _saveDraft,
            icon: const Icon(Icons.save),
            label: Text(_isDraftSaved ? 'Draft Saved' : 'Save Draft'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.grey[600],
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
            ),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: ElevatedButton.icon(
            onPressed: _currentFP == null ? null : () {
              // TODO: Implement PDF generation
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('PDF generation coming soon')),
              );
            },
            icon: const Icon(Icons.picture_as_pdf),
            label: const Text('Generate FP PDF'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.orange[600],
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
            ),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: ElevatedButton.icon(
            onPressed: _currentFP == null || !_canSubmit() ? null : () {
              // TODO: Implement submission
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Submission coming soon')),
              );
            },
            icon: const Icon(Icons.send),
            label: const Text('Submit Period'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green[600],
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
            ),
          ),
        ),
      ],
    );
  }
} 