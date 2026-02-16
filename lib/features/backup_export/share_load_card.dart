import 'dart:io';

import 'package:flutter/material.dart';
import 'package:loadintel/core/theme/app_colors.dart';
import 'package:loadintel/domain/models/load_recipe.dart';
import 'package:loadintel/domain/models/range_result.dart';
import 'package:loadintel/domain/models/target_photo.dart';

class ShareLoadCard extends StatelessWidget {
  const ShareLoadCard({super.key, required this.content});

  static const Size cardSize = Size(1080, 1350);
  static const double _edgePadding = 48;
  static const double _brandWidth = 140;
  static const double _brandHeight = 36;

  final ReportContent content;

  @override
  Widget build(BuildContext context) {
    final photoPath = content.photoPath;
    return Container(
      width: cardSize.width,
      height: cardSize.height,
      color: AppColors.background,
      child: Stack(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(
              _edgePadding,
              _edgePadding,
              _edgePadding,
              _edgePadding + 80,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  content.title,
                  style: const TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 12),
                ...content.loadLines.map(
                  (line) => Padding(
                    padding: const EdgeInsets.only(bottom: 6),
                    child: Text(line, style: const TextStyle(fontSize: 18)),
                  ),
                ),
                const SizedBox(height: 12),
                _sectionTitle(content.bestTitle),
                const SizedBox(height: 8),
                if (content.bestLines.isEmpty)
                  Text(
                    content.bestEmptyMessage,
                    style: const TextStyle(fontSize: 18),
                  )
                else
                  ...content.bestLines.map(
                    (line) => Padding(
                      padding: const EdgeInsets.only(bottom: 6),
                      child: Text(line, style: const TextStyle(fontSize: 18)),
                    ),
                  ),
                if (photoPath != null) ...[
                  const SizedBox(height: 12),
                  _sectionTitle('Target Photo'),
                  const SizedBox(height: 8),
                  _photoThumb(photoPath),
                ],
                const Spacer(),
              ],
            ),
          ),
          Positioned(
            right: 32,
            bottom: 24,
            child: Opacity(
              opacity: 0.7,
              child: Image.asset(
                'assets/brand.png',
                width: _brandWidth,
                height: _brandHeight,
                fit: BoxFit.contain,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _sectionTitle(String text) {
    return Text(
      text,
      style: const TextStyle(
        fontSize: 22,
        fontWeight: FontWeight.w600,
        color: AppColors.secondary,
      ),
    );
  }

  Widget _photoThumb(String pathValue) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: Image.file(
        File(pathValue),
        width: 240,
        height: 240,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) => Container(
          width: 240,
          height: 240,
          color: AppColors.card,
          alignment: Alignment.center,
          child: const Icon(Icons.image_not_supported),
        ),
      ),
    );
  }
}

class ReportContent {
  const ReportContent({
    required this.title,
    required this.loadLines,
    required this.bestTitle,
    required this.bestLines,
    required this.bestEmptyMessage,
    required this.photoPath,
  });

  final String title;
  final List<String> loadLines;
  final String bestTitle;
  final List<String> bestLines;
  final String bestEmptyMessage;
  final String? photoPath;
}

