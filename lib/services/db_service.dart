import 'dart:io';
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
  static const int _databaseVersion = 1;

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
    // DPR table
    await db.execute('''
      CREATE TABLE dpr (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        householdId TEXT NOT NULL,
        householdHeadName TEXT NOT NULL,
        address TEXT NOT NULL,
        phoneNumber TEXT NOT NULL,
        familySize INTEGER NOT NULL,
        monthlyIncome REAL NOT NULL,
        latitude REAL NOT NULL,
        longitude REAL NOT NULL,
        otpCode TEXT NOT NULL,
        signaturePath TEXT NOT NULL,
        createdAt TEXT NOT NULL,
        isSynced INTEGER NOT NULL DEFAULT 0
      )
    ''');

    // MPR table
    await db.execute('''
      CREATE TABLE mpr (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        householdId TEXT NOT NULL,
        purchaseDate TEXT NOT NULL,
        textileType TEXT NOT NULL,
        quantity INTEGER NOT NULL,
        price REAL NOT NULL,
        purchaseLocation TEXT NOT NULL,
        latitude REAL NOT NULL,
        longitude REAL NOT NULL,
        createdAt TEXT NOT NULL,
        isSynced INTEGER NOT NULL DEFAULT 0
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

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    // Handle database upgrades here
  }

  // DPR CRUD Operations
  Future<int> insertDPR(DPR dpr) async {
    final db = await database;
    final id = await db.insert('dpr', dpr.toMap());
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

  // MPR CRUD Operations
  Future<int> insertMPR(MPR mpr) async {
    final db = await database;
    final id = await db.insert('mpr', mpr.toMap());
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
      final periodEnd = DateTime(now.year, now.month - i + 1, 0, 23, 59, 59);
      
      final count = await db.rawQuery('''
        SELECT COUNT(*) as count FROM mpr 
        WHERE purchaseDate >= ? AND purchaseDate <= ?
      ''', [
        periodStart.toIso8601String(),
        periodEnd.toIso8601String(),
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
    final db = await database;
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