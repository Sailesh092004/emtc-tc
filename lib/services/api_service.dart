import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/dpr.dart';
import '../models/mpr.dart';
import '../models/fp.dart';

class ApiService {
  // eMTC FastAPI backend URL - Updated to use deployed backend
  static const String _baseUrl = 'https://emtc-backend.onrender.com/api/v1';

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
          'name_and_address': dpr.nameAndAddress,
          'district': dpr.district,
          'state': dpr.state,
          'family_size': dpr.familySize,
          'income_group': dpr.incomeGroup,
          'centre_code': dpr.centreCode,
          'return_no': dpr.returnNo,
          'month_and_year': dpr.monthAndYear,
          'household_members': dpr.householdMembers.map((member) => member.toMap()).toList(),
          'latitude': dpr.latitude,
          'longitude': dpr.longitude,
          'otp_code': dpr.otpCode,
        }),
      ).timeout(const Duration(seconds: 30));

      if (response.statusCode == 200 || response.statusCode == 201) {
        print('DPR synced successfully: ${dpr.returnNo}');
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
        print('Error syncing DPR ${dpr.returnNo}: $e');
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

  // Sync MPR data to backend
  Future<bool> syncMPR(MPR mpr) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/mpr'),
        headers: _headers,
        body: jsonEncode({
          'name_and_address': mpr.nameAndAddress,
          'district_state_tel': mpr.districtStateTel,
          'panel_centre': mpr.panelCentre,
          'centre_code': mpr.centreCode,
          'return_no': mpr.returnNo,
          'family_size': mpr.familySize,
          'income_group': mpr.incomeGroup,
          'month_and_year': mpr.monthAndYear,
          'occupation_of_head': mpr.occupationOfHead,
          'items': mpr.items.map((item) => item.toMap()).toList(),
          'latitude': mpr.latitude,
          'longitude': mpr.longitude,
          'otp_code': mpr.otpCode,
        }),
      ).timeout(const Duration(seconds: 30));

      if (response.statusCode == 200 || response.statusCode == 201) {
        print('MPR synced successfully: ${mpr.returnNo}');
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
        print('Error syncing MPR ${mpr.returnNo}: $e');
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