class TargetPhoto {
  const TargetPhoto({
    required this.id,
    required this.rangeResultId,
    required this.galleryPath,
    this.thumbPath,
  });

  final String id;
  final String rangeResultId;
  final String galleryPath;
  final String? thumbPath;

  TargetPhoto copyWith({
    String? id,
    String? rangeResultId,
    String? galleryPath,
    String? thumbPath,
  }) {
    return TargetPhoto(
      id: id ?? this.id,
      rangeResultId: rangeResultId ?? this.rangeResultId,
      galleryPath: galleryPath ?? this.galleryPath,
      thumbPath: thumbPath ?? this.thumbPath,
    );
  }

  Map<String, Object?> toMap() {
    return {
      'id': id,
      'rangeResultId': rangeResultId,
      'galleryPath': galleryPath,
      'thumbPath': thumbPath,
    };
  }

  static TargetPhoto fromMap(Map<String, Object?> map) {
    return TargetPhoto(
      id: map['id'] as String,
      rangeResultId: map['rangeResultId'] as String,
      galleryPath: map['galleryPath'] as String,
      thumbPath: map['thumbPath'] as String?,
    );
  }
}
