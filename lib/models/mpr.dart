import 'dart:convert';

class MPR {
  final int? id;
  final String nameAndAddress;
  final String districtStateTel;
  final String panelCentre;
  final String centreCode;
  final String returnNo;
  final int familySize;
  final String incomeGroup;
  final String monthAndYear;
  final String occupationOfHead;
  final List<PurchaseItem> items;
  final double latitude;
  final double longitude;
  final String otpCode;
  final DateTime createdAt;
  final bool isSynced;
  final int? backendId; // ID from backend after first sync

  MPR({
    this.id,
    required this.nameAndAddress,
    required this.districtStateTel,
    required this.panelCentre,
    required this.centreCode,
    required this.returnNo,
    required this.familySize,
    required this.incomeGroup,
    required this.monthAndYear,
    required this.occupationOfHead,
    required this.items,
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
      'districtStateTel': districtStateTel,
      'panelCentre': panelCentre,
      'centreCode': centreCode,
      'returnNo': returnNo,
      'familySize': familySize,
      'incomeGroup': incomeGroup,
      'monthAndYear': monthAndYear,
      'occupationOfHead': occupationOfHead,
      'items': items.map((item) => item.toMap()).toList(),
      'latitude': latitude,
      'longitude': longitude,
      'otpCode': otpCode,
      'createdAt': createdAt.toIso8601String(),
      'isSynced': isSynced ? 1 : 0,
      'backendId': backendId,
    };
  }

  factory MPR.fromMap(Map<String, dynamic> map) {
    List<PurchaseItem> items = [];
    
    // Handle items from database (JSON string) or from memory (List)
    if (map['items'] is String) {
      // Parse JSON string from database
      final List<dynamic> itemsList = jsonDecode(map['items']);
      items = itemsList.map((item) => PurchaseItem.fromMap(item)).toList();
    } else if (map['items'] is List) {
      // Handle List from memory
      items = (map['items'] as List)
          .map((item) => PurchaseItem.fromMap(item))
          .toList();
    }
    
    return MPR(
      id: map['id'],
      nameAndAddress: map['nameAndAddress'],
      districtStateTel: map['districtStateTel'],
      panelCentre: map['panelCentre'],
      centreCode: map['centreCode'],
      returnNo: map['returnNo'],
      familySize: map['familySize'],
      incomeGroup: map['incomeGroup'],
      monthAndYear: map['monthAndYear'],
      occupationOfHead: map['occupationOfHead'],
      items: items,
      latitude: map['latitude'],
      longitude: map['longitude'],
      otpCode: map['otpCode'],
      createdAt: DateTime.parse(map['createdAt']),
      isSynced: map['isSynced'] == 1,
      backendId: map['backendId'],
    );
  }

  MPR copyWith({
    int? id,
    String? nameAndAddress,
    String? districtStateTel,
    String? panelCentre,
    String? centreCode,
    String? returnNo,
    int? familySize,
    String? incomeGroup,
    String? monthAndYear,
    String? occupationOfHead,
    List<PurchaseItem>? items,
    double? latitude,
    double? longitude,
    String? otpCode,
    DateTime? createdAt,
    bool? isSynced,
    int? backendId,
  }) {
    return MPR(
      id: id ?? this.id,
      nameAndAddress: nameAndAddress ?? this.nameAndAddress,
      districtStateTel: districtStateTel ?? this.districtStateTel,
      panelCentre: panelCentre ?? this.panelCentre,
      centreCode: centreCode ?? this.centreCode,
      returnNo: returnNo ?? this.returnNo,
      familySize: familySize ?? this.familySize,
      incomeGroup: incomeGroup ?? this.incomeGroup,
      monthAndYear: monthAndYear ?? this.monthAndYear,
      occupationOfHead: occupationOfHead ?? this.occupationOfHead,
      items: items ?? this.items,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      otpCode: otpCode ?? this.otpCode,
      createdAt: createdAt ?? this.createdAt,
      isSynced: isSynced ?? this.isSynced,
      backendId: backendId ?? this.backendId,
    );
  }
}

