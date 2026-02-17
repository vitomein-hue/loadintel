import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:loadintel/domain/models/firearm.dart';
import 'package:loadintel/domain/models/inventory_item.dart';
import 'package:loadintel/domain/models/load_recipe.dart';
import 'package:loadintel/domain/models/load_with_best_result.dart';
import 'package:loadintel/domain/repositories/firearm_repository.dart';
import 'package:loadintel/domain/repositories/inventory_repository.dart';
import 'package:loadintel/domain/repositories/load_recipe_repository.dart';
import 'package:loadintel/domain/repositories/settings_repository.dart';
import 'package:loadintel/features/build_load/build_load_screen.dart';
import 'package:loadintel/services/purchase_service.dart';
import 'package:loadintel/services/trial_service.dart';
import 'package:provider/provider.dart';

class FakeLoadRecipeRepository implements LoadRecipeRepository {
  final Map<String, LoadRecipe> _recipes = {};
  int upsertCount = 0;

  List<LoadRecipe> get recipes => _recipes.values.toList();

  @override
  Future<void> upsertRecipe(LoadRecipe recipe) async {
    upsertCount += 1;
    _recipes[recipe.id] = recipe;
  }

  @override
  Future<void> updateKeeper(String id, bool isKeeper) async {}

  @override
  Future<void> deleteRecipe(String id) async {
    _recipes.remove(id);
  }

  @override
  Future<LoadRecipe?> getRecipe(String id) async => _recipes[id];

  @override
  Future<List<LoadRecipe>> listRecipes() async => recipes;

  @override
  Future<int> countRecipes() async => _recipes.length;

  @override
  Future<List<LoadRecipe>> listNewLoads() async => recipes;

  @override
  Future<List<LoadWithBestResult>> listTestedLoads() async => [];
}

class FakeFirearmRepository implements FirearmRepository {
  @override
  Future<void> upsertFirearm(Firearm firearm) async {}

  @override
  Future<void> deleteFirearm(String id) async {}

  @override
  Future<Firearm?> getFirearm(String id) async => null;

  @override
  Future<List<Firearm>> listFirearms() async => [];
}

class FakeInventoryRepository implements InventoryRepository {
  FakeInventoryRepository(this._items);

  final List<InventoryItem> _items;

  @override
  Future<void> upsertItem(InventoryItem item) async {}

  @override
  Future<void> deleteItem(String id) async {}

  @override
  Future<InventoryItem?> getItem(String id) async => null;

  @override
  Future<List<InventoryItem>> listItems() async => _items;
}

class FakeSettingsRepository implements SettingsRepository {
  final Map<String, bool> _bools = {};
  final Map<String, String> _strings = {};
  ProEntitlementOverride _override = ProEntitlementOverride.auto;

  @override
  Future<void> setBool(String key, bool value) async {
    _bools[key] = value;
  }

  @override
  Future<bool?> getBool(String key) async => _bools[key];

  @override
  Future<void> setString(String key, String value) async {
    _strings[key] = value;
  }

  @override
  Future<String?> getString(String key) async => _strings[key];

  @override
  Future<void> setProEntitled(bool value) async {
    _bools[SettingsKeys.proEntitled] = value;
  }

  @override
  Future<bool> isProEntitled() async =>
      _bools[SettingsKeys.proEntitled] ?? false;

  @override
  Future<void> setProEntitlementOverride(
    ProEntitlementOverride value,
  ) async {
    _override = value;
  }

  @override
  Future<ProEntitlementOverride> getProEntitlementOverride() async =>
      _override;

  @override
  Future<void> setLifetimeUnlocked(bool value) async {
    _bools[SettingsKeys.lifetimeUnlocked] = value;
  }

  @override
  Future<bool> isLifetimeUnlocked() async =>
      _bools[SettingsKeys.lifetimeUnlocked] ?? false;
}

class FakePurchaseService extends PurchaseService {
  FakePurchaseService(SettingsRepository settingsRepository)
      : super(settingsRepository);

  bool lifetimeAccess = false;
  bool claimedTrial = false;
  DateTime? trialStartDate;

  @override
  bool hasLifetimeAccess() => lifetimeAccess;

  @override
  bool hasClaimedFreeTrial() => claimedTrial;

  @override
  DateTime? getTrialStartDate() => trialStartDate;
}

Finder _fieldWithLabel(String label) {
  return find.byWidgetPredicate(
    (widget) =>
        widget is TextFormField && widget.decoration?.labelText == label,
  );
}

