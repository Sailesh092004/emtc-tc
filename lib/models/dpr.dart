class DPR {
  final int? id;
  final String householdId;
  final String householdHeadName;
  final String address;
  final String phoneNumber;
  final int familySize;
  final double monthlyIncome;
  final double latitude;
  final double longitude;
  final String otpCode;
  final String signaturePath;
  final DateTime createdAt;
  final bool isSynced;

  DPR({
    this.id,
    required this.householdId,
    required this.householdHeadName,
    required this.address,
    required this.phoneNumber,
    required this.familySize,
    required this.monthlyIncome,
    required this.latitude,
    required this.longitude,
    required this.otpCode,
    required this.signaturePath,
    required this.createdAt,
    this.isSynced = false,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'householdId': householdId,
      'householdHeadName': householdHeadName,
      'address': address,
      'phoneNumber': phoneNumber,
      'familySize': familySize,
      'monthlyIncome': monthlyIncome,
      'latitude': latitude,
      'longitude': longitude,
      'otpCode': otpCode,
      'signaturePath': signaturePath,
      'createdAt': createdAt.toIso8601String(),
      'isSynced': isSynced ? 1 : 0,
    };
  }

  factory DPR.fromMap(Map<String, dynamic> map) {
    return DPR(
      id: map['id'],
      householdId: map['householdId'],
      householdHeadName: map['householdHeadName'],
      address: map['address'],
      phoneNumber: map['phoneNumber'],
      familySize: map['familySize'],
      monthlyIncome: map['monthlyIncome'],
      latitude: map['latitude'],
      longitude: map['longitude'],
      otpCode: map['otpCode'],
      signaturePath: map['signaturePath'],
      createdAt: DateTime.parse(map['createdAt']),
      isSynced: map['isSynced'] == 1,
    );
  }

  DPR copyWith({
    int? id,
    String? householdId,
    String? householdHeadName,
    String? address,
    String? phoneNumber,
    int? familySize,
    double? monthlyIncome,
    double? latitude,
    double? longitude,
    String? otpCode,
    String? signaturePath,
    DateTime? createdAt,
    bool? isSynced,
  }) {
    return DPR(
      id: id ?? this.id,
      householdId: householdId ?? this.householdId,
      householdHeadName: householdHeadName ?? this.householdHeadName,
      address: address ?? this.address,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      familySize: familySize ?? this.familySize,
      monthlyIncome: monthlyIncome ?? this.monthlyIncome,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      otpCode: otpCode ?? this.otpCode,
      signaturePath: signaturePath ?? this.signaturePath,
      createdAt: createdAt ?? this.createdAt,
      isSynced: isSynced ?? this.isSynced,
    );
  }
} 