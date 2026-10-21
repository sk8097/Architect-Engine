import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../constants/app_colors.dart';
import '../data/tools_data.dart';
import '../models/tool_model.dart';
import '../providers/app_state_provider.dart';
import '../widgets/common_app_bar.dart';
import '../widgets/app_drawer.dart';
import 'calculator_dialog.dart';

class ToolsScreen extends StatefulWidget {
  final String? initialCategory;

  const ToolsScreen({super.key, this.initialCategory});

  @override
  State<ToolsScreen> createState() => _ToolsScreenState();
}

class _ToolsScreenState extends State<ToolsScreen> {
  String _selectedCat = 'all';
  String _searchQuery = '';
  int _renderLimit = 30;

  @override
  void initState() {
    super.initState();
    if (widget.initialCategory != null) {
      _selectedCat = widget.initialCategory!;
    }
  }

  @override
  Widget build(BuildContext context) {
    final appState = Provider.of<AppStateProvider>(context);

    List<ToolModel> list = ToolsData.allTools;
    if (_selectedCat == 'fav') {
      list = list.where((t) => appState.isFavorite(t.id)).toList();
    } else if (_selectedCat != 'all') {
      list = list.where((t) => t.category == _selectedCat).toList();
    }

    if (_searchQuery.isNotEmpty) {
      final q = _searchQuery.toLowerCase();
      list = list.where((t) => t.name.toLowerCase().contains(q) || t.description.toLowerCase().contains(q)).toList();
    }

    final visibleTools = list.take(_renderLimit).toList();

    return Scaffold(
      appBar: const CommonAppBar(title: 'TOOLS & UTILITIES', icon: '🧰'),
      drawer: const AppDrawer(),
      body: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(18, 14, 18, 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('168 Professional Tools', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                  const Text('Civil engineering, BOQ takeoffs, structural, and architectural calculators', style: TextStyle(fontSize: 12, color: Colors.grey)),
                  const SizedBox(height: 14),

                  // Search Box
                  TextField(
                    decoration: InputDecoration(
                      hintText: 'Search 168 tools (e.g. concrete, steel, tile, boq)...',
                      prefixIcon: const Icon(Icons.search, size: 20),
                      filled: true,
                      fillColor: Theme.of(context).cardColor,
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
                    ),
                    onChanged: (v) => setState(() => _searchQuery = v),
                  ),
                  const SizedBox(height: 14),

                  // Horizontal Category Chips
                  SizedBox(
                    height: 38,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      itemCount: ToolsData.categories.length,
                      itemBuilder: (context, index) {
                        final cat = ToolsData.categories[index];
                        final isSelected = cat.id == _selectedCat;
                        final countText = (cat.id == 'fav' && appState.favoriteToolIds.isNotEmpty)
                            ? ' (${appState.favoriteToolIds.length})'
                            : '';

                        return Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: FilterChip(
                            label: Text('${cat.icon} ${cat.translationKey}$countText'),
                            selected: isSelected,
                            selectedColor: AppColors.darkPrimary,
                            labelStyle: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: isSelected ? const Color(0xFF0A1128) : Theme.of(context).textTheme.bodyMedium?.color,
                            ),
                            backgroundColor: Theme.of(context).cardColor,
                            onSelected: (_) {
                              setState(() {
                                _selectedCat = cat.id;
                                _renderLimit = 30;
                              });
                            },
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Tools Grid
          if (visibleTools.isEmpty)
            const SliverFillRemaining(
              child: Center(
                child: Text('🔍 No tools found matching criteria', style: TextStyle(color: Colors.grey)),
              ),
            )
          else
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
              sliver: SliverGrid(
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                  childAspectRatio: 1.15,
                ),
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    final tool = visibleTools[index];
                    final isFav = appState.isFavorite(tool.id);

                    return InkWell(
                      onTap: () {
                        showDialog(context: context, builder: (_) => CalculatorDialog(tool: tool));
                      },
                      borderRadius: BorderRadius.circular(16),
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Theme.of(context).cardColor,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: AppColors.darkBorder),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Container(
                                  width: 38,
                                  height: 38,
                                  decoration: BoxDecoration(
                                    color: AppColors.darkIconBg,
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  alignment: Alignment.center,
                                  child: Text(tool.icon, style: const TextStyle(fontSize: 19)),
                                ),
                                IconButton(
                                  padding: EdgeInsets.zero,
                                  constraints: const BoxConstraints(),
                                  icon: Icon(
                                    isFav ? Icons.star : Icons.star_border,
                                    size: 18,
                                    color: isFav ? Colors.amber : Colors.grey,
                                  ),
                                  onPressed: () => appState.toggleFavorite(tool.id),
                                ),
                              ],
                            ),
                            const Spacer(),
                            Text(
                              tool.name,
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 2),
                            Text(
                              tool.description,
                              style: const TextStyle(fontSize: 10, color: Colors.grey),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                  childCount: visibleTools.length,
                ),
              ),
            ),

          if (list.length > _renderLimit)
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
                child: OutlinedButton(
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.all(14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    side: const BorderSide(color: AppColors.darkPrimary),
                    foregroundColor: AppColors.darkPrimary,
                  ),
                  onPressed: () => setState(() => _renderLimit += 30),
                  child: Text('LOAD MORE (${_renderLimit}/${list.length})', style: const TextStyle(fontWeight: FontWeight.bold)),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
