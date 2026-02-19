import 'package:flutter/material.dart';
import 'package:loadintel/core/theme/app_colors.dart';
import 'package:loadintel/domain/models/inventory_item.dart';
import 'package:loadintel/domain/repositories/inventory_repository.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';

class InventoryScreen extends StatefulWidget {
  const InventoryScreen({super.key, this.initialCategory});

  final String? initialCategory;

  @override
  State<InventoryScreen> createState() => _InventoryScreenState();
}

class _InventoryScreenState extends State<InventoryScreen> {
  final _uuid = const Uuid();
  late Future<List<InventoryItem>> _itemsFuture;
  final Map<String, GlobalKey> _sectionKeys = {
    for (final category in InventoryCategory.values) category.type: GlobalKey(),
  };

  @override
  void initState() {
    super.initState();
    _itemsFuture = _loadItems();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final target = widget.initialCategory;
      if (target == null) {
        return;
      }
      final key = _sectionKeys[target];
      final context = key?.currentContext;
      if (context != null) {
        Scrollable.ensureVisible(context, alignment: 0.1);
      }
    });
  }

  Future<List<InventoryItem>> _loadItems() {
    final repo = context.read<InventoryRepository>();
    return repo.listItems();
  }

  Future<void> _refresh() async {
    setState(() {
      _itemsFuture = _loadItems();
    });
  }

  Future<void> _showItemDialog({
    InventoryItem? item,
    required InventoryCategory category,
  }) async {
    final nameController = TextEditingController(text: item?.name ?? '');
    final notesController = TextEditingController(text: item?.notes ?? '');
    final formKey = GlobalKey<FormState>();
    final rootContext = context;

    Future<bool> isDuplicateName(String name) async {
      final trimmed = name.trim().toLowerCase();
      final repo = rootContext.read<InventoryRepository>();
      final items = await repo.listItems();
      return items.any(
        (existing) =>
            existing.type == category.type &&
            existing.id != item?.id &&
            existing.name.trim().toLowerCase() == trimmed,
      );
    }

    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          item == null ? 'Add ${category.label}' : 'Edit ${category.label}',
        ),
        content: Form(
          key: formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: nameController,
                  decoration: const InputDecoration(labelText: 'Name'),
                  textInputAction: TextInputAction.next,
                  validator: (value) =>
                      value == null || value.trim().isEmpty ? 'Required' : null,
                  onFieldSubmitted: (_) => FocusScope.of(context).nextFocus(),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: notesController,
                  maxLines: 3,
                  textInputAction: TextInputAction.done,
                  decoration: const InputDecoration(labelText: 'Notes'),
                  onSubmitted: (_) => FocusScope.of(context).unfocus(),
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (!formKey.currentState!.validate()) {
                return;
              }
              if (await isDuplicateName(nameController.text)) {
                ScaffoldMessenger.of(rootContext).showSnackBar(
                  SnackBar(
                    content: Text(
                      'An item with this name already exists in ${category.label}',
                    ),
                  ),
                );
                return;
              }
              Navigator.of(context).pop(true);
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );

    if (result != true) {
      return;
    }

    final now = DateTime.now();
    final updated = InventoryItem(
      id: item?.id ?? _uuid.v4(),
      type: category.type,
      name: nameController.text.trim(),
      qty: item?.qty,
      unit: item?.unit,
      notes: notesController.text.trim().isEmpty
          ? null
          : notesController.text.trim(),
      createdAt: item?.createdAt ?? now,
      updatedAt: now,
    );

    final repo = context.read<InventoryRepository>();
    await repo.upsertItem(updated);
    await _refresh();
  }

  Future<void> _deleteItem(InventoryItem item) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete inventory item?'),
        content: Text('Delete ${item.name}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed != true) {
      return;
    }
    await context.read<InventoryRepository>().deleteItem(item.id);
    await _refresh();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Inventory')),
      body: SafeArea(
        child: FutureBuilder<List<InventoryItem>>(
          future: _itemsFuture,
          builder: (context, snapshot) {
            final items = snapshot.data ?? [];
            return ListView(
              padding: EdgeInsets.fromLTRB(
                16,
                16,
                16,
                16 + MediaQuery.of(context).padding.bottom,
              ),
              children: InventoryCategory.values
                  .map(
                    (category) => _InventorySection(
                      key: _sectionKeys[category.type],
                      category: category,
                      items: items
                          .where((item) => item.type == category.type)
                          .toList(),
                      onAdd: () => _showItemDialog(category: category),
                      onEdit: (item) =>
                          _showItemDialog(item: item, category: category),
                      onDelete: _deleteItem,
                    ),
                  )
                  .toList(),
            );
          },
        ),
      ),
    );
  }
}

class InventoryCategory {
  const InventoryCategory({required this.type, required this.label});

  final String type;
  final String label;

  static const values = [
    InventoryCategory(type: 'brass', label: 'Brass'),
    InventoryCategory(type: 'bullets', label: 'Bullets'),
    InventoryCategory(type: 'wads', label: 'Wads'),
    InventoryCategory(type: 'powder', label: 'Powder'),
    InventoryCategory(type: 'primers', label: 'Primers'),
  ];

  static InventoryCategory byType(String type) {
    return values.firstWhere((category) => category.type == type);
  }
}

class _InventorySection extends StatelessWidget {
  const _InventorySection({
    super.key,
    required this.category,
    required this.items,
    required this.onAdd,
    required this.onEdit,
    required this.onDelete,
  });

  final InventoryCategory category;
  final List<InventoryItem> items;
  final VoidCallback onAdd;
  final ValueChanged<InventoryItem> onEdit;
  final ValueChanged<InventoryItem> onDelete;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ExpansionTile(
        title: Text(
          category.label,
          style: Theme.of(context).textTheme.titleMedium,
        ),
        trailing: ElevatedButton(
          onPressed: onAdd,
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.burntCopper,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
          child: const Text(' + '),
        ),
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (items.isEmpty)
                  const Text('No items yet.')
                else
                  Column(
                    children: items
                        .map(
                          (item) => ListTile(
                            title: Text(item.name),
                            subtitle: Text(_buildSubtitle(item)),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                IconButton(
                                  onPressed: () => onEdit(item),
                                  icon: const Icon(Icons.edit),
                                ),
                                IconButton(
                                  onPressed: () => onDelete(item),
                                  icon: const Icon(Icons.delete),
                                ),
                              ],
                            ),
                          ),
                        )
                        .toList(),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _buildSubtitle(InventoryItem item) {
    final parts = <String>[];
    if (item.notes != null && item.notes!.isNotEmpty) {
      parts.add(item.notes!);
    }
    return parts.isEmpty ? 'No details' : parts.join(' | ');
  }
}
