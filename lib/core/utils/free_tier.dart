const int freeTierRecipeLimit = 10;

bool canCreateRecipe({required int existingCount, required bool isUnlocked}) {
  if (isUnlocked) {
    return true;
  }
  return existingCount < freeTierRecipeLimit;
}
