import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../core/api/api_service.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../data/models/models.dart';
import '../../../shared/widgets/app_card.dart';
import '../../../shared/widgets/common_widgets.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  List<SessionHistoryItem>? _items;
  String? _error;

  @override
  void initState() {
    super.initState();
    _fetch();
  }

  Future<void> _fetch() async {
    try {
      final items = await ApiService.instance.getHistory();
      if (mounted) setState(() => _items = items);
    } catch (e) {
      if (mounted) setState(() => _error = extractErrorMessage(e));
    }
  }

  Color _scoreColor(double score) {
    if (score >= 0.8) return AppColors.success;
    if (score >= 0.5) return AppColors.warning;
    return AppColors.error;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('History'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
      ),
      body: Builder(
        builder: (context) {
          if (_error != null) {
            return AppErrorWidget(message: _error!, onRetry: _fetch);
          }
          if (_items == null) {
            return const LoadingWidget(message: 'Loading history...');
          }
          if (_items!.isEmpty) {
            return const EmptyWidget(
              icon: Icons.history,
              title: 'No exams yet',
              subtitle: 'Completed exams will appear here',
            );
          }
          return RefreshIndicator(
            onRefresh: _fetch,
            child: ListView.separated(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(AppSpacing.base),
              itemCount: _items!.length,
              separatorBuilder: (_, __) => const SizedBox(height: AppSpacing.sm),
              itemBuilder: (context, i) {
                final item = _items![i];
                final date = item.completedAt?.toLocal();
                return AppCard(
                  onTap: () => context.push('/result/${item.sessionId}'),
                  child: Row(
                    children: [
                      Container(
                        width: 48,
                        height: 48,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: _scoreColor(item.score).withValues(alpha: 0.1),
                          borderRadius:
                              BorderRadius.circular(AppSpacing.cardRadius),
                        ),
                        child: Text(
                          '${(item.score * 100).round()}%',
                          style: AppTypography.labelLarge
                              .copyWith(color: _scoreColor(item.score)),
                        ),
                      ),
                      const SizedBox(width: AppSpacing.base),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              item.examTitle ?? 'Exam',
                              style: AppTypography.labelLarge,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: AppSpacing.xs),
                            Text(
                              '${item.correctCount}/${item.totalCount} correct'
                              '${date != null ? ' • ${DateFormat('MMM d, yyyy').format(date)}' : ''}',
                              style: AppTypography.caption,
                            ),
                          ],
                        ),
                      ),
                      const Icon(Icons.chevron_right,
                          color: AppColors.neutral400),
                    ],
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }
}
