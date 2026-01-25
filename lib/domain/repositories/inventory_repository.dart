import 'package:loadintel/domain/models/inventory_item.dart';

abstract class InventoryRepository {
  Future<void> upsertItem(InventoryItem item);
  Future<void> deleteItem(String id);
  Future<InventoryItem?> getItem(String id);
  Future<List<InventoryItem>> listItems();
}

