class ForwardingProforma {
  final String periodId;       // e.g., "2025-01-02" (Jan–Feb)
  final String centerCode;
  final String centerName;
  final int panelSize;         // LO serial range size
  final String loId;
  final String loName;

  final int countCollected;    // withPurchase + nil
  final int countNotCollected;
  final int countWithPurchase;
  final int countNilMpr;
  final List<int> serialsNilMpr;

  final List<NotCollectedRow> notCollected; // LO fills reason/date/substitute
  final PanelChanges panelChanges;          // substitution/address/family changes

  final String draftedAt;      // ISO
  final String? submittedAt;   // ISO
  final Map<String, dynamic>? loLocation; // { lat, lng, accuracy?, capturedAt }

  ForwardingProforma({
    required this.periodId,
    required this.centerCode,
    required this.centerName,
    required this.panelSize,
    required this.loId,
    required this.loName,
    required this.countCollected,
    required this.countNotCollected,
    required this.countWithPurchase,
    required this.countNilMpr,
    required this.serialsNilMpr,
    required this.notCollected,
    required this.panelChanges,
    required this.draftedAt,
    this.submittedAt,
    this.loLocation,
  });

  factory ForwardingProforma.fromJson(Map<String, dynamic> json) {
    return ForwardingProforma(
      periodId: json['periodId'] as String,
      centerCode: json['centerCode'] as String,
      centerName: json['centerName'] as String,
      panelSize: json['panelSize'] as int,
      loId: json['loId'] as String,
      loName: json['loName'] as String,
      countCollected: json['countCollected'] as int,
      countNotCollected: json['countNotCollected'] as int,
      countWithPurchase: json['countWithPurchase'] as int,
      countNilMpr: json['countNilMpr'] as int,
      serialsNilMpr: List<int>.from(json['serialsNilMpr']),
      notCollected: (json['notCollected'] as List)
          .map((e) => NotCollectedRow.fromJson(e))
          .toList(),
      panelChanges: PanelChanges.fromJson(json['panelChanges']),
      draftedAt: json['draftedAt'] as String,
      submittedAt: json['submittedAt'] as String?,
      loLocation: json['loLocation'] != null ? Map<String, dynamic>.from(json['loLocation']) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'periodId': periodId,
      'centerCode': centerCode,
      'centerName': centerName,
      'panelSize': panelSize,
      'loId': loId,
      'loName': loName,
      'countCollected': countCollected,
      'countNotCollected': countNotCollected,
      'countWithPurchase': countWithPurchase,
      'countNilMpr': countNilMpr,
      'serialsNilMpr': serialsNilMpr,
      'notCollected': notCollected.map((e) => e.toJson()).toList(),
      'panelChanges': panelChanges.toJson(),
      'draftedAt': draftedAt,
      'submittedAt': submittedAt,
      if (loLocation != null) 'loLocation': loLocation,
    };
  }

  ForwardingProforma copyWith({
    String? periodId,
    String? centerCode,
    String? centerName,
    int? panelSize,
    String? loId,
    String? loName,
    int? countCollected,
    int? countNotCollected,
    int? countWithPurchase,
    int? countNilMpr,
    List<int>? serialsNilMpr,
    List<NotCollectedRow>? notCollected,
    PanelChanges? panelChanges,
    String? draftedAt,
    String? submittedAt,
    Map<String, dynamic>? loLocation,
  }) {
    return ForwardingProforma(
      periodId: periodId ?? this.periodId,
      centerCode: centerCode ?? this.centerCode,
      centerName: centerName ?? this.centerName,
      panelSize: panelSize ?? this.panelSize,
      loId: loId ?? this.loId,
      loName: loName ?? this.loName,
      countCollected: countCollected ?? this.countCollected,
      countNotCollected: countNotCollected ?? this.countNotCollected,
      countWithPurchase: countWithPurchase ?? this.countWithPurchase,
      countNilMpr: countNilMpr ?? this.countNilMpr,
      serialsNilMpr: serialsNilMpr ?? this.serialsNilMpr,
      notCollected: notCollected ?? this.notCollected,
      panelChanges: panelChanges ?? this.panelChanges,
      draftedAt: draftedAt ?? this.draftedAt,
      submittedAt: submittedAt ?? this.submittedAt,
      loLocation: loLocation ?? this.loLocation,
    );
  }
}

class NotCollectedRow {
  final int serialNo;
  String? reason;
  String? dataCollectionDate;   // ISO
  bool? substituteRequired;

  NotCollectedRow({
    required this.serialNo,
    this.reason,
    this.dataCollectionDate,
    this.substituteRequired,
  });

  factory NotCollectedRow.fromJson(Map<String, dynamic> json) {
    return NotCollectedRow(
      serialNo: json['serialNo'] as int,
      reason: json['reason'] as String?,
      dataCollectionDate: json['dataCollectionDate'] as String?,
      substituteRequired: json['substituteRequired'] as bool?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'serialNo': serialNo,
      'reason': reason,
      'dataCollectionDate': dataCollectionDate,
      'substituteRequired': substituteRequired,
    };
  }

  NotCollectedRow copyWith({
    int? serialNo,
    String? reason,
    String? dataCollectionDate,
    bool? substituteRequired,
  }) {
    return NotCollectedRow(
      serialNo: serialNo ?? this.serialNo,
      reason: reason ?? this.reason,
      dataCollectionDate: dataCollectionDate ?? this.dataCollectionDate,
      substituteRequired: substituteRequired ?? this.substituteRequired,
    );
  }
}

class PanelChanges {
  bool substitution;
  bool addressChange;
  bool familyAddDelete;
  String? notes; // old/new details summary

  PanelChanges({
    required this.substitution,
    required this.addressChange,
    required this.familyAddDelete,
    this.notes,
  });

  factory PanelChanges.fromJson(Map<String, dynamic> json) {
    return PanelChanges(
      substitution: json['substitution'] as bool,
      addressChange: json['addressChange'] as bool,
      familyAddDelete: json['familyAddDelete'] as bool,
      notes: json['notes'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'substitution': substitution,
      'addressChange': addressChange,
      'familyAddDelete': familyAddDelete,
      'notes': notes,
    };
  }

  PanelChanges copyWith({
    bool? substitution,
    bool? addressChange,
    bool? familyAddDelete,
    String? notes,
  }) {
    return PanelChanges(
      substitution: substitution ?? this.substitution,
      addressChange: addressChange ?? this.addressChange,
      familyAddDelete: familyAddDelete ?? this.familyAddDelete,
      notes: notes ?? this.notes,
    );
  }
}

enum MprStatus {
  WITH_PURCHASE,
  NIL,
  NOT_COLLECTED,
}

class SubmitResult {
  final String packageId;
  final String status;
  final Map<String, String> serverHashes;
  final String submittedAt;

  SubmitResult({
    required this.packageId,
    required this.status,
    required this.serverHashes,
    required this.submittedAt,
  });

  factory SubmitResult.fromJson(Map<String, dynamic> json) {
    return SubmitResult(
      packageId: json['packageId'] as String,
      status: json['status'] as String,
      serverHashes: Map<String, String>.from(json['serverHashes']),
      submittedAt: json['submittedAt'] as String,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'packageId': packageId,
      'status': status,
      'serverHashes': serverHashes,
      'submittedAt': submittedAt,
    };
  }
} 