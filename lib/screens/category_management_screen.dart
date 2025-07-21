import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/database_service.dart';

class CategoryManagementScreen extends StatefulWidget {
  const CategoryManagementScreen({super.key});

  @override
  State<CategoryManagementScreen> createState() =>
      _CategoryManagementScreenState();
}

class _CategoryManagementScreenState extends State<CategoryManagementScreen> {
  final _categoryController = TextEditingController();

  @override
  void dispose() {
    _categoryController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final database = Provider.of<DatabaseService>(context);
    final categories = database.getCategories();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Manage Categories'),
        actions: [
          IconButton(
            icon: const Icon(Icons.sort),
            onPressed: () {
              setState(() {
                // This will trigger the reorderable list view
              });
            },
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              controller: _categoryController,
              decoration: InputDecoration(
                labelText: 'New Category',
                suffixIcon: IconButton(
                  icon: const Icon(Icons.add),
                  onPressed: () async {
                    if (_categoryController.text.isNotEmpty) {
                      await database.addCategory(_categoryController.text);
                      _categoryController.clear();
                      setState(() {});
                    }
                  },
                ),
              ),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: ReorderableListView.builder(
                itemCount: categories.length,
                itemBuilder: (context, index) {
                  final category = categories[index];
                  final isDefault = database.isDefaultCategory(category);

                  return ListTile(
                    key: Key('$index-$category'),
                    title: Text(category),
                    trailing: isDefault
                        ? const Icon(Icons.lock, color: Colors.grey)
                        : IconButton(
                            icon: const Icon(Icons.delete),
                            onPressed: () async {
                              final confirmed = await showDialog<bool>(
                                context: context,
                                builder: (context) => AlertDialog(
                                  title: const Text('Delete Category'),
                                  content: Text(
                                    'Are you sure you want to delete "$category"?',
                                  ),
                                  actions: [
                                    TextButton(
                                      onPressed: () =>
                                          Navigator.pop(context, false),
                                      child: const Text('Cancel'),
                                    ),
                                    TextButton(
                                      onPressed: () =>
                                          Navigator.pop(context, true),
                                      child: const Text('Delete'),
                                    ),
                                  ],
                                ),
                              );
                              if (confirmed == true) {
                                await database.deleteCategory(index);
                                setState(() {});
                              }
                            },
                          ),
                  );
                },
                onReorder: (oldIndex, newIndex) async {
                  await database.reorderCategories(oldIndex, newIndex);
                  setState(() {});
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
