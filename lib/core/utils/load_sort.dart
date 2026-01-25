import 'package:loadintel/domain/models/load_with_best_result.dart';

List<LoadWithBestResult> sortTestedLoads(
  List<LoadWithBestResult> loads,
) {
  loads.sort((a, b) {
    final cartridgeCompare =
        a.recipe.cartridge.toLowerCase().compareTo(b.recipe.cartridge.toLowerCase());
    if (cartridgeCompare != 0) {
      return cartridgeCompare;
    }
    final aGroup = a.bestGroupSize ?? double.infinity;
    final bGroup = b.bestGroupSize ?? double.infinity;
    return aGroup.compareTo(bGroup);
  });
  return loads;
}
