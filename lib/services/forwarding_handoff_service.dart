import '../models/forwarding_proforma.dart';
import '../services/db_service.dart';
// import '../services/api_service.dart'; // TODO: Uncomment when implementing submission
import 'dart:convert'; // Added for jsonDecode

class ForwardingHandoffService {
  final DatabaseService _dbService;
  // TODO: Will be used for handoff submission and server communication
  // final ApiService _apiService;

  ForwardingHandoffService({
    required DatabaseService dbService,
    // required ApiService apiService, // TODO: Uncomment when implementing submission
  })  : _dbService = dbService;
        // _apiService = apiService; // TODO: Uncomment when implementing submission

  /// Build ForwardingProforma from DPR and MPR data for a specific center and period
  Future<ForwardingProforma> buildFromDprMpr({
    required String centerCode,
    required String centerName,
    required String periodId,
    required String loId,
    required String loName,
    required List<int> serialRange, // e.g., 1..20
    Map<String, dynamic>? loLocation,
  }) async {
    // 1. Build expected roster from DPR for (centerCode, serialRange)
    // TODO: Use dprMembers for panel change detection and validation
    await _dbService.getDprMembersForCenter(centerCode);
    
    // 2. For each serial, read MPR state for periodId
    final mprs = await _dbService.getMprsForPeriod(centerCode, periodId);
    
    // 3. Compute counts and populate notCollected list
    int countWithPurchase = 0;
    int countNilMpr = 0;
    final List<int> serialsNilMpr = [];
    final List<NotCollectedRow> notCollected = [];
    
    // Process each serial in the range
    for (final serial in serialRange) {
      final mprStatus = await _getMprStatusForSerial(serial, centerCode, periodId, mprs);
      
      switch (mprStatus) {
        case MprStatus.WITH_PURCHASE:
          countWithPurchase++;
          break;
        case MprStatus.NIL:
          countNilMpr++;
          serialsNilMpr.add(serial);
          break;
        case MprStatus.NOT_COLLECTED:
          // Add to notCollected list for LO to fill
          notCollected.add(NotCollectedRow(serialNo: serial));
          break;
      }
    }
    
    // Calculate derived counts
    final countCollected = countWithPurchase + countNilMpr;
    final countNotCollected = serialRange.length - countCollected;
    
    // 4. Check for panel changes by comparing DPR data
    final panelChanges = await _detectPanelChanges(centerCode, periodId);
    
    return ForwardingProforma(
      periodId: periodId,
      centerCode: centerCode,
      centerName: centerName,
      panelSize: serialRange.length,
      loId: loId,
      loName: loName,
      countCollected: countCollected,
      countNotCollected: countNotCollected,
      countWithPurchase: countWithPurchase,
      countNilMpr: countNilMpr,
      serialsNilMpr: serialsNilMpr,
      notCollected: notCollected,
      panelChanges: panelChanges,
      draftedAt: DateTime.now().toIso8601String(),
      loLocation: loLocation,
    );
  }

  /// Generate FP PDF and return file path
  Future<String> generateFpPdf(ForwardingProforma fp) async {
    // TODO: Implement PDF generation
    // - Use official layout: headings, counts, NIL serials, not-collected table, LO signature block
    throw UnimplementedError('PDF generation not yet implemented');
  }

  /// Package MPR bundle and return zip path
  Future<String> packageMprBundle({
    required String centerCode,
    required String periodId,
    required String loId,
  }) async {
    // TODO: Implement MPR bundling
    // - Create ZIP of all MPR JSON for (centerCode, periodId, loId)
    // - Include manifest.json with SHA256 for each file
    throw UnimplementedError('MPR bundling not yet implemented');
  }

  /// Submit handoff package to server
  Future<SubmitResult> submitHandoff({
    required ForwardingProforma fp,
    required String fpPdfPath,
    required String mprZipPath,
    required String manifestJsonPath, // checksums for pdf+zip
  }) async {
    // TODO: Implement handoff submission
    // - Send multipart POST to /handoff/{centerCode}/{periodId}/{loId}
    // - Include fp.json, fp.pdf, mprs.zip, manifest.json
    // - Return SubmitResult with packageId and server hashes
    throw UnimplementedError('Handoff submission not yet implemented');
  }

  /// Save FP draft locally
  Future<void> saveDraft(ForwardingProforma fp) async {
    await _dbService.saveForwardingProformaDraft(fp.toJson());
  }

