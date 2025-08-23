import 'dart:io';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';
import '../models/dpr.dart';
import '../models/mpr.dart';

import '../models/backup_catalog.dart';

class DatabaseService extends ChangeNotifier {
  static Database? _database;
  static const String _databaseName = 'mtc_nanna.db';
  static const int _databaseVersion = 7; // Increment version for FP handoff tables

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

    // ForwardingProformaDrafts table
    await db.execute('''
      CREATE TABLE forwarding_proforma_drafts (
        draft_key TEXT PRIMARY KEY,
        fp_data TEXT NOT NULL,
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL
      )
    ''');

    // ForwardingProformaSubmissions table
    await db.execute('''
      CREATE TABLE forwarding_proforma_submissions (
        submission_key TEXT PRIMARY KEY,
        center_code TEXT NOT NULL,
        period_id TEXT NOT NULL,
        lo_id TEXT NOT NULL,
        package_id TEXT NOT NULL,
        status TEXT NOT NULL,
        server_hashes TEXT NOT NULL,
        submitted_at TEXT NOT NULL,
        created_at TEXT NOT NULL
      )
    ''');

    // MprAuditRecords table
    await db.execute('''
      CREATE TABLE mpr_audit_records (
        mpr_id INTEGER NOT NULL,
        center_code TEXT NOT NULL,
        period_id TEXT NOT NULL,
        lo_id TEXT NOT NULL,
        mpr_data_hash TEXT NOT NULL,
        submitted_at TEXT NOT NULL,
        package_id TEXT NOT NULL,
        created_at TEXT NOT NULL
      )
    ''');
    
    // Backups table
    await db.execute('''
      CREATE TABLE backups (
        id TEXT PRIMARY KEY,
        center_code TEXT NOT NULL,
        period_id TEXT NOT NULL,
        lo_id TEXT NOT NULL,
        version INTEGER NOT NULL,
        path TEXT NOT NULL,
        sha256 TEXT NOT NULL,
        created_at TEXT NOT NULL,
        state TEXT NOT NULL,
        retention_days INTEGER NOT NULL,
        encrypted INTEGER NOT NULL,
        package_id TEXT,
        server_hashes TEXT,
        submitted_at TEXT,
        UNIQUE(center_code, period_id, lo_id, version)
      )
    ''');
    
    // Create index for backup queries
    await db.execute('CREATE INDEX idx_backups_lookup ON backups(center_code, period_id, lo_id)');
    await db.execute('CREATE INDEX idx_backups_state ON backups(state)');
    await db.execute('CREATE INDEX idx_backups_created ON backups(created_at)');
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

    if (oldVersion < 6) {
      // Version 6: Add new FP handoff tables
      await db.execute('''
        CREATE TABLE forwarding_proforma_drafts (
          draft_key TEXT PRIMARY KEY,
          fp_data TEXT NOT NULL,
          created_at TEXT NOT NULL,
          updated_at TEXT NOT NULL
        )
      ''');
      await db.execute('''
        CREATE TABLE forwarding_proforma_submissions (
          submission_key TEXT PRIMARY KEY,
          center_code TEXT NOT NULL,
          period_id TEXT NOT NULL,
          lo_id TEXT NOT NULL,
          package_id TEXT NOT NULL,
          status TEXT NOT NULL,
          server_hashes TEXT NOT NULL,
          submitted_at TEXT NOT NULL,
          created_at TEXT NOT NULL
        )
      ''');
      await db.execute('''
        CREATE TABLE mpr_audit_records (
          mpr_id INTEGER NOT NULL,
          center_code TEXT NOT NULL,
          period_id TEXT NOT NULL,
          lo_id TEXT NOT NULL,
          mpr_data_hash TEXT NOT NULL,
          submitted_at TEXT NOT NULL,
          package_id TEXT NOT NULL,
          created_at TEXT NOT NULL
        )
      ''');
    }
    
    if (oldVersion < 7) {
      // Version 7: Add backup catalog table
      await db.execute('''
        CREATE TABLE backups (
          id TEXT PRIMARY KEY,
          center_code TEXT NOT NULL,
          period_id TEXT NOT NULL,
          lo_id TEXT NOT NULL,
          version INTEGER NOT NULL,
          path TEXT NOT NULL,
          sha256 TEXT NOT NULL,
          created_at TEXT NOT NULL,
          state TEXT NOT NULL,
          retention_days INTEGER NOT NULL,
          encrypted INTEGER NOT NULL,
          package_id TEXT,
          server_hashes TEXT,
          submitted_at TEXT,
          UNIQUE(center_code, period_id, lo_id, version)
        )
      ''');
      
      // Create index for backup queries
      await db.execute('CREATE INDEX idx_backups_lookup ON backups(center_code, period_id, lo_id)');
      await db.execute('CREATE INDEX idx_backups_state ON backups(state)');
      await db.execute('CREATE INDEX idx_backups_created ON backups(created_at)');
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

  // Get DPR for MPR form (with caching)
  Future<Map<String, dynamic>?> getDprFor(String centerId, String householdId) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'dpr',
      where: 'centreCode = ? AND returnNo = ?',
      whereArgs: [centerId, householdId],
      limit: 1,
    );
    
