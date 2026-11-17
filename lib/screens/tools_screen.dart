import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../constants/app_colors.dart';
import '../data/tools_data.dart' as catalog;
import '../models/tool_model.dart';
import '../providers/app_state_provider.dart';
import 'calculator_dialog.dart';

class ToolsScreen extends StatefulWidget {
  final String? initialCategory;

  const ToolsScreen({super.key, this.initialCategory});

  @override
  State<ToolsScreen> createState() => _ToolsScreenState();
}

class _ToolsScreenState extends State<ToolsScreen> {
  late String _category;
  String _query = '';

  @override
  void initState() {
    super.initState();
    _category = widget.initialCategory ?? 'all';
  }

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppStateProvider>();
    final allTools = catalog.ToolsData.allTools;
    final filtered = allTools.where((tool) {
      final matchesCategory = _category == 'all' ||
          (_category == 'fav'
              ? appState.isFavorite(tool.id)
              : tool.category == _category);
      final q = _query.trim().toLowerCase();
      final matchesQuery = q.isEmpty ||
          tool.name.toLowerCase().contains(q) ||
          tool.description.toLowerCase().contains(q);
      return matchesCategory && matchesQuery;
    }).toList();

    return Scaffold(
      appBar: AppBar(title: const Text('Engineering Tools')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: TextField(
              onChanged: (value) => setState(() => _query = value),
              decoration: InputDecoration(
                hintText: 'Search calculators and tools',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
                isDense: true,
              ),
            ),
          ),
          SizedBox(
            height: 48,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              children: catalog.ToolsData.categories.map((category) {
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: ChoiceChip(
                    label: Text(category.icon + ' ' + category.translationKey),
                    selected: _category == category.id,
                    onSelected: (_) => setState(() => _category = category.id),
                  ),
                );
              }).toList(),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(filtered.length.toString() + ' tools',
                  style: Theme.of(context).textTheme.bodySmall),
            ),
          ),
          Expanded(
            child: filtered.isEmpty
                ? const Center(child: Text('No matching tools found'))
                : ListView.separated(
                    padding: const EdgeInsets.fromLTRB(12, 4, 12, 16),
                    itemCount: filtered.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 6),
                    itemBuilder: (context, index) {
                      final ToolModel tool = filtered[index];
                      final favorite = appState.isFavorite(tool.id);
                      return Card(
                        margin: EdgeInsets.zero,
                        child: ListTile(
                          leading: CircleAvatar(
                            backgroundColor: AppColors.darkPrimary.withValues(alpha: 0.12),
                            child: Text(tool.icon),
                          ),
                          title: Text(tool.name, style: const TextStyle(fontWeight: FontWeight.w600)),
                          subtitle: Text(tool.description, maxLines: 2, overflow: TextOverflow.ellipsis),
                          trailing: IconButton(
                            tooltip: favorite ? 'Remove favorite' : 'Add favorite',
                            icon: Icon(favorite ? Icons.star : Icons.star_border,
                                color: favorite ? AppColors.darkPrimary : null),
                            onPressed: () => appState.toggleFavorite(tool.id),
                          ),
                          onTap: () => showDialog<void>(
                            context: context,
                            builder: (_) => CalculatorDialog(tool: tool),
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
