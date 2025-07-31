import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/dpr.dart';
import '../models/mpr.dart';
import '../models/fp.dart';

class ApiService {
  // eMTC FastAPI backend URL - update this to your actual backend URL
  static const String _baseUrl = 'http://localhost:8000/api/v1';
  
  // For local development
  static const String _localUrl = 'http://10.0.2.2:8000/api/v1'; // Android emulator
  static const String _mockUrl = 'https://httpbin.org/post'; // Fallback

  // Headers for API requests
  static const Map<String, String> _headers = {
    'Content-Type': 'application/json',
    'Accept': 'application/json',
  };

  // Sync DPR data to backend
  Future<bool> syncDPR(DPR dpr) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/dpr'),
        headers: _headers,
        body: jsonEncode({
          'household_id': dpr.householdId,
          'respondent_name': dpr.householdHeadName,
          'age': 35, // Default age - you might want to add this field to DPR model
          'gender': 'Not Specified', // Default gender
          'education': 'Not Specified', // Default education
          'occupation': 'Not Specified', // Default occupation
          'income_level': dpr.monthlyIncome.toString(),
          'latitude': dpr.latitude,
          'longitude': dpr.longitude,
        }),
      ).timeout(const Duration(seconds: 30));

      if (response.statusCode == 200 || response.statusCode == 201) {
        print('DPR synced successfully: ${dpr.householdId}');
        return true;
      } else {
        print('Failed to sync DPR: ${response.statusCode} - ${response.body}');
        return false;
      }
    } catch (e) {
      print('Error syncing DPR: $e');
      return false;
    }
  }

  // Sync multiple DPR records
  Future<Map<String, dynamic>> syncMultipleDPR(List<DPR> dprList) async {
    if (dprList.isEmpty) {
      return {'success': true, 'synced': 0, 'failed': 0};
    }

    int synced = 0;
    int failed = 0;

    for (DPR dpr in dprList) {
      try {
        final success = await syncDPR(dpr);
        if (success) {
          synced++;
        } else {
          failed++;
        }
      } catch (e) {
        print('Error syncing DPR ${dpr.householdId}: $e');
        failed++;
      }
    }

    return {
      'success': failed == 0,
      'synced': synced,
      'failed': failed,
    };
  }

  // Verify OTP with backend (mock implementation)
  Future<bool> verifyOTP(String phoneNumber, String otpCode) async {
    try {
      // Simulate API call delay
      await Future.delayed(const Duration(seconds: 1));
      
      // Mock verification - in real app, this would call actual backend
      return otpCode == '123456'; // Mock OTP for testing
    } catch (e) {
      print('Error verifying OTP: $e');
      return false;
    }
  }

  // Upload signature image to backend
  Future<String?> uploadSignature(String signaturePath) async {
    try {
      // In a real implementation, this would upload the image file
      // For now, we'll just return the local path
      return signaturePath;
    } catch (e) {
      print('Error uploading signature: $e');
      return null;
    }
  }

  // Check API connectivity
  Future<bool> checkApiConnectivity() async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/ping'),
        headers: _headers,
      ).timeout(const Duration(seconds: 10));

      return response.statusCode == 200;
    } catch (e) {
      print('API connectivity check failed: $e');
      return false;
    }
  }

  // Get device ID (mock implementation)
  Future<String> _getDeviceId() async {
    // In a real app, this would get the actual device ID
    return 'device_${DateTime.now().millisecondsSinceEpoch}';
  }

  // Sync MPR data to backend
  Future<bool> syncMPR(MPR mpr) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/mpr'),
        headers: _headers,
        body: jsonEncode({
          'household_id': mpr.householdId,
          'purchase_date': mpr.purchaseDate.toIso8601String().split('T')[0], // Format as YYYY-MM-DD
          'textile_type': mpr.textileType,
          'quantity': mpr.quantity,
          'price': mpr.price,
          'purchase_location': mpr.purchaseLocation,
          'latitude': mpr.latitude,
          'longitude': mpr.longitude,
        }),
      ).timeout(const Duration(seconds: 30));

      if (response.statusCode == 200 || response.statusCode == 201) {
        print('MPR synced successfully: ${mpr.householdId}');
        return true;
      } else {
        print('Failed to sync MPR: ${response.statusCode} - ${response.body}');
        return false;
      }
    } catch (e) {
      print('Error syncing MPR: $e');
      return false;
    }
  }

  // Sync multiple MPR records
  Future<Map<String, dynamic>> syncMultipleMPR(List<MPR> mprList) async {
    if (mprList.isEmpty) {
      return {'success': true, 'synced': 0, 'failed': 0};
    }

    int synced = 0;
    int failed = 0;

    for (MPR mpr in mprList) {
      try {
        final success = await syncMPR(mpr);
        if (success) {
          synced++;
        } else {
          failed++;
        }
      } catch (e) {
        print('Error syncing MPR ${mpr.householdId}: $e');
        failed++;
      }
    }

    return {
      'success': failed == 0,
      'synced': synced,
      'failed': failed,
    };
  }

  // Sync FP data to backend
  Future<bool> syncFP(FP fp) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/fp'),
        headers: _headers,
        body: jsonEncode({
          'centre_name': fp.centreName,
          'centre_code': fp.centreCode,
          'panel_size': fp.panelSize,
          'mpr_collected': fp.mprCollected,
          'not_collected': fp.notCollected,
          'with_purchase_data': fp.withPurchaseData,
          'nil_mprs': fp.nilMPRs,
          'nil_serial_nos': fp.nilSerialNos,
          'latitude': fp.latitude,
          'longitude': fp.longitude,
        }),
      ).timeout(const Duration(seconds: 30));

      if (response.statusCode == 200 || response.statusCode == 201) {
        print('FP synced successfully: ${fp.centreCode}');
        return true;
      } else {
        print('Failed to sync FP: ${response.statusCode} - ${response.body}');
        return false;
    }
    } catch (e) {
      print('Error syncing FP: $e');
      return false;
    }
  }

  // Sync multiple FP records
  Future<Map<String, dynamic>> syncMultipleFP(List<FP> fpList) async {
    if (fpList.isEmpty) {
      return {'success': true, 'synced': 0, 'failed': 0};
    }

    int synced = 0;
    int failed = 0;

    for (FP fp in fpList) {
      try {
        final success = await syncFP(fp);
        if (success) {
          synced++;
        } else {
          failed++;
        }
      } catch (e) {
        print('Error syncing FP ${fp.centreCode}: $e');
        failed++;
      }
    }

    return {
      'success': failed == 0,
      'synced': synced,
      'failed': failed,
    };
  }

  // Get sync status from backend
  Future<Map<String, dynamic>> getSyncStatus() async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/stats'),
        headers: _headers,
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return {
          'status': 'connected',
          'lastSync': DateTime.now().toIso8601String(),
          'pendingRecords': 0,
          'stats': data['data'],
        };
      } else {
        return {
          'status': 'disconnected',
          'lastSync': null,
          'pendingRecords': 0,
        };
      }
    } catch (e) {
      return {
        'status': 'error',
        'lastSync': null,
        'pendingRecords': 0,
        'error': e.toString(),
      };
    }
  }
} 