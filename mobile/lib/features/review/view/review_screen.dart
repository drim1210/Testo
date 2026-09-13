import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/api/api_service.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../data/models/models.dart';
import '../../../shared/widgets/app_card.dart';
import '../../../shared/widgets/common_widgets.dart';

enum ReviewFilter { all, incorrect, bookmarked }

class ReviewScreen extends StatefulWidget {
  final String sessionId;
  const ReviewScreen({super.key, required this.sessionId});

  @override
  State<ReviewScreen> createState() => _ReviewScreenState();
}

class _ReviewScreenState extends State<ReviewScreen> {
  ExamReview? _review;
  String? _error;
  ReviewFilter _filter = ReviewFilter.all;
  int _index = 0;
  final PageController _controller = PageController();

  @override
  void initState() {
    super.initState();
    _fetch();
  }

  Future<void> _fetch() async {
    try {
      final review =
          await ApiService.instance.getReview(widget.sessionId);
      if (mounted) setState(() => _review = review);
    } catch (e) {
      if (mounted) setState(() => _error = extractErrorMessage(e));
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  List<ReviewAnswer> get _filtered {
    final answers = _review?.answers ?? [];
    switch (_filter) {
      case ReviewFilter.all:
        return answers;
      case ReviewFilter.incorrect:
        return answers.where((a) => !a.isCorrect).toList();
      case ReviewFilter.bookmarked:
        return answers.where((a) => a.isBookmarked).toList();
    }
  }

  void _setFilter(ReviewFilter filter) {
    setState(() {
      _filter = filter;
      _index = 0;
    });
    _controller.jumpToPage(0);
  }

  @override
  Widget build(BuildContext context) {
    if (_error != null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Review')),
        body: AppErrorWidget(message: _error!, onRetry: _fetch),
      );
    }
    final review = _review;
    if (review == null) {
      return const Scaffold(body: LoadingWidget(message: 'Loading review...'));
    }

    final items = _filtered;

    return Scaffold(
      appBar: AppBar(
        title: Text(items.isEmpty
            ? 'Review'
            : 'Review ${_index + 1}/${items.length}'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.base, vertical: AppSpacing.sm),
            child: Row(
              children: [
                _filterChip('All', ReviewFilter.all, review.answers.length),
                const SizedBox(width: AppSpacing.sm),
                _filterChip('Incorrect', ReviewFilter.incorrect,
                    review.answers.where((a) => !a.isCorrect).length),
                const SizedBox(width: AppSpacing.sm),
                _filterChip('Bookmarked', ReviewFilter.bookmarked,
                    review.answers.where((a) => a.isBookmarked).length),
              ],
            ),
          ),
          Expanded(
            child: items.isEmpty
                ? EmptyWidget(
                    icon: Icons.check_circle_outline,
                    title: _filter == ReviewFilter.incorrect
                        ? 'No incorrect answers'
                        : 'Nothing here',
                    subtitle: _filter == ReviewFilter.bookmarked
                        ? 'You did not bookmark any questions'
                        : null,
                  )
                : PageView.builder(
                    controller: _controller,
                    itemCount: items.length,
                    onPageChanged: (i) => setState(() => _index = i),
                    itemBuilder: (context, i) =>
                        _ReviewCard(answer: items[i], number: i + 1),
                  ),
          ),
          if (items.isNotEmpty)
            SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.base),
                child: Row(
                  children: [
                    Expanded(
                      child: TextButton.icon(
                        onPressed: _index > 0
                            ? () => _controller.previousPage(
                                duration: const Duration(milliseconds: 250),
                                curve: Curves.easeOut)
                            : null,
                        icon: const Icon(Icons.chevron_left),
                        label: const Text('Previous'),
                      ),
                    ),
                    Expanded(
                      child: TextButton.icon(
                        onPressed: _index < items.length - 1
                            ? () => _controller.nextPage(
                                duration: const Duration(milliseconds: 250),
                                curve: Curves.easeOut)
                            : null,
                        icon: const Icon(Icons.chevron_right),
                        label: const Text('Next'),
                        iconAlignment: IconAlignment.end,
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _filterChip(String label, ReviewFilter value, int count) {
    final selected = _filter == value;
    return ChoiceChip(
      label: Text('$label ($count)'),
      selected: selected,
      selectedColor: AppColors.primary,
      labelStyle: TextStyle(
        fontSize: 13,
        fontWeight: FontWeight.w600,
        color: selected ? Colors.white : AppColors.textPrimary,
      ),
      onSelected: (_) => _setFilter(value),
    );
  }
}

class _ReviewCard extends StatelessWidget {
  final ReviewAnswer answer;
  final int number;

  const _ReviewCard({required this.answer, required this.number});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.base, vertical: AppSpacing.sm),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text('Q$number', style: AppTypography.labelLarge),
              const Spacer(),
              Icon(
                answer.isCorrect
                    ? Icons.check_circle
                    : Icons.cancel,
                color: answer.isCorrect
                    ? AppColors.success
                    : AppColors.error,
              ),
              if (answer.isBookmarked) ...[
                const SizedBox(width: AppSpacing.xs),
                const Icon(Icons.bookmark,
                    color: AppColors.warning, size: 18),
              ],
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(answer.content,
              style:
                  AppTypography.bodyLarge.copyWith(fontWeight: FontWeight.w500)),
          const SizedBox(height: AppSpacing.base),
          ...List.generate(answer.options.length, (i) {
            final isCorrect = i == answer.correctIndex;
            final isSelected = i == answer.selectedIdx;
            final color = isCorrect
                ? AppColors.success
                : isSelected
                    ? AppColors.error
                    : null;
            return Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.sm),
              child: Container(
                decoration: BoxDecoration(
                  borderRadius:
                      BorderRadius.circular(AppSpacing.cardRadius),
                  border: Border.all(
                      color: color ?? AppColors.neutral200,
                      width: color != null ? 2 : 1),
                  color: color?.withValues(alpha: 0.05),
                ),
                padding: const EdgeInsets.all(AppSpacing.base),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(
                      width: 24,
                      child: Text(
                        String.fromCharCode(65 + i),
                        style: AppTypography.labelLarge.copyWith(
                            color: color ?? AppColors.textSecondary),
                      ),
                    ),
                    Expanded(child: Text(answer.options[i])),
                    if (isCorrect)
                      const Icon(Icons.check,
                          size: 16, color: AppColors.success),
                    if (isSelected && !isCorrect)
                      const Icon(Icons.close, size: 16, color: AppColors.error),
                  ],
                ),
              ),
            );
          }),
          if (answer.selectedIdx == null)
            Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.sm),
              child: Text('You did not answer this question.',
                  style: AppTypography.caption
                      .copyWith(color: AppColors.textSecondary)),
            ),
          if (answer.explanation != null) ...[
            const SizedBox(height: AppSpacing.xs),
            AppCard(
              color: AppColors.neutral100,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Explanation',
                      style: AppTypography.labelLarge
                          .copyWith(color: AppColors.primary)),
                  const SizedBox(height: AppSpacing.xs),
                  Text(answer.explanation!,
                      style: AppTypography.bodyMedium),
                  if (answer.sourceRef != null) ...[
                    const SizedBox(height: AppSpacing.sm),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(Icons.source_outlined,
                            size: 14, color: AppColors.textSecondary),
                        const SizedBox(width: AppSpacing.xs),
                        Expanded(
                          child: Text(
                            'Source: ${answer.sourceRef}',
                            style: AppTypography.caption
                                .copyWith(color: AppColors.textSecondary),
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ],
          if (answer.topic != null) ...[
            const SizedBox(height: AppSpacing.sm),
            Row(
              children: [
                const Icon(Icons.sell_outlined,
                    size: 14, color: AppColors.textSecondary),
                const SizedBox(width: AppSpacing.xs),
                Text(answer.topic!, style: AppTypography.caption),
              ],
            ),
          ],
          const SizedBox(height: AppSpacing.lg),
        ],
      ),
    );
  }
}
