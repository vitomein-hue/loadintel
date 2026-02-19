enum FirearmType { rifle, pistol, muzzleloader }

extension FirearmTypeX on FirearmType {
  String get storageValue => name;

  static FirearmType fromStorage(String value) {
    switch (value) {
      case 'rifle':
        return FirearmType.rifle;
      case 'pistol':
        return FirearmType.pistol;
      case 'muzzleloader':
        return FirearmType.muzzleloader;
      default:
        return FirearmType.rifle;
    }
  }
}

class Firearm {
  const Firearm({required this.id, required this.name, required this.type});

  final String id;
  final String name;
  final FirearmType type;

  Firearm copyWith({String? id, String? name, FirearmType? type}) {
    return Firearm(
      id: id ?? this.id,
      name: name ?? this.name,
      type: type ?? this.type,
    );
  }

  Map<String, Object?> toMap() {
    return {'id': id, 'name': name, 'type': type.storageValue};
  }

  static Firearm fromMap(Map<String, Object?> map) {
    return Firearm(
      id: map['id'] as String,
      name: map['name'] as String,
      type: FirearmTypeX.fromStorage(map['type'] as String),
    );
  }
}
