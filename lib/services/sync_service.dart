import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'api_service.dart';
import 'db_service.dart';
import '../models/dpr.dart';
import '../models/mpr.dart';
import '../models/fp.dart';

class SyncService extends ChangeNotifier {
  final DatabaseService _dbService;
  final ApiService _apiService = ApiService();
  
  bool _isOnline = false;
  bool _isSyncing = false;
  StreamSubscription? _connectivitySubscription;
  Timer? _syncTimer;
  
  // Sync status
  int _pendingRecords = 0;
  DateTime? _lastSyncTime;
  String _lastSyncStatus = 'idle';

  SyncService(this._dbService) {
    _initializeConnectivityMonitoring();
    _startPeriodicSync();
  }

  // Getters
  bool get isOnline => _isOnline;
  bool get isSyncing => _isSyncing;
  int get pendingRecords => _pendingRecords;
  DateTime? get lastSyncTime => _lastSyncTime;
  String get lastSyncStatus => _lastSyncStatus;

  // Initialize connectivity monitoring
  void _initializeConnectivityMonitoring() {
    _connectivitySubscription = Connectivity()
        .onConnectivityChanged
        .listen(_onConnectivityChanged);
    
    // Check initial connectivity
    _checkInitialConnectivity();
  }

  Future<void> _checkInitialConnectivity() async {
    final connectivityResult = await Connectivity().checkConnectivity();
    _updateConnectivityStatus(connectivityResult != ConnectivityResult.none);
  }

  void _onConnectivityChanged(ConnectivityResult result) {
    final isOnline = result != ConnectivityResult.none;
    _updateConnectivityStatus(isOnline);
  }

  void _updateConnectivityStatus(bool isOnline) {
    if (_isOnline != isOnline) {
      _isOnline = isOnline;
      notifyListeners();
      
      if (isOnline) {
        _onInternetRestored();
      } else {
        _onInternetLost();
      }
    }
  }

  void _onInternetRestored() {
    print('Internet connection restored');
    _syncPendingData();
  }

  void _onInternetLost() {
    print('Internet connection lost');
    _lastSyncStatus = 'offline';
    notifyListeners();
  }

  // Start periodic sync check
  void _startPeriodicSync() {
    _syncTimer = Timer.periodic(const Duration(minutes: 5), (timer) {
      if (_isOnline && !_isSyncing) {
        _syncPendingData();
      }
    });
  }

  // Manual sync trigger
  Future<void> manualSync() async {
    if (_isOnline && !_isSyncing) {
      await _syncPendingData();
    }
  }

  // Sync pending data
  Future<void> _syncPendingData() async {
    if (_isSyncing) return;

    try {
      _isSyncing = true;
      _lastSyncStatus = 'syncing';
      notifyListeners();

      // Get unsynced DPR, MPR, and FP records
      final unsyncedDPR = await _dbService.getUnsyncedDPR();
      final unsyncedMPR = await _dbService.getUnsyncedMPR();
      final unsyncedFP = await _dbService.getUnsyncedFP();
      _pendingRecords = unsyncedDPR.length + unsyncedMPR.length + unsyncedFP.length;

      if (unsyncedDPR.isEmpty && unsyncedMPR.isEmpty && unsyncedFP.isEmpty) {
        _lastSyncStatus = 'no_data';
        _lastSyncTime = DateTime.now();
        notifyListeners();
        return;
      }

      print('Syncing ${unsyncedDPR.length} DPR, ${unsyncedMPR.length} MPR, and ${unsyncedFP.length} FP records...');

      // Sync DPR records
      bool dprSuccess = true;
      if (unsyncedDPR.isNotEmpty) {
        final dprSyncResult = await _apiService.syncMultipleDPR(unsyncedDPR);
        if (dprSyncResult['success']) {
          // Mark all synced DPR records as synced
          for (DPR dpr in unsyncedDPR) {
            if (dpr.id != null) {
              await _dbService.updateDPRSyncStatus(dpr.id!, true);
            }
          }
          print('Successfully synced ${dprSyncResult['synced']} DPR records');
        } else {
          dprSuccess = false;
          print('DPR sync failed: ${dprSyncResult['failed']} records failed');
        }
      }

      // Sync MPR records
      bool mprSuccess = true;
      if (unsyncedMPR.isNotEmpty) {
        final mprSyncResult = await _apiService.syncMultipleMPR(unsyncedMPR);
        if (mprSyncResult['success']) {
          // Mark all synced MPR records as synced
          for (MPR mpr in unsyncedMPR) {
            if (mpr.id != null) {
              await _dbService.updateMPRSyncStatus(mpr.id!, true);
            }
          }
          print('Successfully synced ${mprSyncResult['synced']} MPR records');
        } else {
          mprSuccess = false;
          print('MPR sync failed: ${mprSyncResult['failed']} records failed');
        }
      }

      // Sync FP records
      bool fpSuccess = true;
      if (unsyncedFP.isNotEmpty) {
        final fpSyncResult = await _apiService.syncMultipleFP(unsyncedFP);
        if (fpSyncResult['success']) {
          for (FP fp in unsyncedFP) {
            if (fp.id != null) {
              await _dbService.updateFPSyncStatus(fp.id!, true);
            }
          }
          print('Successfully synced ${fpSyncResult['synced']} FP records');
        } else {
          fpSuccess = false;
          print('FP sync failed: ${fpSyncResult['failed']} records failed');
        }
      }

      if (dprSuccess && mprSuccess && fpSuccess) {
        _lastSyncStatus = 'success';
        _lastSyncTime = DateTime.now();
        // Save last sync time to SharedPreferences
        final prefs = await SharedPreferences.getInstance();
        await prefs.setInt('last_sync_timestamp', _lastSyncTime!.millisecondsSinceEpoch);
      } else {
        _lastSyncStatus = 'failed';
      }

      // Update pending records count
      final unsyncedDprCount = await _dbService.getUnsyncedDPRCount();
      final unsyncedMprCount = await _dbService.getUnsyncedMPRCount();
      final unsyncedFpCount = await _dbService.getUnsyncedFPCount();
      _pendingRecords = unsyncedDprCount + unsyncedMprCount + unsyncedFpCount;

    } catch (e) {
      print('Error during sync: $e');
      _lastSyncStatus = 'error';
    } finally {
      _isSyncing = false;
      notifyListeners();
    }
  }

