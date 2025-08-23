class BackupEntry {
  final String id;
  final String centerCode;
  final String periodId;
  final String loId;
  final int version;
  final String path;
  final String sha256;
  final String createdAt;
  final String state;
  final int retentionDays;
  final bool encrypted;
  final String? packageId;
  final String? serverHashes;
  final String? submittedAt;

  const BackupEntry({
    required this.id,
    required this.centerCode,
    required this.periodId,
    required this.loId,
    required this.version,
    required this.path,
    required this.sha256,
    required this.createdAt,
    required this.state,
    required this.retentionDays,
    required this.encrypted,
    this.packageId,
    this.serverHashes,
    this.submittedAt,
  });

  factory BackupEntry.fromJson(Map<String, dynamic> json) {
    return BackupEntry(
      id: json['id'] as String,
      centerCode: json['centerCode'] as String,
      periodId: json['periodId'] as String,
      loId: json['loId'] as String,
      version: json['version'] as int,
      path: json['path'] as String,
      sha256: json['sha256'] as String,
      createdAt: json['createdAt'] as String,
      state: json['state'] as String,
      retentionDays: json['retentionDays'] as int,
      encrypted: json['encrypted'] as bool,
      packageId: json['packageId'] as String?,
      serverHashes: json['serverHashes'] as String?,
      submittedAt: json['submittedAt'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'centerCode': centerCode,
      'periodId': periodId,
      'loId': loId,
      'version': version,
      'path': path,
      'sha256': sha256,
      'createdAt': createdAt,
      'state': state,
      'retentionDays': retentionDays,
      'encrypted': encrypted,
      'packageId': packageId,
      'serverHashes': serverHashes,
      'submittedAt': submittedAt,
    };
  }

  BackupEntry copyWith({
    String? id,
    String? centerCode,
    String? periodId,
    String? loId,
    int? version,
    String? path,
    String? sha256,
    String? createdAt,
    String? state,
    int? retentionDays,
    bool? encrypted,
    String? packageId,
    String? serverHashes,
    String? submittedAt,
  }) {
    return BackupEntry(
      id: id ?? this.id,
      centerCode: centerCode ?? this.centerCode,
      periodId: periodId ?? this.periodId,
      loId: loId ?? this.loId,
      version: version ?? this.version,
      path: path ?? this.path,
      sha256: sha256 ?? this.sha256,
      createdAt: createdAt ?? this.createdAt,
      state: state ?? this.state,
      retentionDays: retentionDays ?? this.retentionDays,
      encrypted: encrypted ?? this.encrypted,
      packageId: packageId ?? this.packageId,
      serverHashes: serverHashes ?? this.serverHashes,
      submittedAt: submittedAt ?? this.submittedAt,
    );
  }

  @override
  String toString() {
    return 'BackupEntry(id: $id, centerCode: $centerCode, periodId: $periodId, loId: $loId, version: $version, state: $state)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is BackupEntry && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}

// Backup states enum
enum BackupState {
  DRAFTED,
  SUBMITTED_PENDING_ACK,
  ACKED,
  FAILED_RETRYABLE,
  RESTORED,
}

extension BackupStateExtension on BackupState {
  String get value {
    switch (this) {
      case BackupState.DRAFTED:
        return 'DRAFTED';
      case BackupState.SUBMITTED_PENDING_ACK:
        return 'SUBMITTED_PENDING_ACK';
      case BackupState.ACKED:
        return 'ACKED';
      case BackupState.FAILED_RETRYABLE:
        return 'FAILED_RETRYABLE';
      case BackupState.RESTORED:
        return 'RESTORED';
    }
  }

  static BackupState fromString(String value) {
    switch (value) {
      case 'DRAFTED':
        return BackupState.DRAFTED;
      case 'SUBMITTED_PENDING_ACK':
        return BackupState.SUBMITTED_PENDING_ACK;
      case 'ACKED':
        return BackupState.ACKED;
      case 'FAILED_RETRYABLE':
        return BackupState.FAILED_RETRYABLE;
      case 'RESTORED':
        return BackupState.RESTORED;
      default:
        throw ArgumentError('Unknown backup state: $value');
    }
  }
}

// Backup manifest model
class BackupManifest {
  final Map<String, String> fileHashes; // filename -> SHA256
  final String createdAt;
  final String appVersion;
  final String deviceId;
  final String centerCode;
  final String periodId;
  final String loId;
  final int version;

  const BackupManifest({
    required this.fileHashes,
    required this.createdAt,
    required this.appVersion,
    required this.deviceId,
    required this.centerCode,
    required this.periodId,
    required this.loId,
    required this.version,
  });

  factory BackupManifest.fromJson(Map<String, dynamic> json) {
    return BackupManifest(
      fileHashes: Map<String, String>.from(json['fileHashes'] as Map),
      createdAt: json['createdAt'] as String,
      appVersion: json['appVersion'] as String,
      deviceId: json['deviceId'] as String,
      centerCode: json['centerCode'] as String,
      periodId: json['periodId'] as String,
      loId: json['loId'] as String,
      version: json['version'] as int,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'fileHashes': fileHashes,
      'createdAt': createdAt,
      'appVersion': appVersion,
      'deviceId': deviceId,
      'centerCode': centerCode,
      'periodId': periodId,
      'loId': loId,
      'version': version,
    };
  }
}

// MPR file metadata for backup
class MprFile {
  final String serialNo;
  final String filePath;
  final String sha256;
  final String mprData; // JSON string of MPR data

  const MprFile({
    required this.serialNo,
    required this.filePath,
    required this.sha256,
    required this.mprData,
  });

  factory MprFile.fromJson(Map<String, dynamic> json) {
    return MprFile(
      serialNo: json['serialNo'] as String,
      filePath: json['filePath'] as String,
      sha256: json['sha256'] as String,
      mprData: json['mprData'] as String,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'serialNo': serialNo,
      'filePath': filePath,
      'sha256': sha256,
      'mprData': mprData,
    };
  }
} 