Widget _buildTestApp({
  required FakeLoadRecipeRepository loadRepo,
  required FakeInventoryRepository inventoryRepo,
  required FakeFirearmRepository firearmRepo,
  required FakeSettingsRepository settingsRepo,
}) {
  final purchaseService = FakePurchaseService(settingsRepo);
  final trialService = TrialService(settingsRepo, purchaseService);
  return MultiProvider(
    providers: [
      Provider<LoadRecipeRepository>.value(value: loadRepo),
      Provider<InventoryRepository>.value(value: inventoryRepo),
      Provider<FirearmRepository>.value(value: firearmRepo),
      Provider<SettingsRepository>.value(value: settingsRepo),
      ChangeNotifierProvider<TrialService>.value(value: trialService),
    ],
    child: const MaterialApp(
      home: BuildLoadScreen(),
    ),
  );
}

Future<void> _fillRequiredRifleFields(WidgetTester tester) async {
  await tester.enterText(_fieldWithLabel('Recipe Name *'), 'Test Load');
  await tester.enterText(_fieldWithLabel('Cartridge *'), '308 Win');
  await tester.ensureVisible(_fieldWithLabel('Powder *'));
  await tester.tap(_fieldWithLabel('Powder *'));
  await tester.pumpAndSettle();
  await tester.tap(find.text('Varget'));
  await tester.pumpAndSettle();
  await tester.ensureVisible(_fieldWithLabel('Powder Charge (gr) *'));
  await tester.enterText(_fieldWithLabel('Powder Charge (gr) *'), '24.0');
  await tester.ensureVisible(_fieldWithLabel('Notes'));
  await tester.enterText(_fieldWithLabel('Notes'), 'Keep this note');
}

void main() {
  testWidgets('Duplicate & Save calls save once and keeps form open',
      (tester) async {
    final now = DateTime(2026, 2, 17, 12, 0);
    final loadRepo = FakeLoadRecipeRepository();
    final inventoryRepo = FakeInventoryRepository([
      InventoryItem(
        id: 'powder-1',
        type: 'powder',
        name: 'Varget',
        createdAt: now,
        updatedAt: now,
      ),
    ]);
    final firearmRepo = FakeFirearmRepository();
    final settingsRepo = FakeSettingsRepository();

    await tester.pumpWidget(
      _buildTestApp(
        loadRepo: loadRepo,
        inventoryRepo: inventoryRepo,
        firearmRepo: firearmRepo,
        settingsRepo: settingsRepo,
      ),
    );
    await tester.pumpAndSettle();

    await _fillRequiredRifleFields(tester);

    await tester.tap(
      find.widgetWithText(ElevatedButton, 'Duplicate & Save'),
    );
    await tester.pumpAndSettle();

    expect(loadRepo.upsertCount, 1);
    expect(
      find.widgetWithText(ElevatedButton, 'Duplicate & Save'),
      findsOneWidget,
    );

    final nameField =
        tester.widget<TextFormField>(_fieldWithLabel('Recipe Name *'));
    final cartridgeField =
        tester.widget<TextFormField>(_fieldWithLabel('Cartridge *'));
    final powderField =
        tester.widget<TextFormField>(_fieldWithLabel('Powder *'));
    final powderChargeField = tester.widget<TextFormField>(
      _fieldWithLabel('Powder Charge (gr) *'),
    );
    final notesField = tester.widget<TextFormField>(_fieldWithLabel('Notes'));

    expect(nameField.controller?.text, 'Test Load (1)');
    expect(cartridgeField.controller?.text, '308 Win');
    expect(powderField.controller?.text, 'Varget');
    expect(powderChargeField.controller?.text, '24.0');
    expect(notesField.controller?.text, '');
  });

  testWidgets('Duplicate draft uses new ID and does not overwrite original',
      (tester) async {
    final now = DateTime(2026, 2, 17, 12, 0);
    final loadRepo = FakeLoadRecipeRepository();
    final inventoryRepo = FakeInventoryRepository([
      InventoryItem(
        id: 'powder-1',
        type: 'powder',
        name: 'Varget',
        createdAt: now,
        updatedAt: now,
      ),
    ]);
    final firearmRepo = FakeFirearmRepository();
    final settingsRepo = FakeSettingsRepository();

    await tester.pumpWidget(
      _buildTestApp(
        loadRepo: loadRepo,
        inventoryRepo: inventoryRepo,
        firearmRepo: firearmRepo,
        settingsRepo: settingsRepo,
      ),
    );
    await tester.pumpAndSettle();

    await _fillRequiredRifleFields(tester);

    await tester.tap(
      find.widgetWithText(ElevatedButton, 'Duplicate & Save'),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.widgetWithText(ElevatedButton, 'Save'));
    await tester.pumpAndSettle();

    expect(loadRepo.recipes.length, 2);
    expect(
      loadRepo.recipes.map((recipe) => recipe.id).toSet().length,
      2,
    );
  });
}
