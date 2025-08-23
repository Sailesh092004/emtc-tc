import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'api_service.dart';
import 'db_service.dart';
import '../models/dpr.dart';
import '../models/mpr.dart';


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

      // Get unsynced DPR and MPR records
      final unsyncedDPR = await _dbService.getUnsyncedDPR();
      final unsyncedMPR = await _dbService.getUnsyncedMPR();
      _pendingRecords = unsyncedDPR.length + unsyncedMPR.length;

      if (unsyncedDPR.isEmpty && unsyncedMPR.isEmpty) {
        _lastSyncStatus = 'no_data';
        _lastSyncTime = DateTime.now();
        notifyListeners();
        return;
      }

      print('Syncing ${unsyncedDPR.length} DPR and ${unsyncedMPR.length} MPR records...');

      // Sync DPR records
      bool dprSuccess = true;
      if (unsyncedDPR.isNotEmpty) {
        // Separate new records from updated records
        List<DPR> newDPR = [];
        List<DPR> updatedDPR = [];
        
        for (DPR dpr in unsyncedDPR) {
          // If the record has a backend ID, it's an update; otherwise it's new
          if (dpr.backendId != null) {
            updatedDPR.add(dpr);
          } else {
            newDPR.add(dpr);
          }
        }
        
        // Sync new DPR records
        if (newDPR.isNotEmpty) {
          final dprSyncResult = await _apiService.syncMultipleDPR(newDPR);
          if (dprSyncResult['success']) {
            // Mark all synced DPR records as synced
            for (DPR dpr in newDPR) {
              if (dpr.id != null) {
                await _dbService.updateDPRSyncStatus(dpr.id!, true);
              }
            }
            print('Successfully synced ${dprSyncResult['synced']} new DPR records');
          } else {
            dprSuccess = false;
            print('New DPR sync failed: ${dprSyncResult['failed']} records failed');
          }
        }
        
        // Update existing DPR records
        if (updatedDPR.isNotEmpty) {
          int updatedCount = 0;
          int failedCount = 0;
          
          for (DPR dpr in updatedDPR) {
            try {
              final success = await _apiService.updateDPR(dpr);
              if (success) {
                await _dbService.updateDPRSyncStatus(dpr.id!, true);
                updatedCount++;
              } else {
                failedCount++;
              }
            } catch (e) {
              print('Error updating DPR ${dpr.returnNo}: $e');
              failedCount++;
            }
          }
          
          if (failedCount == 0) {
            print('Successfully updated $updatedCount DPR records');
          } else {
            dprSuccess = false;
            print('DPR update failed: $failedCount records failed');
          }
        }
      }

      // Sync MPR records
      bool mprSuccess = true;
      if (unsyncedMPR.isNotEmpty) {
        // Separate new records from updated records
        List<MPR> newMPR = [];
        List<MPR> updatedMPR = [];
        
        for (MPR mpr in unsyncedMPR) {
          // If the record has a backend ID, it's an update; otherwise it's new
          if (mpr.backendId != null) {
            updatedMPR.add(mpr);
          } else {
            newMPR.add(mpr);
          }
        }
        
        // Sync new MPR records
        if (newMPR.isNotEmpty) {
          final mprSyncResult = await _apiService.syncMultipleMPR(newMPR);
          if (mprSyncResult['success']) {
            // Mark all synced MPR records as synced
            for (MPR mpr in newMPR) {
              if (mpr.id != null) {
                await _dbService.updateMPRSyncStatus(mpr.id!, true);
              }
            }
            print('Successfully synced ${mprSyncResult['synced']} new MPR records');
          } else {
            mprSuccess = false;
            print('New MPR sync failed: ${mprSyncResult['failed']} records failed');
          }
        }
        
        // Update existing MPR records
        if (updatedMPR.isNotEmpty) {
          int updatedCount = 0;
          int failedCount = 0;
          
          for (MPR mpr in updatedMPR) {
            try {
              final success = await _apiService.updateMPR(mpr);
              if (success) {
                await _dbService.updateMPRSyncStatus(mpr.id!, true);
                updatedCount++;
              } else {
                failedCount++;
              }
            } catch (e) {
              print('Error updating MPR ${mpr.returnNo}: $e');
              failedCount++;
            }
          }
          
          if (failedCount == 0) {
            print('Successfully updated $updatedCount MPR records');
          } else {
            mprSuccess = false;
            print('MPR update failed: $failedCount records failed');
          }
        }
      }

      if (dprSuccess && mprSuccess) {
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
      _pendingRecords = unsyncedDprCount + unsyncedMprCount;

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
      
      bool dprSuccess = true;
      bool mprSuccess = true;

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

      if (dprSuccess && mprSuccess) {
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
      _pendingRecords = unsyncedDprCount + unsyncedMprCount;

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
    _pendingRecords = unsyncedDprCount + unsyncedMprCount;
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