import 'dart:convert';

class DPR {
  final int? id;
  final String nameAndAddress;
  final String district;
  final String state;
  final int familySize;
  final String incomeGroup;
  final String centreCode;
  final String returnNo;
  final String monthAndYear;
  final List<HouseholdMember> householdMembers;
  final double latitude;
  final double longitude;
  final String otpCode;
  final DateTime createdAt;
  final bool isSynced;
  final int? backendId; // ID from backend after first sync

  DPR({
    this.id,
    required this.nameAndAddress,
    required this.district,
    required this.state,
    required this.familySize,
    required this.incomeGroup,
    required this.centreCode,
    required this.returnNo,
    required this.monthAndYear,
    required this.householdMembers,
    required this.latitude,
    required this.longitude,
    required this.otpCode,
    required this.createdAt,
    this.isSynced = false,
    this.backendId,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'nameAndAddress': nameAndAddress,
      'district': district,
      'state': state,
      'familySize': familySize,
      'incomeGroup': incomeGroup,
      'centreCode': centreCode,
      'returnNo': returnNo,
      'monthAndYear': monthAndYear,
      'householdMembers': householdMembers.map((member) => member.toMap()).toList(),
      'latitude': latitude,
      'longitude': longitude,
      'otpCode': otpCode,
      'createdAt': createdAt.toIso8601String(),
      'isSynced': isSynced ? 1 : 0,
      'backendId': backendId,
    };
  }

  factory DPR.fromMap(Map<String, dynamic> map) {
    List<HouseholdMember> members = [];
    
    // Handle householdMembers from database (JSON string) or from memory (List)
    if (map['householdMembers'] is String) {
      // Parse JSON string from database
      final List<dynamic> membersList = jsonDecode(map['householdMembers']);
      members = membersList.map((member) => HouseholdMember.fromMap(member)).toList();
    } else if (map['householdMembers'] is List) {
      // Handle List from memory
      members = (map['householdMembers'] as List)
          .map((member) => HouseholdMember.fromMap(member))
          .toList();
    }
    
    return DPR(
      id: map['id'],
      nameAndAddress: map['nameAndAddress'],
      district: map['district'],
      state: map['state'],
      familySize: map['familySize'],
      incomeGroup: map['incomeGroup'],
      centreCode: map['centreCode'],
      returnNo: map['returnNo'],
      monthAndYear: map['monthAndYear'],
      householdMembers: members,
      latitude: map['latitude'],
      longitude: map['longitude'],
      otpCode: map['otpCode'],
      createdAt: DateTime.parse(map['createdAt']),
      isSynced: map['isSynced'] == 1,
      backendId: map['backendId'],
    );
  }

  DPR copyWith({
    int? id,
    String? nameAndAddress,
    String? district,
    String? state,
    int? familySize,
    String? incomeGroup,
    String? centreCode,
    String? returnNo,
    String? monthAndYear,
    List<HouseholdMember>? householdMembers,
    double? latitude,
    double? longitude,
    String? otpCode,
    DateTime? createdAt,
    bool? isSynced,
    int? backendId,
  }) {
    return DPR(
      id: id ?? this.id,
      nameAndAddress: nameAndAddress ?? this.nameAndAddress,
      district: district ?? this.district,
      state: state ?? this.state,
      familySize: familySize ?? this.familySize,
      incomeGroup: incomeGroup ?? this.incomeGroup,
      centreCode: centreCode ?? this.centreCode,
      returnNo: returnNo ?? this.returnNo,
      monthAndYear: monthAndYear ?? this.monthAndYear,
      householdMembers: householdMembers ?? this.householdMembers,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      otpCode: otpCode ?? this.otpCode,
      createdAt: createdAt ?? this.createdAt,
      isSynced: isSynced ?? this.isSynced,
      backendId: backendId ?? this.backendId,
    );
  }
}

class HouseholdMember {
  final int? id;
  final String name;
  final String relationshipWithHead;
  final String gender;
  final int age;
  final String education;
  final String occupation;
  final double annualIncomeJob;
  final double annualIncomeOther;
  final String otherIncomeSource;
  final double totalIncome;

  HouseholdMember({
    this.id,
    required this.name,
    required this.relationshipWithHead,
    required this.gender,
    required this.age,
    required this.education,
    required this.occupation,
    required this.annualIncomeJob,
    required this.annualIncomeOther,
    required this.otherIncomeSource,
    required this.totalIncome,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'relationshipWithHead': relationshipWithHead,
      'gender': gender,
      'age': age,
      'education': education,
      'occupation': occupation,
      'annualIncomeJob': annualIncomeJob,
      'annualIncomeOther': annualIncomeOther,
      'otherIncomeSource': otherIncomeSource,
      'totalIncome': totalIncome,
    };
  }

  factory HouseholdMember.fromMap(Map<String, dynamic> map) {
    return HouseholdMember(
      id: map['id'],
      name: map['name'],
      relationshipWithHead: map['relationshipWithHead'],
      gender: map['gender'],
      age: map['age'],
      education: map['education'],
      occupation: map['occupation'],
      annualIncomeJob: map['annualIncomeJob'],
      annualIncomeOther: map['annualIncomeOther'],
      otherIncomeSource: map['otherIncomeSource'],
      totalIncome: map['totalIncome'],
    );
  }

  HouseholdMember copyWith({
    int? id,
    String? name,
    String? relationshipWithHead,
    String? gender,
    int? age,
    String? education,
    String? occupation,
    double? annualIncomeJob,
    double? annualIncomeOther,
    String? otherIncomeSource,
    double? totalIncome,
  }) {
    return HouseholdMember(
      id: id ?? this.id,
      name: name ?? this.name,
      relationshipWithHead: relationshipWithHead ?? this.relationshipWithHead,
      gender: gender ?? this.gender,
      age: age ?? this.age,
      education: education ?? this.education,
      occupation: occupation ?? this.occupation,
      annualIncomeJob: annualIncomeJob ?? this.annualIncomeJob,
      annualIncomeOther: annualIncomeOther ?? this.annualIncomeOther,
      otherIncomeSource: otherIncomeSource ?? this.otherIncomeSource,
      totalIncome: totalIncome ?? this.totalIncome,
    );
  }
} 