import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../data/tools_data.dart';
import '../models/tool_model.dart';
import '../providers/app_state_provider.dart';
import 'calculator_dialog.dart';

class ToolsScreen extends StatefulWidget {
  const ToolsScreen({super.key, this.initialCategory});

  final String? initialCategory;

  @override
  State<ToolsScreen> createState() => _ToolsScreenState();
}

class _ToolsScreenState extends State<ToolsScreen> {
  late String _category;
  String _query = '';

  @override
  void initState() {
    super.initState();
    final requested = widget.initialCategory;
    _category = ToolsData.categories.any((item) => item.id == requested)
        ? requested!
        : 'all';
  }

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppStateProvider>();
    final query = _query.trim().toLowerCase();
    final tools = ToolsData.allTools.where((tool) {
      final inCategory = switch (_category) {
        'all' => true,
        'fav' => appState.isFavorite(tool.id),
        _ => tool.category == _category,
      };
      return inCategory &&
          (tool.name.toLowerCase().contains(query) ||
              tool.description.toLowerCase().contains(query));
    }).toList();

    return Scaffold(
      appBar: AppBar(title: const Text('Tools & Utilities')),
      body: CustomScrollView(
        keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
        slivers: [
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(18, 16, 18, 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${ToolsData.allTools.length} Professional Tools',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const Text('Civil engineering, BOQ and architectural calculators'),
                  const SizedBox(height: 12),
                  TextField(
                    decoration: const InputDecoration(
                      labelText: 'Search tools',
                      prefixIcon: Icon(Icons.search),
                    ),
                    onChanged: (value) => setState(() => _query = value),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    height: 48,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      itemCount: ToolsData.categories.length,
                      separatorBuilder: (_, index) => const SizedBox(width: 8),
                      itemBuilder: (context, index) {
                        final category = ToolsData.categories[index];
                        return ChoiceChip(
                          key: ValueKey('tools-category-${category.id}'),
                          label: Text('${category.icon} ${category.translationKey}'),
                          selected: _category == category.id,
                          onSelected: (selected) {
                            if (selected) setState(() => _category = category.id);
                          },
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (tools.isEmpty)
            SliverFillRemaining(
              hasScrollBody: false,
              child: Center(
                child: Text(_category == 'fav' && query.isEmpty
                    ? 'No favorites yet. Tap a star to save a tool.'
                    : 'No tools match your search.'),
              ),
            )
          else
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(14, 0, 14, 16),
              sliver: SliverGrid.builder(
                gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                  maxCrossAxisExtent: 300,
                  mainAxisExtent: 134,
                  mainAxisSpacing: 8,
                  crossAxisSpacing: 8,
                ),
                itemCount: tools.length,
                itemBuilder: (context, index) => _ToolCard(
                  tool: tools[index],
                  favorite: appState.isFavorite(tools[index].id),
                  onFavorite: () => appState.toggleFavorite(tools[index].id),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _ToolCard extends StatelessWidget {
  const _ToolCard({required this.tool, required this.favorite, required this.onFavorite});

  final ToolModel tool;
  final bool favorite;
  final VoidCallback onFavorite;

  @override
  Widget build(BuildContext context) => Card(
    clipBehavior: Clip.antiAlias,
    child: InkWell(
      onTap: tool.isWorking
          ? () => showDialog<void>(
              context: context,
              builder: (_) => CalculatorDialog(tool: tool),
            )
          : null,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(tool.icon, style: const TextStyle(fontSize: 22)),
                IconButton(
                  tooltip: favorite ? 'Remove from favorites' : 'Add to favorites',
                  onPressed: onFavorite,
                  icon: Icon(favorite ? Icons.star : Icons.star_border),
                  color: favorite ? Colors.amber : null,
                ),
              ],
            ),
            Text(tool.name, style: Theme.of(context).textTheme.titleSmall,
                maxLines: 1, overflow: TextOverflow.ellipsis),
            const SizedBox(height: 3),
            Flexible(child: Text(tool.description, maxLines: 2, overflow: TextOverflow.ellipsis)),
          ],
        ),
      ),
    ),
  );
}
