import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:qr_scanner/app/theme/app_tokens.dart';
import 'package:qr_scanner/core/l10n/app_strings.dart';
import 'package:qr_scanner/core/utils/date_formatters.dart';
import 'package:qr_scanner/core/widgets/empty_state.dart';
import 'package:qr_scanner/features/history/data/history_controller.dart';
import 'package:qr_scanner/features/history/models/qr_content_type.dart';
import 'package:qr_scanner/features/history/models/qr_history_item.dart';
import 'package:qr_scanner/features/scanner/presentation/result_sheet.dart';
import 'package:qr_scanner/shared/widgets/action_chip_button.dart';

class HistoryPage extends StatelessWidget {
  const HistoryPage({super.key});

  @override
  Widget build(BuildContext context) {
    final s = stringsOf(context);
    final history = context.watch<HistoryController>();

    return Scaffold(
      appBar: AppBar(
        title: Text(s.historyTitle),
        actions: [
          if (history.items.isNotEmpty)
            IconButton(
              tooltip: s.clearHistory,
              onPressed: () => _confirmClear(context, history, s),
              icon: const Icon(Icons.delete_outline_rounded),
            ),
        ],
      ),
      body: !history.ready
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                  child: TextField(
                    onChanged: history.setQuery,
                    textInputAction: TextInputAction.search,
                    decoration: InputDecoration(
                      hintText: s.searchHint,
                      prefixIcon: const Icon(Icons.search),
                      isDense: true,
                    ),
                  ),
                ),
                SizedBox(
                  height: 44,
                  child: ListView(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    children: [
                      _FilterChip(
                        label: s.filterAll,
                        selected: history.filter == HistoryFilter.all,
                        onTap: () => history.setFilter(HistoryFilter.all),
                      ),
                      _FilterChip(
                        label: s.filterScan,
                        selected: history.filter == HistoryFilter.scans,
                        onTap: () => history.setFilter(HistoryFilter.scans),
                      ),
                      _FilterChip(
                        label: s.filterCreate,
                        selected: history.filter == HistoryFilter.created,
                        onTap: () => history.setFilter(HistoryFilter.created),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
                Expanded(
                  child: history.visibleItems.isEmpty
                      ? EmptyStateView(
                          icon: Icons.inbox_outlined,
                          title: s.historyEmptyTitle,
                          body: s.historyEmptyBody,
                        )
                      : _GroupedHistoryList(items: history.visibleItems),
                ),
              ],
            ),
    );
  }

  Future<void> _confirmClear(
    BuildContext context,
    HistoryController history,
    AppStrings s,
  ) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(s.clearHistory),
        content: Text(s.clearHistoryConfirm),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(s.cancel),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(
              s.delete,
              style: const TextStyle(color: AppColors.danger),
            ),
          ),
        ],
      ),
    );
    if (ok == true) await history.clear();
  }
}

class _FilterChip extends StatelessWidget {
  const _FilterChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: FilterChip(
        label: Text(label),
        selected: selected,
        onSelected: (_) => onTap(),
      ),
    );
  }
}

class _GroupedHistoryList extends StatelessWidget {
  const _GroupedHistoryList({required this.items});

  final List<QrHistoryItem> items;

  @override
  Widget build(BuildContext context) {
    final s = stringsOf(context);
    final now = DateTime.now();
    final groups = <HistoryGroup, List<QrHistoryItem>>{};
    for (final item in items) {
      final g = DateFormatters.groupFor(item.createdAt, now);
      groups.putIfAbsent(g, () => []).add(item);
    }

    final order = [
      HistoryGroup.today,
      HistoryGroup.yesterday,
      HistoryGroup.thisWeek,
      HistoryGroup.older,
    ];

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
      children: [
        for (final group in order)
          if (groups[group]?.isNotEmpty == true) ...[
            Padding(
              padding: const EdgeInsets.only(top: 8, bottom: 8),
              child: Text(
                _groupLabel(group, s),
                style: Theme.of(
                  context,
                ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w800),
              ),
            ),
            for (final item in groups[group]!) _HistoryTile(item: item),
          ],
      ],
    );
  }

  String _groupLabel(HistoryGroup g, AppStrings s) => switch (g) {
    HistoryGroup.today => s.today,
    HistoryGroup.yesterday => s.yesterday,
    HistoryGroup.thisWeek => s.thisWeek,
    HistoryGroup.older => s.older,
  };
}

class _HistoryTile extends StatelessWidget {
  const _HistoryTile({required this.item});

  final QrHistoryItem item;

  @override
  Widget build(BuildContext context) {
    final s = stringsOf(context);
    final history = context.read<HistoryController>();
    final scheme = Theme.of(context).colorScheme;
    final isScan = item.source == HistorySource.scan;

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Dismissible(
        key: ValueKey(item.id),
        direction: DismissDirection.endToStart,
        background: Container(
          alignment: Alignment.centerRight,
          padding: const EdgeInsets.only(right: 20),
          decoration: BoxDecoration(
            color: AppColors.danger.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(AppRadius.lg),
          ),
          child: const Icon(Icons.delete_outline, color: AppColors.danger),
        ),
        onDismissed: (_) async {
          final removed = await history.remove(item.id);
          if (removed == null || !context.mounted) return;
          ScaffoldMessenger.of(context).clearSnackBars();
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(s.deleted),
              action: SnackBarAction(
                label: s.undo,
                onPressed: () => history.restore(removed),
              ),
            ),
          );
        },
        child: Material(
          color: scheme.surface,
          borderRadius: BorderRadius.circular(AppRadius.lg),
          child: InkWell(
            borderRadius: BorderRadius.circular(AppRadius.lg),
            onTap: () {
              showModalBottomSheet<void>(
                context: context,
                isScrollControlled: true,
                backgroundColor: scheme.surface,
                shape: const RoundedRectangleBorder(
                  borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
                ),
                builder: (_) =>
                    ResultSheet(raw: item.content, createdAt: item.createdAt),
              );
            },
            child: Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(AppRadius.lg),
                border: Border.all(color: scheme.outlineVariant),
              ),
              child: Row(
                children: [
                  Container(
                    width: 42,
                    height: 42,
                    decoration: BoxDecoration(
                      color: (isScan ? scheme.primary : AppColors.warning)
                          .withValues(alpha: 0.14),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      isScan ? Icons.qr_code_scanner : Icons.qr_code_2,
                      color: isScan ? scheme.primary : AppColors.warning,
                      size: 22,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          item.content,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontWeight: FontWeight.w600),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${item.title} · ${isScan ? s.filterScan : s.filterCreate} · ${DateFormatters.relative(item.createdAt, s)}',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: Theme.of(context).textTheme.bodySmall
                              ?.copyWith(color: scheme.onSurfaceVariant),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
