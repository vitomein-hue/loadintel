import 'dart:convert';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:excel/excel.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter/material.dart';
import 'package:loadintel/domain/models/load_recipe.dart';
import 'package:loadintel/domain/models/range_result.dart';
import 'package:loadintel/domain/models/target_photo.dart';
import 'package:loadintel/domain/repositories/load_recipe_repository.dart';
import 'package:loadintel/domain/repositories/range_result_repository.dart';
import 'package:loadintel/domain/repositories/settings_repository.dart';
import 'package:loadintel/domain/repositories/target_photo_repository.dart';
import 'package:loadintel/features/backup_export/share_load_card.dart';
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

    final loadsBytes = _encodeCsvForExcel(_buildLoadsCsv(loads));
    final resultsBytes = _encodeCsvForExcel(_buildResultsCsv(results));

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
    final brandImage = await _loadBrandImage();

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
          build: (context) =>
              _buildReport(load, bestResult, photos, brandImage),
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

  Future<XFile> exportSingleLoadCsv(LoadRecipe load) async {
    final results = await _rangeRepo.listResultsByLoad(load.id);
    final csvText = _buildSingleLoadCsv(load, results);
    final csvBytes = _encodeCsvForExcel(csvText);
    final fileName = _singleLoadFileName(load.id, 'csv');
    final directory = await getTemporaryDirectory();
    final filePath = path.join(directory.path, fileName);
    await File(filePath).writeAsBytes(csvBytes, flush: true);
    return XFile(filePath, mimeType: 'text/csv', name: fileName);
  }

  Future<XFile> exportSingleLoadXlsx(LoadRecipe load) async {
    final results = await _rangeRepo.listResultsByLoad(load.id);
    final bytes = _buildSingleLoadXlsx(load, results);
    final fileName = _singleLoadFileName(load.id, 'xlsx');
    final filePath = await _writeTempExportFile(fileName, bytes);
    return XFile(
      filePath,
      mimeType:
          'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet',
      name: fileName,
    );
  }

  Future<XFile> exportSingleLoadPdf(LoadRecipe load) async {
    final bestResult = await _rangeRepo.getBestResultForLoad(load.id);
    final photos = bestResult == null
        ? <TargetPhoto>[]
        : await _photoRepo.listPhotosForResult(bestResult.id);
    final brandImage = await _loadBrandImage();
    final doc = pw.Document();
    doc.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.letter,
        build: (context) => _buildReport(load, bestResult, photos, brandImage),
      ),
    );
    final fileName = _singleLoadFileName(load.id, 'pdf');
    final filePath = await _writeTempExportFile(fileName, await doc.save());
    return XFile(filePath, mimeType: 'application/pdf', name: fileName);
  }

  Future<XFile> exportSingleLoadTxt(LoadRecipe load) async {
    final results = await _rangeRepo.listResultsByLoad(load.id);
    final bestResult = await _rangeRepo.getBestResultForLoad(load.id);
    final text = _buildSingleLoadTxt(load, bestResult, results);
    final bytes = Uint8List.fromList(utf8.encode(text));
    final fileName = _singleLoadFileName(load.id, 'txt');
    final filePath = await _writeTempExportFile(fileName, bytes);
    return XFile(filePath, mimeType: 'text/plain', name: fileName);
  }

  Future<XFile> saveSingleLoadPng({
    required BuildContext context,
    required LoadRecipe load,
  }) async {
    final bestResult = await _rangeRepo.getBestResultForLoad(load.id);
    final photos = bestResult == null
        ? <TargetPhoto>[]
        : await _photoRepo.listPhotosForResult(bestResult.id);
    final content = buildReportContent(
      load: load,
      bestResult: bestResult,
      photos: photos,
    );
    final card = ShareLoadCard(content: content);
    final pngBytes = await _captureWidgetPng(
      context: context,
      child: card,
      size: ShareLoadCard.cardSize,
    );
    final fileName = _singleLoadFileName(load.id, 'png');
    final filePath = await _writeTempExportFile(fileName, pngBytes);
    return XFile(filePath, mimeType: 'image/png', name: fileName);
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
    if (kDebugMode) {
      debugPrint('Exported $fileName -> $filePath');
    }
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
      final location = await _safChannel.invokeMethod<String>('writeFile', {
        'treeUri': treeUri,
        'subDir': _androidSubdirName,
        'fileName': fileName,
        'mimeType': mimeType,
        'bytes': bytes,
      });
      if (location != null) {
        if (kDebugMode) {
          debugPrint('Exported $fileName -> $location');
        }
      }
      return location;
    } on PlatformException {
      await _settingsRepo.setString(SettingsKeys.exportFolderUri, '');
      treeUri = await _pickAndroidTreeUri();
      if (treeUri == null) {
        return null;
      }
      final location = await _safChannel.invokeMethod<String>('writeFile', {
        'treeUri': treeUri,
        'subDir': _androidSubdirName,
        'fileName': fileName,
        'mimeType': mimeType,
        'bytes': bytes,
      });
      if (location != null) {
        if (kDebugMode) {
          debugPrint('Exported $fileName -> $location');
        }
      }
      return location;
    }
  }

  Future<String?> _ensureAndroidTreeUri() async {
    final existing = await _settingsRepo.getString(
      SettingsKeys.exportFolderUri,
    );
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

  Future<String> _writeTempExportFile(String fileName, Uint8List bytes) async {
    final directory = await getTemporaryDirectory();
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

  Future<Uint8List> _captureWidgetPng({
    required BuildContext context,
    required Widget child,
    required Size size,
  }) async {
    final overlay = Overlay.of(context);
    final boundaryKey = GlobalKey();
    final entry = OverlayEntry(
      builder: (_) => Positioned(
        left: 0,
        top: 0,
        width: size.width,
        height: size.height,
        child: IgnorePointer(
          child: Opacity(
            opacity: 0,
            child: RepaintBoundary(
              key: boundaryKey,
              child: SizedBox(
                width: size.width,
                height: size.height,
                child: Material(color: Colors.transparent, child: child),
              ),
            ),
          ),
        ),
      ),
    );
    overlay.insert(entry);
    try {
      await WidgetsBinding.instance.endOfFrame;
      final boundary =
          boundaryKey.currentContext?.findRenderObject()
              as RenderRepaintBoundary?;
      if (boundary == null) {
        throw StateError('Unable to capture report.');
      }
      final image = await boundary.toImage(pixelRatio: 3);
      final data = await image.toByteData(format: ui.ImageByteFormat.png);
      image.dispose();
      return data!.buffer.asUint8List();
    } finally {
      entry.remove();
    }
  }

  pw.Widget _buildReport(
    LoadRecipe load,
    RangeResult? best,
    List<TargetPhoto> photos,
    pw.ImageProvider brandImage,
  ) {
    final content = buildReportContent(
      load: load,
      bestResult: best,
      photos: photos,
    );
    final photoBytes = content.photoPath == null
        ? null
        : _safeReadBytesFromPath(content.photoPath!);
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(content.title, style: pw.TextStyle(fontSize: 20)),
        pw.SizedBox(height: 8),
        ...content.loadLines.map(pw.Text.new),
        pw.SizedBox(height: 12),
        pw.Text(content.bestTitle, style: pw.TextStyle(fontSize: 16)),
        if (content.bestLines.isEmpty)
          pw.Text(content.bestEmptyMessage)
        else
          ...content.bestLines.map(pw.Text.new),
        if (photoBytes != null) ...[
          pw.SizedBox(height: 12),
          pw.Text('Target Photo'),
          pw.SizedBox(height: 8),
          pw.Image(pw.MemoryImage(photoBytes), width: 240, height: 240),
        ],
        pw.Spacer(),
        _buildPdfFooter(brandImage),
      ],
    );
  }

  pw.Widget _buildPdfFooter(pw.ImageProvider brandImage) {
    return pw.Padding(
      padding: const pw.EdgeInsets.only(top: 16, right: 20, bottom: 12),
      child: pw.Align(
        alignment: pw.Alignment.bottomRight,
        child: pw.Opacity(
          opacity: 0.7,
          child: pw.Image(
            brandImage,
            width: 72,
            height: 20,
            fit: pw.BoxFit.contain,
          ),
        ),
      ),
    );
  }

  Future<pw.ImageProvider> _loadBrandImage() async {
    final data = await rootBundle.load('assets/brand.png');
    return pw.MemoryImage(data.buffer.asUint8List());
  }

  Uint8List? _safeReadBytesFromPath(String pathValue) {
    try {
      return Uint8List.fromList(File(pathValue).readAsBytesSync());
    } catch (_) {
      return null;
    }
  }

  String _buildLoadsCsv(List<LoadRecipe> loads) {
    final buffer = StringBuffer();
    final grouped = <LoadType, List<LoadRecipe>>{
      LoadType.rifle: [],
      LoadType.shotgun: [],
      LoadType.muzzleloader: [],
    };
    for (final load in loads) {
      grouped[load.loadType]?.add(load);
    }

    for (final type in [
      LoadType.rifle,
      LoadType.shotgun,
      LoadType.muzzleloader,
    ]) {
      final sectionLoads = grouped[type] ?? [];
      if (sectionLoads.isEmpty) {
        continue;
      }
      buffer.writeln(_sectionTitleForType(type));
      buffer.writeln(_headersForType(type).join(','));
      for (final load in sectionLoads) {
        buffer.writeln(_valuesForType(load).map(_csvEscape).join(','));
      }
      buffer.writeln();
    }
    return buffer.toString();
  }

  String _buildResultsCsv(List<RangeResult> results) {
    final buffer = StringBuffer();
    buffer.writeln(
      'id,loadId,testedAt,firearmId,distanceYds,roundsTested,fpsShots,avgFps,sdFps,esFps,groupSizeIn,notes,createdAt,updatedAt',
    );
    for (final result in results) {
      buffer.writeln(
        [
          result.id,
          result.loadId,
          result.testedAt.toIso8601String(),
          result.firearmId,
          result.distanceYds,
          result.roundsTested,
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

  String _sectionTitleForType(LoadType type) {
    switch (type) {
      case LoadType.rifle:
        return 'Rifle/Pistol Loads';
      case LoadType.shotgun:
        return 'Shotgun Loads';
      case LoadType.muzzleloader:
        return 'Muzzleloader Loads';
    }
  }

  List<String> _headersForType(LoadType type) {
    switch (type) {
      case LoadType.rifle:
        return [
          'id',
          'recipeName',
          'cartridge',
          'bulletBrand',
          'bulletWeightGr',
          'bulletDiameter',
          'bulletType',
          'brass',
          'brassTrimLength',
          'annealingTimeSec',
          'primer',
          'caseResize',
          'gasCheckMaterial',
          'gasCheckInstallMethod',
          'bulletCoating',
          'powder',
          'powderChargeGr',
          'coal',
          'baseToOgive',
          'seatingDepth',
          'notes',
          'firearmId',
          'isKeeper',
          'isDangerous',
          'dangerConfirmedAt',
          'createdAt',
          'updatedAt',
        ];
      case LoadType.shotgun:
        return [
          'id',
          'recipeName',
          'gauge',
          'shellLength',
          'hull',
          'shotgunPrimer',
          'shotgunPowder',
          'shotgunPowderCharge',
          'wad',
          'shotWeight',
          'shotSize',
          'shotType',
          'crimpType',
          'dramEquivalent',
          'notes',
          'firearmId',
          'isKeeper',
          'isDangerous',
          'dangerConfirmedAt',
          'createdAt',
          'updatedAt',
        ];
      case LoadType.muzzleloader:
        return [
          'id',
          'recipeName',
          'muzzleloaderCaliber',
          'ignitionType',
          'muzzleloaderPowderType',
          'powderGranulation',
          'muzzleloaderPowderCharge',
          'projectileType',
          'projectileSizeWeight',
          'patchMaterial',
          'patchThickness',
          'patchLube',
          'sabotType',
          'cleanedBetweenShots',
          'notes',
          'firearmId',
          'isKeeper',
          'isDangerous',
          'dangerConfirmedAt',
          'createdAt',
          'updatedAt',
        ];
    }
  }

  List<Object?> _valuesForType(LoadRecipe load) {
    switch (load.loadType) {
      case LoadType.rifle:
        return [
          load.id,
          load.recipeName,
          load.cartridge,
          load.bulletBrand,
          load.bulletWeightGr,
          load.bulletDiameter,
          load.bulletType,
          load.brass,
          load.brassTrimLength,
          load.annealingTimeSec,
          load.primer,
          load.caseResize,
          load.gasCheckMaterial,
          load.gasCheckInstallMethod,
          load.bulletCoating,
          load.powder,
          load.powderChargeGr,
          load.coal,
          load.baseToOgive,
          load.seatingDepth,
          load.notes,
          load.firearmId ?? '',
          load.isKeeper ? 1 : 0,
          load.isDangerous ? 1 : 0,
          load.dangerConfirmedAt?.toIso8601String(),
          load.createdAt.toIso8601String(),
          load.updatedAt.toIso8601String(),
        ];
      case LoadType.shotgun:
        return [
          load.id,
          load.recipeName,
          load.gauge,
          load.shellLength,
          load.hull,
          load.shotgunPrimer,
          load.shotgunPowder,
          load.shotgunPowderCharge,
          load.wad,
          load.shotWeight,
          load.shotSize,
          load.shotType,
          load.crimpType,
          load.dramEquivalent,
          load.notes,
          load.firearmId ?? '',
          load.isKeeper ? 1 : 0,
          load.isDangerous ? 1 : 0,
          load.dangerConfirmedAt?.toIso8601String(),
          load.createdAt.toIso8601String(),
          load.updatedAt.toIso8601String(),
        ];
      case LoadType.muzzleloader:
        return [
          load.id,
          load.recipeName,
          load.muzzleloaderCaliber,
          load.ignitionType,
          load.muzzleloaderPowderType,
          load.powderGranulation,
          load.muzzleloaderPowderCharge,
          load.projectileType,
          load.projectileSizeWeight,
          load.patchMaterial,
          load.patchThickness,
          load.patchLube,
          load.sabotType,
          _boolToInt(load.cleanedBetweenShots),
          load.notes,
          load.firearmId ?? '',
          load.isKeeper ? 1 : 0,
          load.isDangerous ? 1 : 0,
          load.dangerConfirmedAt?.toIso8601String(),
          load.createdAt.toIso8601String(),
          load.updatedAt.toIso8601String(),
        ];
    }
  }

  int? _boolToInt(bool? value) {
    if (value == null) {
      return null;
    }
    return value ? 1 : 0;
  }

  Uint8List _encodeCsvForExcel(String csvText) {
    final normalized = csvText
        .replaceAll('\r\n', '\n')
        .replaceAll('\n', '\r\n');
    final bytes = utf8.encode(normalized);
    final withBom = Uint8List(bytes.length + 3)
      ..[0] = 0xEF
      ..[1] = 0xBB
      ..[2] = 0xBF
      ..setRange(3, bytes.length + 3, bytes);
    return withBom;
  }


  String _buildSingleLoadCsv(LoadRecipe load, List<RangeResult> results) {
    final buffer = StringBuffer();
    buffer.writeln('Load');
    buffer.writeln(_headersForType(load.loadType).join(','));
    buffer.writeln(_valuesForType(load).map(_csvEscape).join(','));
    buffer.writeln();
    buffer.writeln('Results');
    buffer.writeln(
      'id,loadId,testedAt,firearmId,distanceYds,roundsTested,fpsShots,avgFps,sdFps,esFps,groupSizeIn,notes,createdAt,updatedAt',
    );
    for (final result in results) {
      buffer.writeln(
        [
          result.id,
          result.loadId,
          result.testedAt.toIso8601String(),
          result.firearmId,
          result.distanceYds,
          result.roundsTested,
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

  Uint8List _buildSingleLoadXlsx(LoadRecipe load, List<RangeResult> results) {
    final excel = Excel.createExcel();
    final loadSheet = excel['Load'];
    final loadHeaders = _headersForType(load.loadType);
    loadSheet.appendRow(
      loadHeaders.map((value) => TextCellValue(value)).toList(),
    );
    loadSheet.appendRow(
      _valuesForType(
        load,
      ).map((value) => TextCellValue(value?.toString() ?? '')).toList(),
    );

    final resultsSheet = excel['Results'];
    resultsSheet.appendRow([
      TextCellValue('id'),
      TextCellValue('loadId'),
      TextCellValue('testedAt'),
      TextCellValue('firearmId'),
      TextCellValue('distanceYds'),
      TextCellValue('roundsTested'),
      TextCellValue('fpsShots'),
      TextCellValue('avgFps'),
      TextCellValue('sdFps'),
      TextCellValue('esFps'),
      TextCellValue('groupSizeIn'),
      TextCellValue('notes'),
      TextCellValue('createdAt'),
      TextCellValue('updatedAt'),
    ]);
    for (final result in results) {
      resultsSheet.appendRow([
        TextCellValue(result.id),
        TextCellValue(result.loadId),
        TextCellValue(result.testedAt.toIso8601String()),
        TextCellValue(result.firearmId),
        TextCellValue(result.distanceYds.toString()),
        TextCellValue(result.roundsTested?.toString() ?? ''),
        TextCellValue(jsonEncode(result.fpsShots)),
        TextCellValue(result.avgFps?.toString() ?? ''),
        TextCellValue(result.sdFps?.toString() ?? ''),
        TextCellValue(result.esFps?.toString() ?? ''),
        TextCellValue(result.groupSizeIn.toString()),
        TextCellValue(result.notes ?? ''),
        TextCellValue(result.createdAt.toIso8601String()),
        TextCellValue(result.updatedAt.toIso8601String()),
      ]);
    }

    final bytes = excel.encode();
    if (bytes == null) {
      throw StateError('Unable to generate XLSX.');
    }
    return Uint8List.fromList(bytes);
  }

  String _buildSingleLoadTxt(
    LoadRecipe load,
    RangeResult? best,
    List<RangeResult> results,
  ) {
    final buffer = StringBuffer();
    buffer.writeln('Load Intel - Load Card');
    buffer.writeln('Load Type: ${load.loadType.label}');
    buffer.writeln('Recipe: ${load.recipeName}');
    switch (load.loadType) {
      case LoadType.rifle:
        buffer.writeln('Cartridge: ${load.cartridge}');
        buffer.writeln(
          'Bullet: ${load.bulletBrand ?? '-'} ${load.bulletWeightGr ?? ''} ${load.bulletType ?? ''}',
        );
        buffer.writeln('Powder: ${load.powder} ${load.powderChargeGr} gr');
        buffer.writeln('Brass: ${load.brass ?? '-'}');
        buffer.writeln('Brass Trim Length: ${load.brassTrimLength ?? '-'}');
        buffer.writeln('Annealing Time: ${load.annealingTimeSec ?? '-'} sec');
        buffer.writeln('Primer: ${load.primer ?? '-'}');
        buffer.writeln('COAL: ${load.coal ?? '-'}');
        buffer.writeln('Base to Ogive: ${load.baseToOgive ?? '-'}');
        buffer.writeln('Seating Depth: ${load.seatingDepth ?? '-'}');
        break;
      case LoadType.shotgun:
        buffer.writeln('Gauge: ${load.gauge ?? '-'}');
        buffer.writeln('Shell Length: ${load.shellLength ?? '-'}');
        buffer.writeln('Hull: ${load.hull ?? '-'}');
        buffer.writeln('Primer: ${load.shotgunPrimer ?? '-'}');
        buffer.writeln(
          'Powder: ${load.shotgunPowder ?? '-'} ${load.shotgunPowderCharge ?? '-'} gr',
        );
        buffer.writeln('Wad: ${load.wad ?? '-'}');
        buffer.writeln('Shot Weight: ${load.shotWeight ?? '-'}');
        buffer.writeln('Shot Size: ${load.shotSize ?? '-'}');
        buffer.writeln('Shot Type: ${load.shotType ?? '-'}');
        buffer.writeln('Crimp Type: ${load.crimpType ?? '-'}');
        if (load.dramEquivalent != null) {
          buffer.writeln('Dram Equivalent: ${load.dramEquivalent}');
        }
        break;
      case LoadType.muzzleloader:
        buffer.writeln('Caliber: ${load.muzzleloaderCaliber ?? '-'}');
        buffer.writeln('Ignition Type: ${load.ignitionType ?? '-'}');
        buffer.writeln(
          'Powder: ${load.muzzleloaderPowderType ?? '-'} (${load.powderGranulation ?? '-'})',
        );
        buffer.writeln(
          'Powder Charge: ${load.muzzleloaderPowderCharge ?? '-'} gr (by volume)',
        );
        buffer.writeln('Projectile Type: ${load.projectileType ?? '-'}');
        buffer.writeln(
          'Projectile Size/Weight: ${load.projectileSizeWeight ?? '-'}',
        );
        if (load.patchMaterial != null && load.patchMaterial!.isNotEmpty) {
          buffer.writeln('Patch Material: ${load.patchMaterial}');
        }
        if (load.patchThickness != null && load.patchThickness!.isNotEmpty) {
          buffer.writeln('Patch Thickness: ${load.patchThickness}');
        }
        if (load.patchLube != null && load.patchLube!.isNotEmpty) {
          buffer.writeln('Patch Lube: ${load.patchLube}');
        }
        if (load.sabotType != null && load.sabotType!.isNotEmpty) {
          buffer.writeln('Sabot Type: ${load.sabotType}');
        }
        buffer.writeln(
          'Cleaned Between Shots: ${load.cleanedBetweenShots == true ? 'Yes' : 'No'}',
        );
        break;
    }
    buffer.writeln('Keeper: ${load.isKeeper ? 'YES' : 'No'}');
    buffer.writeln('Dangerous: ${load.isDangerous ? 'YES' : 'No'}');
    if (load.notes != null && load.notes!.trim().isNotEmpty) {
      buffer.writeln('Notes: ${load.notes}');
    }
    buffer.writeln();
    if (best == null) {
      buffer.writeln('Best Result: No results yet.');
    } else {
      buffer.writeln('Best Result');
      buffer.writeln('Tested At: ${best.testedAt.toLocal()}');
      buffer.writeln('Group Size: ${best.groupSizeIn} in');
      buffer.writeln('Rounds Tested: ${best.roundsTested ?? '-'}');
      buffer.writeln('AVG: ${best.avgFps ?? '-'}');
      buffer.writeln('SD: ${best.sdFps ?? '-'}');
      buffer.writeln('ES: ${best.esFps ?? '-'}');
    }
    if (results.isNotEmpty) {
      buffer.writeln();
      buffer.writeln('Results (${results.length})');
      for (final result in results) {
        buffer.writeln(
          '- ${result.testedAt.toLocal().toString().split(' ').first}: '
          'Group ${result.groupSizeIn} in, Rounds ${result.roundsTested ?? '-'}, '
          'AVG ${result.avgFps ?? '-'}, SD ${result.sdFps ?? '-'}, ES ${result.esFps ?? '-'}',
        );
      }
    }
    return buffer.toString();
  }

  String _reportFileName(LoadRecipe load, String stamp) {
    final safeName = load.recipeName.replaceAll(RegExp(r'[^a-zA-Z0-9_-]'), '_');
    final safeCartridge = load.cartridge.replaceAll(
      RegExp(r'[^a-zA-Z0-9_-]'),
      '_',
    );
    return 'loadintel_${safeCartridge}_${safeName}_$stamp.pdf';
  }

  String _singleLoadFileName(String loadId, String extension) {
    return 'loadintel_${loadId}_${_timestampCompact()}.$extension';
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

  String _timestampCompact() {
    final now = DateTime.now();
    return '${now.year}${_two(now.month)}${_two(now.day)}_${_two(now.hour)}${_two(now.minute)}${_two(now.second)}';
  }

  String _two(int value) => value.toString().padLeft(2, '0');
}


