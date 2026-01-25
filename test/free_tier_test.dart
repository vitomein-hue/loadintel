import 'package:flutter_test/flutter_test.dart';
import 'package:loadintel/core/utils/free_tier.dart';

void main() {
  test('canCreateRecipe respects limit when locked', () {
    expect(canCreateRecipe(existingCount: 9, isUnlocked: false), isTrue);
    expect(canCreateRecipe(existingCount: 10, isUnlocked: false), isFalse);
  });

  test('canCreateRecipe ignores limit when unlocked', () {
    expect(canCreateRecipe(existingCount: 10, isUnlocked: true), isTrue);
    expect(canCreateRecipe(existingCount: 50, isUnlocked: true), isTrue);
  });
}
