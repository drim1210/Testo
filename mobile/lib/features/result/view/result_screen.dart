import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/api/api_service.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../data/models/models.dart';
import '../../../shared/widgets/app_button.dart';
import '../../../shared/widgets/app_card.dart';
import '../../../shared/widgets/common_widgets.dart';

class ResultScreen extends StatefulWidget {
  final String sessionId;
  const ResultScreen({super.key, required this.sessionId});

  @override
  State<ResultScreen> createState() => _ResultScreenState();
}

class _ResultScreenState extends State<ResultScreen> {
  ExamResult? _result;
  String? _error;
  bool _isPracticeLoading = false;

  @override
  void initState() {
    super.initState();
    final passed =
        ModalRoute.of(context)?.settings.arguments is ExamResult;
    if (passed) {
      _result = ModalRoute.of(context)!.settings.arguments as ExamResult;
    } else {
      _fetch();
    }
  }

  Future<void> _fetch() async {
    try {
      final result = await ApiService.instance.getResult(widget.sessionId);
      if (mounted) setState(() => _result = result);
    } catch (e) {
      if (mounted) setState(() => _error = extractErrorMessage(e));
    }
  }

  Future<void> _practiceWeakAreas() async {
    final result = _result;
    if (result == null) return;
    setState(() => _isPracticeLoading = true);
    try {
      final examId = await ApiService.instance.generatePractice(
        documentId: result.documentId,
        numQuestions: 10,
      );
      if (!mounted) return;
      context.push('/generating/$examId');
    } catch (e) {
      if (mounted) {
        setState(() => _isPracticeLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(extractErrorMessage(e))),
        );
      }
    }
  }

  Color get _scoreColor {
    final pct = _result?.percentage ?? 0;
    if (pct >= 80) return AppColors.success;
    if (pct >= 50) return AppColors.warning;
    return AppColors.error;
  }

  @override
  Widget build(BuildContext context) {
    if (_error != null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Results')),
        body: AppErrorWidget(message: _error!, onRetry: _fetch),
      );
    }
    final result = _result;
    if (result == null) {
      return const Scaffold(
        body: LoadingWidget(message: 'Calculating results...'),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Results'),
        automaticallyImplyLeading: false,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.base),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: AppSpacing.lg),
            TweenAnimationBuilder<double>(
              tween: Tween(begin: 0, end: result.percentage / 100),
              duration: const Duration(milliseconds: 1200),
              curve: Curves.easeOutCubic,
              builder: (context, value, _) => Column(
                children: [
                  SizedBox(
                    width: 140,
                    height: 140,
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        CircularProgressIndicator(
                          value: value,
                          strokeWidth: 10,
                          color: _scoreColor,
                          backgroundColor: AppColors.neutral200,
                        ),
                        Center(
                          child: Text(
                            '${(value * 100).round()}%',
                            style: AppTypography.displayMedium
                                .copyWith(color: _scoreColor),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: AppSpacing.base),
                  Text(
                    '${result.correctCount} of ${result.totalCount} correct',
                    style: AppTypography.bodyLarge
                        .copyWith(color: AppColors.textSecondary),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.xl),

            if (result.topicResults.isNotEmpty) ...[
              const Text('Topic Breakdown', style: AppTypography.headlineMedium),
              const SizedBox(height: AppSpacing.sm),
              ...result.topicResults.map((t) => _topicRow(t)),
              const SizedBox(height: AppSpacing.base),
            ],

            if (result.strongTopics.isNotEmpty) _topicListCard(
              'Strong Topics',
              result.strongTopics.map((t) => t.topic).toList(),
              Icons.thumb_up_outlined,
              AppColors.success,
            ),
            if (result.weakTopics.isNotEmpty) ...[
              const SizedBox(height: AppSpacing.sm),
              _topicListCard(
                'Needs Practice',
                result.weakTopics.map((t) => t.topic).toList(),
                Icons.thumb_down_outlined,
                AppColors.error,
              ),
            ],

            const SizedBox(height: AppSpacing.xl),
            AppButton(
              label: 'Review Answers',
              onPressed: () => context.push('/review/${result.sessionId}'),
              icon: Icons.rule,
            ),
            const SizedBox(height: AppSpacing.sm),
            if (result.weakTopics.isNotEmpty)
              AppButton(
                label: 'Practice My Weak Areas',
                isOutlined: true,
                isLoading: _isPracticeLoading,
                onPressed:
                    _isPracticeLoading ? null : _practiceWeakAreas,
                icon: Icons.fitness_center,
              ),
            const SizedBox(height: AppSpacing.sm),
            AppButton(
              label: 'Back to Home',
              isOutlined: true,
              onPressed: () => context.go('/'),
              icon: Icons.home_outlined,
            ),
            const SizedBox(height: AppSpacing.lg),
          ],
        ),
      ),
    );
  }

  Widget _topicRow(TopicResult t) {
    final color = t.percentage >= 70
        ? AppColors.success
        : t.percentage >= 40
            ? AppColors.warning
            : AppColors.error;
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(t.topic,
                    style: AppTypography.bodyMedium,
                    overflow: TextOverflow.ellipsis),
              ),
              Text('${t.correct}/${t.total} • ${t.percentage.round()}%',
                  style: AppTypography.caption),
            ],
          ),
          const SizedBox(height: AppSpacing.xs),
          ClipRRect(
            borderRadius: BorderRadius.circular(100),
            child: LinearProgressIndicator(
              value: t.percentage / 100,
              minHeight: 6,
              color: color,
              backgroundColor: AppColors.neutral200,
            ),
          ),
        ],
      ),
    );
  }

  Widget _topicListCard(
      String title, List<String> topics, IconData icon, Color color) {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 18),
              const SizedBox(width: AppSpacing.sm),
              Text(title, style: AppTypography.labelLarge),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          Wrap(
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.xs,
            children: topics
                .map((t) => Chip(
                      label: Text(t, style: AppTypography.caption),
                      backgroundColor: color.withValues(alpha: 0.1),
                      side: BorderSide(color: color.withValues(alpha: 0.4)),
                    ))
                .toList(),
          ),
        ],
      ),
    );
  }
}
