import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:loadintel/domain/models/load_recipe.dart';
import 'package:loadintel/domain/models/range_result.dart';
import 'package:loadintel/domain/models/target_photo.dart';
import 'package:loadintel/domain/repositories/load_recipe_repository.dart';
import 'package:loadintel/domain/repositories/range_result_repository.dart';
import 'package:loadintel/domain/repositories/settings_repository.dart';
import 'package:loadintel/domain/repositories/target_photo_repository.dart';
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:share_plus/share_plus.dart';

class ExportService {
  ExportService(
    this._loadRepo,
    this._rangeRepo,
    this._photoRepo,
    this._settingsRepo,
  );

  static const MethodChannel _safChannel = MethodChannel(
    'com.vitomein.loadintel/export',
  );
  static const String _androidSubdirName = 'Load Intel';

  final LoadRecipeRepository _loadRepo;
  final RangeResultRepository _rangeRepo;
  final TargetPhotoRepository _photoRepo;
  final SettingsRepository _settingsRepo;

  Future<List<String>> exportCsv() async {
    final loads = await _loadRepo.listRecipes();
    final results = <RangeResult>[];
    for (final load in loads) {
      final loadResults = await _rangeRepo.listResultsByLoad(load.id);
      results.addAll(loadResults);
    }

    final stamp = _timestamp();
    final files = <String>[];
    final loadsName = 'loadintel_loads_$stamp.csv';
    final resultsName = 'loadintel_results_$stamp.csv';

    final loadsBytes = Uint8List.fromList(utf8.encode(_buildLoadsCsv(loads)));
    final resultsBytes = Uint8List.fromList(utf8.encode(_buildResultsCsv(results)));

    final loadsLocation = await _writeExportFile(
      fileName: loadsName,
      mimeType: 'text/csv',
      bytes: loadsBytes,
    );
    if (loadsLocation == null) {
      return files;
    }
    files.add(loadsLocation);

    final resultsLocation = await _writeExportFile(
      fileName: resultsName,
      mimeType: 'text/csv',
      bytes: resultsBytes,
    );
    if (resultsLocation != null) {
      files.add(resultsLocation);
    }

    await _shareIfNeeded(files, subject: 'Load Intel CSV Export');
    return files;
  }

  Future<List<String>> exportPdfReports() async {
    final loads = await _loadRepo.listRecipes();
    final files = <String>[];
    final stamp = _timestamp();

    for (final load in loads) {
      final bestResult = await _rangeRepo.getBestResultForLoad(load.id);
      final photos = bestResult == null
          ? <TargetPhoto>[]
          : await _photoRepo.listPhotosForResult(bestResult.id);
      final fileName = _reportFileName(load, stamp);
      final doc = pw.Document();
      doc.addPage(
        pw.Page(
          pageFormat: PdfPageFormat.letter,
          build: (context) => _buildReport(load, bestResult, photos),
        ),
      );
      final fileLocation = await _writeExportFile(
        fileName: fileName,
        mimeType: 'application/pdf',
        bytes: await doc.save(),
      );
      if (fileLocation == null) {
        break;
      }
      files.add(fileLocation);
    }

    await _shareIfNeeded(files, subject: 'Load Intel PDF Reports');
    return files;
  }

  Future<String?> _writeExportFile({
    required String fileName,
    required String mimeType,
    required Uint8List bytes,
  }) async {
    if (Platform.isAndroid) {
      return _writeAndroidFile(
        fileName: fileName,
        mimeType: mimeType,
        bytes: bytes,
      );
    }

    final filePath = await _writeLocalExportFile(fileName, bytes);
    debugPrint('Exported $fileName -> $filePath');
    return filePath;
  }

