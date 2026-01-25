import 'package:loadintel/domain/models/target_photo.dart';

abstract class TargetPhotoRepository {
  Future<void> addPhoto(TargetPhoto photo);
  Future<void> deletePhoto(String id);
  Future<List<TargetPhoto>> listPhotosForResult(String rangeResultId);
}