class PurchaseItem {
  final int? id;
  final String itemName;
  final String itemCode;
  final String monthOfPurchase;
  final String fibreCode;
  final String sectorOfManufactureCode;
  final String colourDesignCode;
  final String personAgeGender;
  final String typeOfShopCode;
  final String purchaseTypeCode;
  final String dressIntendedCode;
  final double lengthInMeters;
  final double pricePerMeter;
  final double totalAmountPaid;
  final String brandMillName;
  final bool isImported;

  PurchaseItem({
    this.id,
    required this.itemName,
    required this.itemCode,
    required this.monthOfPurchase,
    required this.fibreCode,
    required this.sectorOfManufactureCode,
    required this.colourDesignCode,
    required this.personAgeGender,
    required this.typeOfShopCode,
    required this.purchaseTypeCode,
    required this.dressIntendedCode,
    required this.lengthInMeters,
    required this.pricePerMeter,
    required this.totalAmountPaid,
    required this.brandMillName,
    required this.isImported,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'itemName': itemName,
      'itemCode': itemCode,
      'monthOfPurchase': monthOfPurchase,
      'fibreCode': fibreCode,
      'sectorOfManufactureCode': sectorOfManufactureCode,
      'colourDesignCode': colourDesignCode,
      'personAgeGender': personAgeGender,
      'typeOfShopCode': typeOfShopCode,
      'purchaseTypeCode': purchaseTypeCode,
      'dressIntendedCode': dressIntendedCode,
      'lengthInMeters': lengthInMeters,
      'pricePerMeter': pricePerMeter,
      'totalAmountPaid': totalAmountPaid,
      'brandMillName': brandMillName,
      'isImported': isImported ? 1 : 0,
    };
  }

  factory PurchaseItem.fromMap(Map<String, dynamic> map) {
    return PurchaseItem(
      id: map['id'],
      itemName: map['itemName'],
      itemCode: map['itemCode'],
      monthOfPurchase: map['monthOfPurchase'],
      fibreCode: map['fibreCode'],
      sectorOfManufactureCode: map['sectorOfManufactureCode'],
      colourDesignCode: map['colourDesignCode'],
      personAgeGender: map['personAgeGender'],
      typeOfShopCode: map['typeOfShopCode'],
      purchaseTypeCode: map['purchaseTypeCode'],
      dressIntendedCode: map['dressIntendedCode'],
      lengthInMeters: map['lengthInMeters'],
      pricePerMeter: map['pricePerMeter'],
      totalAmountPaid: map['totalAmountPaid'],
      brandMillName: map['brandMillName'],
      isImported: map['isImported'] == 1,
    );
  }

  PurchaseItem copyWith({
    int? id,
    String? itemName,
    String? itemCode,
    String? monthOfPurchase,
    String? fibreCode,
    String? sectorOfManufactureCode,
    String? colourDesignCode,
    String? personAgeGender,
    String? typeOfShopCode,
    String? purchaseTypeCode,
    String? dressIntendedCode,
    double? lengthInMeters,
    double? pricePerMeter,
    double? totalAmountPaid,
    String? brandMillName,
    bool? isImported,
  }) {
    return PurchaseItem(
      id: id ?? this.id,
      itemName: itemName ?? this.itemName,
      itemCode: itemCode ?? this.itemCode,
      monthOfPurchase: monthOfPurchase ?? this.monthOfPurchase,
      fibreCode: fibreCode ?? this.fibreCode,
      sectorOfManufactureCode: sectorOfManufactureCode ?? this.sectorOfManufactureCode,
      colourDesignCode: colourDesignCode ?? this.colourDesignCode,
      personAgeGender: personAgeGender ?? this.personAgeGender,
      typeOfShopCode: typeOfShopCode ?? this.typeOfShopCode,
      purchaseTypeCode: purchaseTypeCode ?? this.purchaseTypeCode,
      dressIntendedCode: dressIntendedCode ?? this.dressIntendedCode,
      lengthInMeters: lengthInMeters ?? this.lengthInMeters,
      pricePerMeter: pricePerMeter ?? this.pricePerMeter,
      totalAmountPaid: totalAmountPaid ?? this.totalAmountPaid,
      brandMillName: brandMillName ?? this.brandMillName,
      isImported: isImported ?? this.isImported,
    );
  }
} 