  Future<String?> _writeAndroidFile({
    required String fileName,
    required String mimeType,
    required Uint8List bytes,
  }) async {
    var treeUri = await _ensureAndroidTreeUri();
    if (treeUri == null) {
      return null;
    }

    try {
      final location = await _safChannel.invokeMethod<String>(
        'writeFile',
        {
          'treeUri': treeUri,
          'subDir': _androidSubdirName,
          'fileName': fileName,
          'mimeType': mimeType,
          'bytes': bytes,
        },
      );
      if (location != null) {
        debugPrint('Exported $fileName -> $location');
      }
      return location;
    } on PlatformException {
      await _settingsRepo.setString(SettingsKeys.exportFolderUri, '');
      treeUri = await _pickAndroidTreeUri();
      if (treeUri == null) {
        return null;
      }
      final location = await _safChannel.invokeMethod<String>(
        'writeFile',
        {
          'treeUri': treeUri,
          'subDir': _androidSubdirName,
          'fileName': fileName,
          'mimeType': mimeType,
          'bytes': bytes,
        },
      );
      if (location != null) {
        debugPrint('Exported $fileName -> $location');
      }
      return location;
    }
  }

  Future<String?> _ensureAndroidTreeUri() async {
    final existing = await _settingsRepo.getString(SettingsKeys.exportFolderUri);
    if (existing != null && existing.isNotEmpty) {
      return existing;
    }
    return _pickAndroidTreeUri();
  }

  Future<String?> _pickAndroidTreeUri() async {
    final selected = await _safChannel.invokeMethod<String>('pickDirectory');
    if (selected == null || selected.isEmpty) {
      return null;
    }
    await _settingsRepo.setString(SettingsKeys.exportFolderUri, selected);
    return selected;
  }

  Future<String> _writeLocalExportFile(String fileName, Uint8List bytes) async {
    final directory = await _exportDir();
    final filePath = path.join(directory.path, fileName);
    await File(filePath).writeAsBytes(bytes, flush: true);
    return filePath;
  }

  Future<void> _shareIfNeeded(
    List<String> files, {
    required String subject,
  }) async {
    if (!Platform.isIOS || files.isEmpty) {
      return;
    }
    final xFiles = files.map(XFile.new).toList();
    await Share.shareXFiles(xFiles, subject: subject);
  }

