import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:loadintel/domain/models/load_recipe.dart';
import 'package:loadintel/domain/models/range_result.dart';
import 'package:loadintel/domain/models/target_photo.dart';
import 'package:loadintel/domain/repositories/load_recipe_repository.dart';
import 'package:loadintel/domain/repositories/range_result_repository.dart';
import 'package:loadintel/domain/repositories/target_photo_repository.dart';
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

class ExportService {
  ExportService(
    this._loadRepo,
    this._rangeRepo,
    this._photoRepo,
  );

  final LoadRecipeRepository _loadRepo;
  final RangeResultRepository _rangeRepo;
  final TargetPhotoRepository _photoRepo;

  Future<List<String>> exportCsv() async {
    final loads = await _loadRepo.listRecipes();
    final results = <RangeResult>[];
    for (final load in loads) {
      final loadResults = await _rangeRepo.listResultsByLoad(load.id);
      results.addAll(loadResults);
    }

    final dir = await _exportDir();
    final loadsPath = path.join(dir.path, 'loads.csv');
    final resultsPath = path.join(dir.path, 'results.csv');

    await File(loadsPath).writeAsString(_buildLoadsCsv(loads));
    await File(resultsPath).writeAsString(_buildResultsCsv(results));

    return [loadsPath, resultsPath];
  }

  Future<List<String>> exportPdfReports() async {
    final loads = await _loadRepo.listRecipes();
    final dir = await _exportDir();
    final files = <String>[];

    for (final load in loads) {
      final bestResult = await _rangeRepo.getBestResultForLoad(load.id);
      final photos = bestResult == null
          ? <TargetPhoto>[]
          : await _photoRepo.listPhotosForResult(bestResult.id);
      final filePath = path.join(dir.path, _reportFileName(load));
      final doc = pw.Document();
      doc.addPage(
        pw.Page(
          pageFormat: PdfPageFormat.letter,
          build: (context) => _buildReport(load, bestResult, photos),
        ),
      );
      final file = File(filePath);
      await file.writeAsBytes(await doc.save());
      files.add(filePath);
    }
    return files;
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
      'id,recipeName,cartridge,bulletBrand,bulletWeightGr,bulletType,brass,primer,powder,powderChargeGr,coal,seatingDepth,notes,firearmId,isDangerous,dangerConfirmedAt,createdAt,updatedAt',
    );
    for (final load in loads) {
      buffer.writeln(
        [
          load.id,
          load.recipeName,
          load.cartridge,
          load.bulletBrand,
          load.bulletWeightGr,
          load.bulletType,
          load.brass,
          load.primer,
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

  String _reportFileName(LoadRecipe load) {
    final safeName = load.recipeName.replaceAll(RegExp(r'[^a-zA-Z0-9_-]'), '_');
    return 'report_${load.cartridge}_$safeName.pdf';
  }

  Future<Directory> _exportDir() async {
    final directory = await getApplicationDocumentsDirectory();
    final exportDir = Directory(path.join(directory.path, 'exports'));
    if (!exportDir.existsSync()) {
      await exportDir.create(recursive: true);
    }
    return exportDir;
  }
}
