import 'package:loadintel/domain/models/load_with_best_result.dart';

List<LoadWithBestResult> sortTestedLoads(List<LoadWithBestResult> loads) {
  loads.sort((a, b) {
    final cartridgeCompare = _compareText(
      a.recipe.cartridge,
      b.recipe.cartridge,
    );
    if (cartridgeCompare != 0) {
      return cartridgeCompare;
    }

    final bulletBrandCompare = _compareText(
      a.recipe.bulletBrand,
      b.recipe.bulletBrand,
    );
    if (bulletBrandCompare != 0) {
      return bulletBrandCompare;
    }

    final bulletWeightCompare = _compareNumber(
      a.recipe.bulletWeightGr,
      b.recipe.bulletWeightGr,
    );
    if (bulletWeightCompare != 0) {
      return bulletWeightCompare;
    }

    final bulletDiameterCompare = _compareNumber(
      a.recipe.bulletDiameter,
      b.recipe.bulletDiameter,
    );
    if (bulletDiameterCompare != 0) {
      return bulletDiameterCompare;
    }

    final bulletTypeCompare = _compareText(
      a.recipe.bulletType,
      b.recipe.bulletType,
    );
    if (bulletTypeCompare != 0) {
      return bulletTypeCompare;
    }

    final groupCompare = _compareNumber(a.bestGroupSize, b.bestGroupSize);
    if (groupCompare != 0) {
      return groupCompare;
    }

    return _compareText(a.recipe.recipeName, b.recipe.recipeName);
  });
  return loads;
}

int _compareText(String? a, String? b) {
  final aValue = (a ?? '').trim();
  final bValue = (b ?? '').trim();
  final aEmpty = aValue.isEmpty;
  final bEmpty = bValue.isEmpty;
  if (aEmpty && bEmpty) {
    return 0;
  }
  if (aEmpty) {
    return 1;
  }
  if (bEmpty) {
    return -1;
  }
  return aValue.toLowerCase().compareTo(bValue.toLowerCase());
}

int _compareNumber(double? a, double? b) {
  if (a == null && b == null) {
    return 0;
  }
  if (a == null) {
    return 1;
  }
  if (b == null) {
    return -1;
  }
  return a.compareTo(b);
}