  pw.Widget _buildReport(
    LoadRecipe load,
    RangeResult? best,
    List<TargetPhoto> photos,
  ) {
    final photoBytes = photos.isNotEmpty ? _safeReadBytes(photos.first) : null;
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text('Load Intel Report', style: pw.TextStyle(fontSize: 20)),
        pw.SizedBox(height: 8),
        pw.Text('Recipe: ${load.recipeName}'),
        pw.Text('Cartridge: ${load.cartridge}'),
        pw.Text('Powder: ${load.powder} ${load.powderChargeGr} gr'),
        pw.Text('Bullet: ${load.bulletBrand ?? '-'} ${load.bulletWeightGr ?? ''}'),
        if (load.bulletDiameter != null)
          pw.Text('Bullet Diameter: ${load.bulletDiameter}'),
        if (load.caseResize != null && load.caseResize!.isNotEmpty)
          pw.Text('Case Resize: ${load.caseResize}'),
        if (load.gasCheckMaterial != null && load.gasCheckMaterial!.isNotEmpty)
          pw.Text('Gas Check Material: ${load.gasCheckMaterial}'),
        if (load.gasCheckInstallMethod != null &&
            load.gasCheckInstallMethod!.isNotEmpty)
          pw.Text('Gas Check Install: ${load.gasCheckInstallMethod}'),
        if (load.bulletCoating != null && load.bulletCoating!.isNotEmpty)
          pw.Text('Bullet Coating: ${load.bulletCoating}'),
        pw.Text('Dangerous: ${load.isDangerous ? 'YES' : 'No'}'),
        pw.SizedBox(height: 12),
        pw.Text('Best Result', style: pw.TextStyle(fontSize: 16)),
        if (best == null)
          pw.Text('No results yet.')
        else ...[
          pw.Text('Group Size: ${best.groupSizeIn} in'),
          pw.Text('Tested At: ${best.testedAt.toLocal()}'),
          pw.Text('AVG: ${best.avgFps ?? '-'}'),
          pw.Text('SD: ${best.sdFps ?? '-'}'),
          pw.Text('ES: ${best.esFps ?? '-'}'),
        ],
        if (photoBytes != null) ...[
          pw.SizedBox(height: 12),
          pw.Text('Target Photo'),
          pw.SizedBox(height: 8),
          pw.Image(pw.MemoryImage(photoBytes), width: 240, height: 240),
        ],
      ],
    );
  }

  Uint8List? _safeReadBytes(TargetPhoto photo) {
    final pathValue = photo.thumbPath ?? photo.galleryPath;
    try {
      return Uint8List.fromList(File(pathValue).readAsBytesSync());
    } catch (_) {
      return null;
    }
  }

  String _buildLoadsCsv(List<LoadRecipe> loads) {
    final buffer = StringBuffer();
    buffer.writeln(
      'id,recipeName,cartridge,bulletBrand,bulletWeightGr,bulletDiameter,bulletType,brass,primer,caseResize,gasCheckMaterial,gasCheckInstallMethod,bulletCoating,powder,powderChargeGr,coal,seatingDepth,notes,firearmId,isDangerous,dangerConfirmedAt,createdAt,updatedAt',
    );
    for (final load in loads) {
      buffer.writeln(
        [
          load.id,
          load.recipeName,
          load.cartridge,
          load.bulletBrand,
          load.bulletWeightGr,
          load.bulletDiameter,
          load.bulletType,
          load.brass,
          load.primer,
          load.caseResize,
          load.gasCheckMaterial,
          load.gasCheckInstallMethod,
          load.bulletCoating,
          load.powder,
          load.powderChargeGr,
          load.coal,
          load.seatingDepth,
          load.notes,
          load.firearmId,
          load.isDangerous ? 1 : 0,
          load.dangerConfirmedAt?.toIso8601String(),
          load.createdAt.toIso8601String(),
          load.updatedAt.toIso8601String(),
        ].map(_csvEscape).join(','),
      );
    }
    return buffer.toString();
  }

  String _buildResultsCsv(List<RangeResult> results) {
    final buffer = StringBuffer();
    buffer.writeln(
      'id,loadId,testedAt,firearmId,distanceYds,fpsShots,avgFps,sdFps,esFps,groupSizeIn,notes,createdAt,updatedAt',
    );
    for (final result in results) {
      buffer.writeln(
        [
          result.id,
          result.loadId,
          result.testedAt.toIso8601String(),
          result.firearmId,
          result.distanceYds,
          jsonEncode(result.fpsShots),
          result.avgFps,
          result.sdFps,
          result.esFps,
          result.groupSizeIn,
          result.notes,
          result.createdAt.toIso8601String(),
          result.updatedAt.toIso8601String(),
        ].map(_csvEscape).join(','),
      );
    }
    return buffer.toString();
  }

  String _csvEscape(Object? value) {
    final text = value?.toString() ?? '';
    if (text.contains(',') || text.contains('"') || text.contains('\n')) {
      final escaped = text.replaceAll('"', '""');
      return '"$escaped"';
    }
    return text;
  }

  String _reportFileName(LoadRecipe load, String stamp) {
    final safeName = load.recipeName.replaceAll(RegExp(r'[^a-zA-Z0-9_-]'), '_');
    final safeCartridge = load.cartridge.replaceAll(RegExp(r'[^a-zA-Z0-9_-]'), '_');
    return 'loadintel_${safeCartridge}_${safeName}_$stamp.pdf';
  }

  Future<Directory> _exportDir() async {
    final directory = await getApplicationDocumentsDirectory();
    final exportDir = Directory(path.join(directory.path, 'Exports'));
    if (!exportDir.existsSync()) {
      await exportDir.create(recursive: true);
    }
    return exportDir;
  }

  String _timestamp() {
    final now = DateTime.now();
    return '${now.year}-${_two(now.month)}-${_two(now.day)}_${_two(now.hour)}${_two(now.minute)}${_two(now.second)}';
  }

  String _two(int value) => value.toString().padLeft(2, '0');
}
