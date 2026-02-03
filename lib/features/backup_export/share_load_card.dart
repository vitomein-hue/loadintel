import 'dart:io';

import 'package:flutter/material.dart';
import 'package:loadintel/core/theme/app_colors.dart';
import 'package:loadintel/domain/models/load_recipe.dart';
import 'package:loadintel/domain/models/range_result.dart';
import 'package:loadintel/domain/models/target_photo.dart';

class ShareLoadCard extends StatelessWidget {
  const ShareLoadCard({
    super.key,
    required this.load,
    required this.bestResult,
    required this.photos,
  });

  static const Size cardSize = Size(1080, 1350);
  static const double _edgePadding = 48;
  static const double _brandWidth = 140;
  static const double _brandHeight = 36;

  final LoadRecipe load;
  final RangeResult? bestResult;
  final List<TargetPhoto> photos;

  @override
  Widget build(BuildContext context) {
    final thumbnailPhotos = photos.take(2).toList();
    final notes = _combinedNotes(load.notes, bestResult?.notes);
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
                  load.recipeName,
                  style: const TextStyle(
                    fontSize: 40,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  load.cartridge,
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w600,
                    color: AppColors.secondary,
                  ),
                ),
                const SizedBox(height: 20),
                _infoRow('Bullet', _bulletSummary(load)),
                _infoRow('Powder', '${load.powder} ${load.powderChargeGr} gr'),
                _infoRow('Primer', load.primer ?? '-'),
                _infoRow('Brass', load.brass ?? '-'),
                _infoRow(
                  'Brass Trim Length',
                  load.brassTrimLength?.toString() ?? '-',
                ),
                _infoRow(
                  'Annealing time',
                  load.annealingTimeSec == null
                      ? '-'
                      : '${load.annealingTimeSec} sec',
                ),
                _infoRow('COAL', load.coal?.toString() ?? '-'),
                _infoRow('Seating Depth', load.seatingDepth?.toString() ?? '-'),
                if (bestResult != null) ...[
                  const SizedBox(height: 18),
                  _sectionTitle('Performance'),
                  const SizedBox(height: 8),
                  _infoRow(
                    'Tested',
                    bestResult!.testedAt.toLocal().toString().split(' ').first,
                  ),
                  _infoRow(
                    'Group Size',
                    '${bestResult!.groupSizeIn.toStringAsFixed(2)} in',
                  ),
                  _infoRow('AVG', _formatMaybe(bestResult!.avgFps)),
                  _infoRow('SD', _formatMaybe(bestResult!.sdFps)),
                  _infoRow('ES', _formatMaybe(bestResult!.esFps)),
                ],
                if (thumbnailPhotos.isNotEmpty) ...[
                  const SizedBox(height: 18),
                  _sectionTitle('Targets'),
                  const SizedBox(height: 8),
                  Row(
                    children: thumbnailPhotos
                        .map((photo) => Padding(
                              padding: const EdgeInsets.only(right: 12),
                              child: _photoThumb(photo),
                            ))
                        .toList(),
                  ),
                ],
                if (notes.isNotEmpty) ...[
                  const SizedBox(height: 18),
                  _sectionTitle('Notes'),
                  const SizedBox(height: 8),
                  Text(
                    notes,
                    maxLines: 5,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 18),
                  ),
                ],
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

  Widget _infoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 180,
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: AppColors.secondary,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontSize: 18),
            ),
          ),
        ],
      ),
    );
  }

  Widget _photoThumb(TargetPhoto photo) {
    final pathValue = photo.thumbPath ?? photo.galleryPath;
    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: Image.file(
        File(pathValue),
        width: 160,
        height: 160,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => Container(
          width: 160,
          height: 160,
          color: AppColors.card,
          alignment: Alignment.center,
          child: const Icon(Icons.image_not_supported),
        ),
      ),
    );
  }

  String _bulletSummary(LoadRecipe load) {
    final parts = <String>[];
    if (load.bulletBrand != null && load.bulletBrand!.isNotEmpty) {
      parts.add(load.bulletBrand!);
    }
    if (load.bulletWeightGr != null) {
      parts.add('${load.bulletWeightGr} gr');
    }
    if (load.bulletType != null && load.bulletType!.isNotEmpty) {
      parts.add(load.bulletType!);
    }
    return parts.isEmpty ? '-' : parts.join(' ');
  }

  String _combinedNotes(String? loadNotes, String? resultNotes) {
    final parts = <String>[];
    final trimmedLoad = loadNotes?.trim();
    if (trimmedLoad != null && trimmedLoad.isNotEmpty) {
      parts.add(trimmedLoad);
    }
    final trimmedResult = resultNotes?.trim();
    if (trimmedResult != null && trimmedResult.isNotEmpty) {
      parts.add(trimmedResult);
    }
    return parts.join('\n');
  }

  String _formatMaybe(double? value) {
    if (value == null) {
      return '-';
    }
    return value.toStringAsFixed(1);
  }
}