  // Check sync status
  Future<Map<String, dynamic>> getSyncStatus() async {
    final stats = await _dbService.getDatabaseStats();
    final apiStatus = await _apiService.getSyncStatus();

    return {
      'isOnline': _isOnline,
      'isSyncing': _isSyncing,
      'pendingRecords': stats['unsyncedDPR'] ?? 0,
      'totalRecords': stats['totalDPR'] ?? 0,
      'lastSyncTime': _lastSyncTime?.toIso8601String(),
      'lastSyncStatus': _lastSyncStatus,
      'apiStatus': apiStatus,
    };
  }

  // Force sync all data
  Future<void> forceSyncAll() async {
    if (_isSyncing) return;

    try {
      _isSyncing = true;
      _lastSyncStatus = 'force_syncing';
      notifyListeners();

      final allDPR = await _dbService.getAllDPR();
      final allMPR = await _dbService.getAllMPR();
      final allFP = await _dbService.getAllFP();
      
      bool dprSuccess = true;
      bool mprSuccess = true;
      bool fpSuccess = true;

      if (allDPR.isNotEmpty) {
        final dprSyncResult = await _apiService.syncMultipleDPR(allDPR);
        if (dprSyncResult['success']) {
          // Mark all DPR records as synced
          for (DPR dpr in allDPR) {
            if (dpr.id != null) {
              await _dbService.updateDPRSyncStatus(dpr.id!, true);
            }
          }
        } else {
          dprSuccess = false;
        }
      }

      if (allMPR.isNotEmpty) {
        final mprSyncResult = await _apiService.syncMultipleMPR(allMPR);
        if (mprSyncResult['success']) {
          // Mark all MPR records as synced
          for (MPR mpr in allMPR) {
            if (mpr.id != null) {
              await _dbService.updateMPRSyncStatus(mpr.id!, true);
            }
          }
        } else {
          mprSuccess = false;
        }
      }

      if (allFP.isNotEmpty) {
        final fpSyncResult = await _apiService.syncMultipleFP(allFP);
        if (fpSyncResult['success']) {
          // Mark all FP records as synced
          for (FP fp in allFP) {
            if (fp.id != null) {
              await _dbService.updateFPSyncStatus(fp.id!, true);
            }
          }
        } else {
          fpSuccess = false;
        }
      }

      if (dprSuccess && mprSuccess && fpSuccess) {
        _lastSyncStatus = 'force_success';
        _lastSyncTime = DateTime.now();
        // Save last sync time to SharedPreferences
        final prefs = await SharedPreferences.getInstance();
        await prefs.setInt('last_sync_timestamp', _lastSyncTime!.millisecondsSinceEpoch);
      } else {
        _lastSyncStatus = 'force_failed';
      }

      final unsyncedDprCount = await _dbService.getUnsyncedDPRCount();
      final unsyncedMprCount = await _dbService.getUnsyncedMPRCount();
      final unsyncedFpCount = await _dbService.getUnsyncedFPCount();
      _pendingRecords = unsyncedDprCount + unsyncedMprCount + unsyncedFpCount;

    } catch (e) {
      print('Error during force sync: $e');
      _lastSyncStatus = 'force_error';
    } finally {
      _isSyncing = false;
      notifyListeners();
    }
  }

  // Update pending records count
  Future<void> updatePendingCount() async {
    final unsyncedDprCount = await _dbService.getUnsyncedDPRCount();
    final unsyncedMprCount = await _dbService.getUnsyncedMPRCount();
    final unsyncedFpCount = await _dbService.getUnsyncedFPCount();
    _pendingRecords = unsyncedDprCount + unsyncedMprCount + unsyncedFpCount;
    notifyListeners();
  }

  // Dispose resources
  @override
  void dispose() {
    _connectivitySubscription?.cancel();
    _syncTimer?.cancel();
    super.dispose();
  }
} 