    if (maps.isEmpty) {
      return null;
    }
    
    final dpr = DPR.fromMap(maps.first);
    return {
      'id': dpr.id,
      'centreCode': dpr.centreCode,
      'returnNo': dpr.returnNo,
      'members': dpr.householdMembers.map((m) => m.toMap()).toList(),
    };
  }

  // Cache DPR data for MPR form
  Future<void> cacheDprFor(String centerId, String householdId, Map<String, dynamic> dprJson) async {
    // This method is for future use when we implement caching from API
    // For now, we rely on the existing database
    print('Caching DPR data for $centerId/$householdId: $dprJson');
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

  // Upsert DPR members - update existing or insert new
  Future<void> upsertMembers(int dprId, List<HouseholdMember> members) async {
    final db = await database;
    
    // Get existing DPR
    final List<Map<String, dynamic>> maps = await db.query(
      'dpr',
      where: 'id = ?',
      whereArgs: [dprId],
      limit: 1,
    );
    
    if (maps.isEmpty) {
      throw Exception('DPR not found with ID: $dprId');
    }
    
    // Convert members to JSON string
    final membersJson = jsonEncode(
      members.map((member) => member.toMap()).toList()
    );
    
    // Update the householdMembers field
    await db.update(
      'dpr',
      {
        'householdMembers': membersJson,
        'familySize': members.length,
        'isSynced': 0, // Mark as unsynced when updated
      },
      where: 'id = ?',
      whereArgs: [dprId],
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



  // ForwardingProforma (FP) Operations
  Future<void> saveForwardingProformaDraft(Map<String, dynamic> fpData) async {
    final db = await database;
    final key = '${fpData['centerCode']}_${fpData['periodId']}_${fpData['loId']}';
    
    await db.execute('''
      INSERT OR REPLACE INTO forwarding_proforma_drafts (
        draft_key, fp_data, created_at, updated_at
      ) VALUES (?, ?, ?, ?)
    ''', [
      key,
      jsonEncode(fpData),
      DateTime.now().toIso8601String(),
      DateTime.now().toIso8601String(),
    ]);
    
    notifyListeners();
  }

  Future<Map<String, dynamic>?> getForwardingProformaDraft(String centerCode, String periodId, String loId) async {
    final db = await database;
    final key = '${centerCode}_${periodId}_${loId}';
    
    final result = await db.query(
      'forwarding_proforma_drafts',
      where: 'draft_key = ?',
      whereArgs: [key],
    );
    
    if (result.isNotEmpty) {
      return jsonDecode(result.first['fp_data'] as String);
    }
    return null;
  }

  Future<void> markForwardingProformaSubmitted(String centerCode, String periodId, String loId, Map<String, dynamic> submitResult) async {
    final db = await database;
    final key = '${centerCode}_${periodId}_${loId}';
    
    await db.execute('''
      INSERT OR REPLACE INTO forwarding_proforma_submissions (
        submission_key, center_code, period_id, lo_id, package_id, status, 
        server_hashes, submitted_at, created_at
      ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?)
    ''', [
      key,
      centerCode,
      periodId,
      loId,
      submitResult['packageId'],
      submitResult['status'],
      jsonEncode(submitResult['serverHashes']),
      submitResult['submittedAt'],
      DateTime.now().toIso8601String(),
    ]);
    
    notifyListeners();
  }

  Future<void> cleanupLocalMprsAfterSubmit(String centerCode, String periodId, String loId) async {
    final db = await database;
    
    // Get MPRs for this center and period
    final mprs = await db.query(
      'mpr',
      where: 'centreCode = ? AND monthAndYear = ?',
      whereArgs: [centerCode, periodId],
    );
    
    // Create audit records before deletion
    for (final mpr in mprs) {
      await db.execute('''
        INSERT INTO mpr_audit_records (
          mpr_id, center_code, period_id, lo_id, mpr_data_hash, 
          submitted_at, package_id, created_at
        ) VALUES (?, ?, ?, ?, ?, ?, ?, ?)
      ''', [
        mpr['id'],
        centerCode,
        periodId,
        loId,
        mpr['items'], // Use items as hash for now
        DateTime.now().toIso8601String(),
        'PENDING', // Will be updated with actual package ID
        DateTime.now().toIso8601String(),
      ]);
    }
    
    // Delete local MPR entries
    await db.delete(
      'mpr',
      where: 'centreCode = ? AND monthAndYear = ?',
      whereArgs: [centerCode, periodId],
    );
    
    notifyListeners();
  }

  Future<List<Map<String, dynamic>>> getMprsForPeriod(String centerCode, String periodId) async {
    final db = await database;
    
    final result = await db.query(
      'mpr',
      where: 'centreCode = ? AND monthAndYear = ?',
      whereArgs: [centerCode, periodId],
    );
    
    return result;
  }

  Future<Map<String, dynamic>?> getDprForCenter(String centerCode) async {
    final db = await database;
    
    final result = await db.query(
      'dpr',
      where: 'centreCode = ?',
      whereArgs: [centerCode],
      limit: 1,
    );
    
    if (result.isNotEmpty) {
      return result.first;
    }
    return null;
  }

  Future<List<Map<String, dynamic>>> getDprMembersForCenter(String centerCode) async {
    final db = await database;
    
    final result = await db.query(
      'dpr',
      where: 'centreCode = ?',
      whereArgs: [centerCode],
    );
    
    final members = <Map<String, dynamic>>[];
    for (final dpr in result) {
      if (dpr['householdMembers'] != null) {
        final householdMembers = jsonDecode(dpr['householdMembers'] as String);
        if (householdMembers is List) {
          for (final member in householdMembers) {
            if (member is Map<String, dynamic>) {
              members.add({
                ...member,
                'returnNo': dpr['returnNo'],
                'centerCode': centerCode,
              });
            }
          }
        }
      }
    }
    
    return members;
  }

  // Database statistics
  Future<Map<String, int>> getDatabaseStats() async {
    final dprCount = await getDPRCount();
    final unsyncedDprCount = await getUnsyncedDPRCount();
    final mprCount = await getMPRCount();
    final unsyncedMprCount = await getUnsyncedMPRCount();
    return {
      'totalDPR': dprCount,
      'unsyncedDPR': unsyncedDprCount,
      'totalMPR': mprCount,
      'unsyncedMPR': unsyncedMprCount,
    };
  }

  // Close database
  Future<void> close() async {
    final db = await database;
    await db.close();
  }

  // ===== BACKUP CATALOG OPERATIONS =====
  
  Future<void> insertBackupEntry(BackupEntry backup) async {
    final db = await database;
    await db.insert('backups', backup.toJson());
    notifyListeners();
  }

  Future<void> updateBackupEntry(BackupEntry backup) async {
    final db = await database;
    await db.update(
      'backups',
      backup.toJson(),
      where: 'id = ?',
      whereArgs: [backup.id],
    );
    notifyListeners();
  }

  Future<BackupEntry?> getBackupEntry(String id) async {
    final db = await database;
    final result = await db.query(
      'backups',
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );
    
    if (result.isNotEmpty) {
      return BackupEntry.fromJson(result.first);
    }
    return null;
  }

  Future<List<BackupEntry>> getBackupsForHandoff({
    String? centerCode,
    String? periodId,
    String? loId,
  }) async {
    final db = await database;
    
    String whereClause = '';
    List<Object> whereArgs = [];
    
    if (centerCode != null) {
      whereClause += 'center_code = ?';
      whereArgs.add(centerCode);
    }
    
    if (periodId != null) {
      if (whereClause.isNotEmpty) whereClause += ' AND ';
      whereClause += 'period_id = ?';
      whereArgs.add(periodId);
    }
    
    if (loId != null) {
      if (whereClause.isNotEmpty) whereClause += ' AND ';
      whereClause += 'lo_id = ?';
      whereArgs.add(loId);
    }
    
    final result = await db.query(
      'backups',
      where: whereClause.isEmpty ? null : whereClause,
      whereArgs: whereArgs.isEmpty ? null : whereArgs,
      orderBy: 'version DESC, created_at DESC',
    );
    
    return result.map((map) => BackupEntry.fromJson(map)).toList();
  }

  Future<List<BackupEntry>> getBackupsByState(String state) async {
    final db = await database;
    final result = await db.query(
      'backups',
      where: 'state = ?',
      whereArgs: [state],
      orderBy: 'created_at ASC',
    );
    
    return result.map((map) => BackupEntry.fromJson(map)).toList();
  }

  Future<void> deleteBackupEntry(String id) async {
    final db = await database;
    await db.delete(
      'backups',
      where: 'id = ?',
      whereArgs: [id],
    );
    notifyListeners();
  }

  Future<void> purgeExpiredBackups() async {
    final db = await database;
    
    // Get current timestamp
    final now = DateTime.now();
    
    // Find backups that are ACKED and older than their retention period
    final expiredBackups = await db.rawQuery('''
      SELECT id FROM backups 
      WHERE state = 'ACKED' 
      AND datetime(created_at) < datetime(?, '-' || retention_days || ' days')
    ''', [now.toIso8601String()]);
    
    // Delete expired backups
    for (final backup in expiredBackups) {
      final backupId = backup['id'] as String;
      await deleteBackupEntry(backupId);
      
      // Also delete the actual backup file
      // TODO: Implement file deletion
    }
  }

  Future<int> getBackupCount() async {
    final db = await database;
    final result = await db.rawQuery('SELECT COUNT(*) as count FROM backups');
    return Sqflite.firstIntValue(result) ?? 0;
  }
} 