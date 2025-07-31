class MPR {
  final int? id;
  final String householdId;
  final DateTime purchaseDate;
  final String textileType;
  final int quantity;
  final double price;
  final String purchaseLocation;
  final double latitude;
  final double longitude;
  final DateTime createdAt;
  final bool isSynced;

  MPR({
    this.id,
    required this.householdId,
    required this.purchaseDate,
    required this.textileType,
    required this.quantity,
    required this.price,
    required this.purchaseLocation,
    required this.latitude,
    required this.longitude,
    required this.createdAt,
    this.isSynced = false,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'householdId': householdId,
      'purchaseDate': purchaseDate.toIso8601String(),
      'textileType': textileType,
      'quantity': quantity,
      'price': price,
      'purchaseLocation': purchaseLocation,
      'latitude': latitude,
      'longitude': longitude,
      'createdAt': createdAt.toIso8601String(),
      'isSynced': isSynced ? 1 : 0,
    };
  }

  factory MPR.fromMap(Map<String, dynamic> map) {
    return MPR(
      id: map['id'],
      householdId: map['householdId'],
      purchaseDate: DateTime.parse(map['purchaseDate']),
      textileType: map['textileType'],
      quantity: map['quantity'],
      price: map['price'],
      purchaseLocation: map['purchaseLocation'],
      latitude: map['latitude'],
      longitude: map['longitude'],
      createdAt: DateTime.parse(map['createdAt']),
      isSynced: map['isSynced'] == 1,
    );
  }

  MPR copyWith({
    int? id,
    String? householdId,
    DateTime? purchaseDate,
    String? textileType,
    int? quantity,
    double? price,
    String? purchaseLocation,
    double? latitude,
    double? longitude,
    DateTime? createdAt,
    bool? isSynced,
  }) {
    return MPR(
      id: id ?? this.id,
      householdId: householdId ?? this.householdId,
      purchaseDate: purchaseDate ?? this.purchaseDate,
      textileType: textileType ?? this.textileType,
      quantity: quantity ?? this.quantity,
      price: price ?? this.price,
      purchaseLocation: purchaseLocation ?? this.purchaseLocation,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      createdAt: createdAt ?? this.createdAt,
      isSynced: isSynced ?? this.isSynced,
    );
  }
} 