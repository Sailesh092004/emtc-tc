import 'dart:io';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';
import '../models/dpr.dart';
import '../models/mpr.dart';
import '../models/fp.dart';

class DatabaseService extends ChangeNotifier {
  static Database? _database;
  static const String _databaseName = 'mtc_nanna.db';
  static const int _databaseVersion = 5; // Increment version for lo_phone column

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    Directory documentsDirectory = await getApplicationDocumentsDirectory();
    String path = join(documentsDirectory.path, _databaseName);
    
    return await openDatabase(
      path,
      version: _databaseVersion,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    // DPR table - Updated structure
    await db.execute('''
      CREATE TABLE dpr (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        nameAndAddress TEXT NOT NULL,
        district TEXT NOT NULL,
        state TEXT NOT NULL,
        familySize INTEGER NOT NULL,
        incomeGroup TEXT NOT NULL,
        centreCode TEXT NOT NULL,
        returnNo TEXT NOT NULL,
        monthAndYear TEXT NOT NULL,
        mobileNumber TEXT NOT NULL,
        householdMembers TEXT NOT NULL,
        latitude REAL NOT NULL,
        longitude REAL NOT NULL,
        otpCode TEXT NOT NULL,
        createdAt TEXT NOT NULL,
        isSynced INTEGER NOT NULL DEFAULT 0,
        backendId INTEGER,
        lo_phone TEXT
      )
    ''');

    // MPR table - Updated structure
    await db.execute('''
      CREATE TABLE mpr (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        nameAndAddress TEXT NOT NULL,
        districtStateTel TEXT NOT NULL,
        panelCentre TEXT NOT NULL,
        centreCode TEXT NOT NULL,
        returnNo TEXT NOT NULL,
        familySize INTEGER NOT NULL,
        incomeGroup TEXT NOT NULL,
        monthAndYear TEXT NOT NULL,
        occupationOfHead TEXT NOT NULL,
        items TEXT NOT NULL,
        latitude REAL NOT NULL,
        longitude REAL NOT NULL,
        otpCode TEXT NOT NULL,
        createdAt TEXT NOT NULL,
        isSynced INTEGER NOT NULL DEFAULT 0,
        backendId INTEGER,
        lo_phone TEXT
      )
    ''');

    // FP table
    await db.execute('''
      CREATE TABLE fp (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        centreName TEXT NOT NULL,
        centreCode TEXT NOT NULL,
        panelSize INTEGER NOT NULL,
        mprCollected INTEGER NOT NULL,
        notCollected INTEGER NOT NULL,
        withPurchaseData INTEGER NOT NULL,
        nilMPRs INTEGER NOT NULL,
        nilSerialNos INTEGER NOT NULL,
        latitude REAL NOT NULL,
        longitude REAL NOT NULL,
        createdAt TEXT NOT NULL,
        isSynced INTEGER NOT NULL DEFAULT 0
      )
    ''');
  }

