import 'dart:io';

import 'package:image_picker/image_picker.dart';
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';
import 'package:photo_manager/photo_manager.dart';

class PhotoService {
  PhotoService({ImagePicker? picker}) : _picker = picker ?? ImagePicker();

  static const String _albumName = 'Load Intel';
  static const String _androidRelativePath = 'Pictures/Load Intel';

  final ImagePicker _picker;

  Future<String?> pickFromCamera() async {
    final file = await _picker.pickImage(source: ImageSource.camera);
    return file?.path;
  }

  Future<String?> pickFromGallery() async {
    final file = await _picker.pickImage(source: ImageSource.gallery);
    return file?.path;
  }

  Future<String?> persistAndSave(String sourcePath) async {
    final copied = await _copyToAppStorage(sourcePath);
    await _saveToGallery(copied);
    return copied;
  }

  Future<void> _saveToGallery(String filePath) async {
    final permission = await PhotoManager.requestPermissionExtend();
    if (!permission.hasAccess) {
      return;
    }

    try {
      final asset = await PhotoManager.editor.saveImageWithPath(
        filePath,
        title: path.basename(filePath),
        relativePath: Platform.isAndroid ? _androidRelativePath : null,
      );

      if (Platform.isIOS) {
        final album = await _getOrCreateIosAlbum();
        if (album != null) {
          await PhotoManager.editor.copyAssetToPath(
            asset: asset,
            pathEntity: album,
          );
        }
      }
    } catch (_) {
      return;
    }
  }

  Future<AssetPathEntity?> _getOrCreateIosAlbum() async {
    final paths = await PhotoManager.getAssetPathList(type: RequestType.image);
    for (final pathEntity in paths) {
      if (pathEntity.name == _albumName) {
        return pathEntity;
      }
    }
    try {
      return await PhotoManager.editor.darwin.createAlbum(_albumName);
    } catch (_) {
      return null;
    }
  }

  Future<String> _copyToAppStorage(String sourcePath) async {
    final root = await getApplicationDocumentsDirectory();
    final photosDir = Directory(path.join(root.path, 'loadintel_photos'));
    if (!photosDir.existsSync()) {
      await photosDir.create(recursive: true);
    }
    final fileName = path.basename(sourcePath);
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final targetPath = path.join(photosDir.path, '${timestamp}_$fileName');
    final copied = await File(sourcePath).copy(targetPath);
    return copied.path;
  }
}
