bool canCreateRecipe({
  required int existingCount,
  required bool isUnlocked,
  int limit = 25,
}) {
  if (isUnlocked) {
    return true;
  }
  return existingCount < limit;
}