  /// Retrieve FP draft from local storage
  Future<ForwardingProforma?> getDraft(String centerCode, String periodId, String loId) async {
    final draftData = await _dbService.getForwardingProformaDraft(centerCode, periodId, loId);
    if (draftData != null) {
      return ForwardingProforma.fromJson(draftData);
    }
    return null;
  }

  /// Mark FP as submitted locally after successful server response
  Future<void> markSubmittedLocally(String centerCode, String periodId, String loId, SubmitResult res) async {
    await _dbService.markForwardingProformaSubmitted(centerCode, periodId, loId, res.toJson());
  }

  /// Clean up local MPR entries after successful submission
  /// Keep immutable audit metadata (hashes, timestamps) for traceability
  Future<void> cleanupLocalMprsAfterSubmit(String centerCode, String periodId, String loId) async {
    await _dbService.cleanupLocalMprsAfterSubmit(centerCode, periodId, loId);
  }

  /// Validate FP before submission
  bool validateForSubmission(ForwardingProforma fp) {
    // Check if all NOT_COLLECTED rows have reason and date
    for (final row in fp.notCollected) {
      if (row.reason == null || row.reason!.isEmpty || row.dataCollectionDate == null) {
        return false;
      }
    }
    
    // Check if panel changes notes are provided when flags are true
    if ((fp.panelChanges.substitution || fp.panelChanges.addressChange || fp.panelChanges.familyAddDelete) &&
        (fp.panelChanges.notes == null || fp.panelChanges.notes!.isEmpty)) {
      return false;
    }
    
    return true;
  }

  /// Get bi-monthly period options
  List<String> getBiMonthlyPeriods() {
    final now = DateTime.now();
    final periods = <String>[];
    
    // Generate periods for current year and previous year
    for (int year = now.year - 1; year <= now.year + 1; year++) {
      for (int month = 1; month <= 12; month += 2) {
        final startMonth = month.toString().padLeft(2, '0');
        final endMonth = (month + 1).toString().padLeft(2, '0');
        periods.add('$year-$startMonth-$endMonth');
      }
    }
    
    return periods;
  }

  /// Get LO information from SharedPreferences or other storage
  Future<Map<String, String>> getLOInfo() async {
    // TODO: Implement LO info retrieval
    // This would typically come from user authentication or app settings
    return {
      'loId': 'LO001',
      'loName': 'Local Officer',
      'phone': '+91-9876543210',
    };
  }

  /// Get center information by center code
  Future<Map<String, String>?> getCenterInfo(String centerCode) async {
    try {
      final dprData = await _dbService.getDprForCenter(centerCode);
      if (dprData != null) {
        return {
          'centerCode': centerCode,
          'centerName': dprData['nameAndAddress'] ?? 'Unknown Center',
          'district': dprData['district'] ?? '',
          'state': dprData['state'] ?? '',
        };
      }
      return null;
    } catch (e) {
      print('Error getting center info: $e');
      return null;
    }
  }

  /// Generate a default serial range for a center
  List<int> getDefaultSerialRange(String centerCode) {
    // TODO: Implement logic to determine panel size based on center
    // For now, return a default range of 1-20
    return List.generate(20, (index) => index + 1);
  }

  /// Get MPR status for a specific serial number and period
  Future<MprStatus> _getMprStatusForSerial(int serialNo, String centerCode, String periodId, List<Map<String, dynamic>> mprs) async {
    // Look for MPR with matching return number (serial)
    final returnNo = serialNo.toString().padLeft(3, '0'); // Convert serial to return number format
    
    for (final mpr in mprs) {
      if (mpr['returnNo'] == returnNo) {
        // Check if MPR has purchase items
        final items = mpr['items'];
        if (items != null && items.isNotEmpty) {
          try {
            final itemsList = jsonDecode(items) as List;
            if (itemsList.isNotEmpty) {
              return MprStatus.WITH_PURCHASE;
            }
          } catch (e) {
            print('Error parsing MPR items: $e');
          }
        }
        // MPR exists but no items - this is a NIL MPR
        return MprStatus.NIL;
      }
    }
    
    // No MPR found for this serial - NOT_COLLECTED
    return MprStatus.NOT_COLLECTED;
  }

  /// Detect panel changes by analyzing DPR data
  Future<PanelChanges> _detectPanelChanges(String centerCode, String periodId) async {
    // TODO: Implement panel change detection logic
    // This would involve comparing DPR data across periods
    // For now, return default values
    return PanelChanges(
      substitution: false,
      addressChange: false,
      familyAddDelete: false,
      notes: null,
    );
  }
} 