ReportContent buildReportContent({
  required LoadRecipe load,
  required RangeResult? bestResult,
  required List<TargetPhoto> photos,
}) {
  final loadLines = <String>[
    'Load Type: ${load.loadType.label}',
    'Recipe: ${load.recipeName}',
  ];
  switch (load.loadType) {
    case LoadType.rifle:
      loadLines.addAll([
        'Cartridge: ${load.cartridge}',
        'Powder: ${load.powder} ${load.powderChargeGr} gr',
      ]);
      if (load.annealingTimeSec != null) {
        loadLines.add('Annealing Time: ${load.annealingTimeSec} sec');
      }
      loadLines.add(
        'Bullet: ${load.bulletBrand ?? '-'} ${load.bulletWeightGr ?? ''}',
      );
      if (load.bulletDiameter != null) {
        loadLines.add('Bullet Diameter: ${load.bulletDiameter}');
      }
      if (load.caseResize != null && load.caseResize!.isNotEmpty) {
        loadLines.add('Case Resize: ${load.caseResize}');
      }
      if (load.gasCheckMaterial != null && load.gasCheckMaterial!.isNotEmpty) {
        loadLines.add('Gas Check Material: ${load.gasCheckMaterial}');
      }
      if (load.gasCheckInstallMethod != null &&
          load.gasCheckInstallMethod!.isNotEmpty) {
        loadLines.add('Gas Check Install: ${load.gasCheckInstallMethod}');
      }
      if (load.bulletCoating != null && load.bulletCoating!.isNotEmpty) {
        loadLines.add('Bullet Coating: ${load.bulletCoating}');
      }
      if (load.coal != null ||
          load.baseToOgive != null ||
          load.seatingDepth != null) {
        final coalText = load.coal != null ? load.coal.toString() : '-';
        final btoText = load.baseToOgive != null
            ? load.baseToOgive.toString()
            : '-';
        final seatingText = load.seatingDepth != null
            ? load.seatingDepth.toString()
            : '-';
        loadLines.add('COAL: $coalText | BTO: $btoText | Seating: $seatingText');
      }
      break;
    case LoadType.shotgun:
      loadLines.addAll([
        'Gauge: ${load.gauge ?? '-'}',
        'Shell Length: ${load.shellLength ?? '-'}',
        'Hull: ${load.hull ?? '-'}',
        'Primer: ${load.shotgunPrimer ?? '-'}',
        'Powder: ${load.shotgunPowder ?? '-'} ${load.shotgunPowderCharge ?? '-'} gr',
        'Wad: ${load.wad ?? '-'}',
        'Shot Weight: ${load.shotWeight ?? '-'}',
        'Shot Size: ${load.shotSize ?? '-'}',
        'Shot Type: ${load.shotType ?? '-'}',
        'Crimp Type: ${load.crimpType ?? '-'}',
      ]);
      if (load.dramEquivalent != null) {
        loadLines.add('Dram Equivalent: ${load.dramEquivalent}');
      }
      break;
    case LoadType.muzzleloader:
      loadLines.addAll([
        'Caliber: ${load.muzzleloaderCaliber ?? '-'}',
        'Ignition Type: ${load.ignitionType ?? '-'}',
        'Powder: ${load.muzzleloaderPowderType ?? '-'} (${load.powderGranulation ?? '-'})',
        'Powder Charge: ${load.muzzleloaderPowderCharge ?? '-'} gr (by volume)',
        'Projectile: ${load.projectileType ?? '-'} ${load.projectileSizeWeight ?? ''}',
      ]);
      if (load.patchMaterial != null && load.patchMaterial!.isNotEmpty) {
        loadLines.add('Patch Material: ${load.patchMaterial}');
      }
      if (load.patchThickness != null && load.patchThickness!.isNotEmpty) {
        loadLines.add('Patch Thickness: ${load.patchThickness}');
      }
      if (load.patchLube != null && load.patchLube!.isNotEmpty) {
        loadLines.add('Patch Lube: ${load.patchLube}');
      }
      if (load.sabotType != null && load.sabotType!.isNotEmpty) {
        loadLines.add('Sabot Type: ${load.sabotType}');
      }
      loadLines.add(
        'Cleaned Between Shots: ${load.cleanedBetweenShots == true ? 'Yes' : 'No'}',
      );
      break;
  }
  loadLines.add('Keeper: ${load.isKeeper ? 'YES' : 'No'}');
  loadLines.add('Dangerous: ${load.isDangerous ? 'YES' : 'No'}');

  final bestLines = <String>[];
  if (bestResult != null) {
    bestLines.add('Group Size: ${bestResult.groupSizeIn} in');
    bestLines.add('Tested At: ${bestResult.testedAt.toLocal()}');
    bestLines.add('Rounds Tested: ${bestResult.roundsTested ?? '-'}');
    bestLines.add('AVG: ${bestResult.avgFps ?? '-'}');
    bestLines.add('SD: ${bestResult.sdFps ?? '-'}');
    bestLines.add('ES: ${bestResult.esFps ?? '-'}');
  }

  final photoPath = photos.isNotEmpty
      ? (photos.first.thumbPath ?? photos.first.galleryPath)
      : null;

  return ReportContent(
    title: 'Load Intel Report',
    loadLines: loadLines,
    bestTitle: 'Best Result',
    bestLines: bestLines,
    bestEmptyMessage: 'No results yet.',
    photoPath: photoPath,
  );
}
