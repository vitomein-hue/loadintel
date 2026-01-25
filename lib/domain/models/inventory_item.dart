class InventoryItem {
  const InventoryItem({
    required this.id,
    required this.type,
    required this.name,
    this.qty,
    this.unit,
    this.notes,
    required this.createdAt,
    required this.updatedAt,
  });

  final String id;
  final String type;
  final String name;
  final double? qty;
  final String? unit;
  final String? notes;
  final DateTime createdAt;
  final DateTime updatedAt;

  InventoryItem copyWith({
    String? id,
    String? type,
    String? name,
    double? qty,
    String? unit,
    String? notes,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return InventoryItem(
      id: id ?? this.id,
      type: type ?? this.type,
      name: name ?? this.name,
      qty: qty ?? this.qty,
      unit: unit ?? this.unit,
      notes: notes ?? this.notes,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  Map<String, Object?> toMap({
    required int createdAtMillis,
    required int updatedAtMillis,
  }) {
    return {
      'id': id,
      'type': type,
      'name': name,
      'qty': qty,
      'unit': unit,
      'notes': notes,
      'createdAt': createdAtMillis,
      'updatedAt': updatedAtMillis,
    };
  }

  static InventoryItem fromMap({
    required Map<String, Object?> map,
    required DateTime createdAt,
    required DateTime updatedAt,
  }) {
    return InventoryItem(
      id: map['id'] as String,
      type: map['type'] as String,
      name: map['name'] as String,
      qty: (map['qty'] as num?)?.toDouble(),
      unit: map['unit'] as String?,
      notes: map['notes'] as String?,
      createdAt: createdAt,
      updatedAt: updatedAt,
    );
  }
}

