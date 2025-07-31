class FP {
  final int? id;
  final String centreName;
  final String centreCode;
  final int panelSize;
  final int mprCollected;
  final int notCollected;
  final int withPurchaseData;
  final int nilMPRs;
  final int nilSerialNos;
  final double latitude;
  final double longitude;
  final DateTime createdAt;
  final bool isSynced;

  FP({
    this.id,
    required this.centreName,
    required this.centreCode,
    required this.panelSize,
    required this.mprCollected,
    required this.notCollected,
    required this.withPurchaseData,
    required this.nilMPRs,
    required this.nilSerialNos,
    required this.latitude,
    required this.longitude,
    required this.createdAt,
    this.isSynced = false,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'centreName': centreName,
      'centreCode': centreCode,
      'panelSize': panelSize,
      'mprCollected': mprCollected,
      'notCollected': notCollected,
      'withPurchaseData': withPurchaseData,
      'nilMPRs': nilMPRs,
      'nilSerialNos': nilSerialNos,
      'latitude': latitude,
      'longitude': longitude,
      'createdAt': createdAt.toIso8601String(),
      'isSynced': isSynced ? 1 : 0,
    };
  }

  factory FP.fromMap(Map<String, dynamic> map) {
    return FP(
      id: map['id'],
      centreName: map['centreName'],
      centreCode: map['centreCode'],
      panelSize: map['panelSize'],
      mprCollected: map['mprCollected'],
      notCollected: map['notCollected'],
      withPurchaseData: map['withPurchaseData'],
      nilMPRs: map['nilMPRs'],
      nilSerialNos: map['nilSerialNos'],
      latitude: map['latitude'],
      longitude: map['longitude'],
      createdAt: DateTime.parse(map['createdAt']),
      isSynced: map['isSynced'] == 1,
    );
  }

  FP copyWith({
    int? id,
    String? centreName,
    String? centreCode,
    int? panelSize,
    int? mprCollected,
    int? notCollected,
    int? withPurchaseData,
    int? nilMPRs,
    int? nilSerialNos,
    double? latitude,
    double? longitude,
    DateTime? createdAt,
    bool? isSynced,
  }) {
    return FP(
      id: id ?? this.id,
      centreName: centreName ?? this.centreName,
      centreCode: centreCode ?? this.centreCode,
      panelSize: panelSize ?? this.panelSize,
      mprCollected: mprCollected ?? this.mprCollected,
      notCollected: notCollected ?? this.notCollected,
      withPurchaseData: withPurchaseData ?? this.withPurchaseData,
      nilMPRs: nilMPRs ?? this.nilMPRs,
      nilSerialNos: nilSerialNos ?? this.nilSerialNos,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      createdAt: createdAt ?? this.createdAt,
      isSynced: isSynced ?? this.isSynced,
    );
  }
} 