  void _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      // Version 2: Add isSynced column to all tables
      await db.execute('ALTER TABLE dpr ADD COLUMN isSynced INTEGER NOT NULL DEFAULT 0');
      await db.execute('ALTER TABLE mpr ADD COLUMN isSynced INTEGER NOT NULL DEFAULT 0');
      await db.execute('ALTER TABLE fp ADD COLUMN isSynced INTEGER NOT NULL DEFAULT 0');
    }
    
    if (oldVersion < 3) {
      // Version 3: Drop and recreate tables to handle JSON data properly
      await db.execute('DROP TABLE IF EXISTS dpr');
      await db.execute('DROP TABLE IF EXISTS mpr');
      await db.execute('DROP TABLE IF EXISTS fp');
      
      await db.execute('''
        CREATE TABLE dpr (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          nameAndAddress TEXT NOT NULL,
          district TEXT NOT NULL,
          state TEXT NOT NULL,
          familySize INTEGER NOT NULL,
          incomeGroup TEXT NOT NULL,
          centreCode TEXT NOT NULL,
          returnNo TEXT NOT NULL,
          monthAndYear TEXT NOT NULL,
          householdMembers TEXT NOT NULL,
          latitude REAL NOT NULL,
          longitude REAL NOT NULL,
          otpCode TEXT NOT NULL,
          createdAt TEXT NOT NULL,
          isSynced INTEGER NOT NULL DEFAULT 0
        )
      ''');
      
      await db.execute('''
        CREATE TABLE mpr (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          nameAndAddress TEXT NOT NULL,
          districtStateTel TEXT NOT NULL,
          panelCentre TEXT NOT NULL,
          centreCode TEXT NOT NULL,
          returnNo TEXT NOT NULL,
          familySize INTEGER NOT NULL,
          incomeGroup TEXT NOT NULL,
          monthAndYear TEXT NOT NULL,
          occupationOfHead TEXT NOT NULL,
          items TEXT NOT NULL,
          latitude REAL NOT NULL,
          longitude REAL NOT NULL,
          otpCode TEXT NOT NULL,
          createdAt TEXT NOT NULL,
          isSynced INTEGER NOT NULL DEFAULT 0
        )
      ''');
      
      await db.execute('''
        CREATE TABLE fp (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          centreName TEXT NOT NULL,
          centreCode TEXT NOT NULL,
          panelSize INTEGER NOT NULL,
          mprCollected INTEGER NOT NULL,
          notCollected INTEGER NOT NULL,
          withPurchaseData INTEGER NOT NULL,
          nilMPRs INTEGER NOT NULL,
          nilSerialNos INTEGER NOT NULL,
          latitude REAL NOT NULL,
          longitude REAL NOT NULL,
          createdAt TEXT NOT NULL,
          isSynced INTEGER NOT NULL DEFAULT 0
        )
      ''');
    }
    
    if (oldVersion < 4) {
      // Version 4: Add backendId column to track backend synchronization
      await db.execute('ALTER TABLE dpr ADD COLUMN backendId INTEGER');
      await db.execute('ALTER TABLE mpr ADD COLUMN backendId INTEGER');
      await db.execute('ALTER TABLE fp ADD COLUMN backendId INTEGER');
    }
    
    if (oldVersion < 5) {
      // Version 5: Add lo_phone column for LO access control
      await db.execute('ALTER TABLE dpr ADD COLUMN lo_phone TEXT');
      await db.execute('ALTER TABLE mpr ADD COLUMN lo_phone TEXT');
    }
  }

  // DPR CRUD Operations
  Future<int> insertDPR(DPR dpr) async {
    final db = await database;
    
    // Convert householdMembers to JSON string
    final householdMembersJson = jsonEncode(
      dpr.householdMembers.map((member) => member.toMap()).toList()
    );
    
    final data = {
      'nameAndAddress': dpr.nameAndAddress,
      'district': dpr.district,
      'state': dpr.state,
      'familySize': dpr.familySize,
      'incomeGroup': dpr.incomeGroup,
      'centreCode': dpr.centreCode,
      'returnNo': dpr.returnNo,
      'monthAndYear': dpr.monthAndYear,
      'mobileNumber': dpr.mobileNumber,
      'householdMembers': householdMembersJson,
      'latitude': dpr.latitude,
      'longitude': dpr.longitude,
      'otpCode': dpr.otpCode,
      'createdAt': dpr.createdAt.toIso8601String(),
      'isSynced': 0,
      'backendId': dpr.backendId,
      'lo_phone': dpr.loPhone,
    };
    
    final id = await db.insert('dpr', data);
    notifyListeners();
    return id;
  }

  Future<List<DPR>> getAllDPR() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query('dpr', orderBy: 'createdAt DESC');
    return List.generate(maps.length, (i) => DPR.fromMap(maps[i]));
  }

  Future<List<DPR>> getUnsyncedDPR() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'dpr',
      where: 'isSynced = ?',
      whereArgs: [0],
      orderBy: 'createdAt ASC',
    );
    return List.generate(maps.length, (i) => DPR.fromMap(maps[i]));
  }

  Future<void> updateDPRSyncStatus(int id, bool isSynced) async {
    final db = await database;
    await db.update(
      'dpr',
      {'isSynced': isSynced ? 1 : 0},
      where: 'id = ?',
      whereArgs: [id],
    );
    notifyListeners();
  }

  Future<void> updateDPRBackendId(int id, int backendId) async {
    final db = await database;
    await db.update(
      'dpr',
      {'backendId': backendId},
      where: 'id = ?',
      whereArgs: [id],
    );
    notifyListeners();
  }

  Future<void> deleteDPR(int id) async {
    final db = await database;
    await db.delete(
      'dpr',
      where: 'id = ?',
      whereArgs: [id],
    );
    notifyListeners();
  }

  Future<int> getDPRCount() async {
    final db = await database;
    final result = await db.rawQuery('SELECT COUNT(*) as count FROM dpr');
    return Sqflite.firstIntValue(result) ?? 0;
  }

  Future<int> getUnsyncedDPRCount() async {
    final db = await database;
    final result = await db.rawQuery(
      'SELECT COUNT(*) as count FROM dpr WHERE isSynced = 0'
    );
    return Sqflite.firstIntValue(result) ?? 0;
  }

  // Get DPR by Centre Code and Return Number for MPR auto-fill
  Future<DPR?> getDPRByCentreAndReturn(String centreCode, String returnNo) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'dpr',
      where: 'centreCode = ? AND returnNo = ?',
      whereArgs: [centreCode, returnNo],
      limit: 1,
    );
    
    if (maps.isEmpty) {
      return null;
    }
    
    return DPR.fromMap(maps.first);
  }

  // Get DPRs by LO phone number for access control
  Future<List<DPR>> getDPRsByLo(String loPhone) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'dpr',
      where: 'lo_phone = ?',
      whereArgs: [loPhone],
      orderBy: 'createdAt DESC',
    );
    return List.generate(maps.length, (i) => DPR.fromMap(maps[i]));
  }

  // Update DPR record
  Future<void> updateDPR(DPR dpr) async {
    final db = await database;
    
    // Convert householdMembers to JSON string
    final householdMembersJson = jsonEncode(
      dpr.householdMembers.map((member) => member.toMap()).toList()
    );
    
    final data = {
      'nameAndAddress': dpr.nameAndAddress,
      'district': dpr.district,
      'state': dpr.state,
      'familySize': dpr.familySize,
      'incomeGroup': dpr.incomeGroup,
      'centreCode': dpr.centreCode,
      'returnNo': dpr.returnNo,
      'monthAndYear': dpr.monthAndYear,
      'householdMembers': householdMembersJson,
      'latitude': dpr.latitude,
      'longitude': dpr.longitude,
      'otpCode': dpr.otpCode,
      'createdAt': dpr.createdAt.toIso8601String(),
      'isSynced': 0, // Mark as unsynced when updated
      'backendId': dpr.backendId,
      'lo_phone': dpr.loPhone,
    };
    
    await db.update(
      'dpr',
      data,
      where: 'id = ?',
      whereArgs: [dpr.id],
    );
    notifyListeners();
  }

  // Update MPR record
  Future<void> updateMPR(MPR mpr) async {
    final db = await database;
    
    // Convert items to JSON string
    final itemsJson = jsonEncode(
      mpr.items.map((item) => item.toMap()).toList()
    );
    
    final data = {
      'nameAndAddress': mpr.nameAndAddress,
      'districtStateTel': mpr.districtStateTel,
      'panelCentre': mpr.panelCentre,
      'centreCode': mpr.centreCode,
      'returnNo': mpr.returnNo,
      'familySize': mpr.familySize,
      'incomeGroup': mpr.incomeGroup,
      'monthAndYear': mpr.monthAndYear,
      'occupationOfHead': mpr.occupationOfHead,
      'items': itemsJson,
      'latitude': mpr.latitude,
      'longitude': mpr.longitude,
      'otpCode': mpr.otpCode,
      'createdAt': mpr.createdAt.toIso8601String(),
      'isSynced': 0, // Mark as unsynced when updated
      'backendId': mpr.backendId,
      'lo_phone': mpr.loPhone,
    };
    
    await db.update(
      'mpr',
      data,
      where: 'id = ?',
      whereArgs: [mpr.id],
    );
    notifyListeners();
  }

  // MPR CRUD Operations
  Future<int> insertMPR(MPR mpr) async {
    final db = await database;
    
    // Convert items to JSON string
    final itemsJson = jsonEncode(
      mpr.items.map((item) => item.toMap()).toList()
    );
    
    final data = {
      'nameAndAddress': mpr.nameAndAddress,
      'districtStateTel': mpr.districtStateTel,
      'panelCentre': mpr.panelCentre,
      'centreCode': mpr.centreCode,
      'returnNo': mpr.returnNo,
      'familySize': mpr.familySize,
      'incomeGroup': mpr.incomeGroup,
      'monthAndYear': mpr.monthAndYear,
      'occupationOfHead': mpr.occupationOfHead,
      'items': itemsJson,
      'latitude': mpr.latitude,
      'longitude': mpr.longitude,
      'otpCode': mpr.otpCode,
      'createdAt': mpr.createdAt.toIso8601String(),
      'isSynced': 0,
      'backendId': mpr.backendId,
      'lo_phone': mpr.loPhone,
    };
    
    final id = await db.insert('mpr', data);
    notifyListeners();
    return id;
  }

  Future<List<MPR>> getAllMPR() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query('mpr', orderBy: 'createdAt DESC');
    return List.generate(maps.length, (i) => MPR.fromMap(maps[i]));
  }

  Future<List<MPR>> getUnsyncedMPR() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'mpr',
      where: 'isSynced = ?',
      whereArgs: [0],
      orderBy: 'createdAt ASC',
    );
    return List.generate(maps.length, (i) => MPR.fromMap(maps[i]));
  }

  // Get MPRs by LO phone number for access control
  Future<List<MPR>> getMPRsByLo(String loPhone) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'mpr',
      where: 'lo_phone = ?',
      whereArgs: [loPhone],
      orderBy: 'createdAt DESC',
    );
    return List.generate(maps.length, (i) => MPR.fromMap(maps[i]));
  }

  Future<void> updateMPRSyncStatus(int id, bool isSynced) async {
    final db = await database;
    await db.update(
      'mpr',
      {'isSynced': isSynced ? 1 : 0},
      where: 'id = ?',
      whereArgs: [id],
    );
    notifyListeners();
  }

  Future<void> updateMPRBackendId(int id, int backendId) async {
    final db = await database;
    await db.update(
      'mpr',
      {'backendId': backendId},
      where: 'id = ?',
      whereArgs: [id],
    );
    notifyListeners();
  }

  Future<void> deleteMPR(int id) async {
    final db = await database;
    await db.delete(
      'mpr',
      where: 'id = ?',
      whereArgs: [id],
    );
    notifyListeners();
  }

  Future<int> getMPRCount() async {
    final db = await database;
    final result = await db.rawQuery('SELECT COUNT(*) as count FROM mpr');
    return Sqflite.firstIntValue(result) ?? 0;
  }

  Future<int> getUnsyncedMPRCount() async {
    final db = await database;
    final result = await db.rawQuery(
      'SELECT COUNT(*) as count FROM mpr WHERE isSynced = 0'
    );
    return Sqflite.firstIntValue(result) ?? 0;
  }

  // Get MPR submissions over the past 6 periods (months)
  Future<List<Map<String, dynamic>>> getMPRSubmissionsByPeriod() async {
    final db = await database;
    final now = DateTime.now();
    final List<Map<String, dynamic>> result = [];
    
    for (int i = 5; i >= 0; i--) {
      final periodStart = DateTime(now.year, now.month - i, 1);
      
      final count = await db.rawQuery('''
        SELECT COUNT(*) as count FROM mpr 
        WHERE monthAndYear = ?
      ''', [
        '${periodStart.month}/${periodStart.year}',
      ]);
      
      result.add({
        'period': '${periodStart.month}/${periodStart.year}',
        'count': Sqflite.firstIntValue(count) ?? 0,
      });
    }
    
    return result;
  }

  // FP CRUD Operations
  Future<int> insertFP(FP fp) async {
    final db = await database;
    final id = await db.insert('fp', fp.toMap());
    notifyListeners();
    return id;
  }

  Future<List<FP>> getAllFP() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query('fp', orderBy: 'createdAt DESC');
    return List.generate(maps.length, (i) => FP.fromMap(maps[i]));
  }

  Future<List<FP>> getUnsyncedFP() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'fp',
      where: 'isSynced = ?',
      whereArgs: [0],
      orderBy: 'createdAt ASC',
    );
    return List.generate(maps.length, (i) => FP.fromMap(maps[i]));
  }

  Future<void> updateFPSyncStatus(int id, bool isSynced) async {
    final db = await database;
    await db.update(
      'fp',
      {'isSynced': isSynced ? 1 : 0},
      where: 'id = ?',
      whereArgs: [id],
    );
    notifyListeners();
  }

  Future<void> updateFPBackendId(int id, int backendId) async {
    final db = await database;
    await db.update(
      'fp',
      {'backendId': backendId},
      where: 'id = ?',
      whereArgs: [id],
    );
    notifyListeners();
  }

  Future<void> deleteFP(int id) async {
    final db = await database;
    await db.delete(
      'fp',
      where: 'id = ?',
      whereArgs: [id],
    );
    notifyListeners();
  }

  Future<int> getFPCount() async {
    final db = await database;
    final result = await db.rawQuery('SELECT COUNT(*) as count FROM fp');
    return Sqflite.firstIntValue(result) ?? 0;
  }

  Future<int> getUnsyncedFPCount() async {
    final db = await database;
    final result = await db.rawQuery(
      'SELECT COUNT(*) as count FROM fp WHERE isSynced = 0'
    );
    return Sqflite.firstIntValue(result) ?? 0;
  }

  // Database statistics
  Future<Map<String, int>> getDatabaseStats() async {
    final dprCount = await getDPRCount();
    final unsyncedDprCount = await getUnsyncedDPRCount();
    final mprCount = await getMPRCount();
    final unsyncedMprCount = await getUnsyncedMPRCount();
    final fpCount = await getFPCount();
    final unsyncedFpCount = await getUnsyncedFPCount();
    
    return {
      'totalDPR': dprCount,
      'unsyncedDPR': unsyncedDprCount,
      'totalMPR': mprCount,
      'unsyncedMPR': unsyncedMprCount,
      'totalFP': fpCount,
      'unsyncedFP': unsyncedFpCount,
    };
  }

  // Close database
  Future<void> close() async {
    final db = await database;
    await db.close();
  }
} 