import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../shared/widgets/app_button.dart';
import '../../../shared/widgets/app_card.dart';
import '../../../shared/widgets/common_widgets.dart';
import '../cubit/quiz_cubit.dart';

/// Shows elapsed time as MM:SS, ticking every second.
class _QuizTimer extends StatefulWidget {
  const _QuizTimer();

  @override
  State<_QuizTimer> createState() => _QuizTimerState();
}

class _QuizTimerState extends State<_QuizTimer> {
  late final DateTime _start;
  late final Timer _timer;
  Duration _elapsed = Duration.zero;

  @override
  void initState() {
    super.initState();
    _start = DateTime.now();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() => _elapsed = DateTime.now().difference(_start));
    });
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  String _format(Duration d) {
    final m = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final s = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Icon(Icons.timer_outlined, size: 16, color: AppColors.neutral500),
        const SizedBox(width: 4),
        Text(_format(_elapsed),
            style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: AppColors.neutral500)),
        const SizedBox(width: 8),
      ],
    );
  }
}

class QuizScreen extends StatelessWidget {
  final String examId;
  const QuizScreen({super.key, required this.examId});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => QuizCubit()..load(examId),
      child: _QuizView(examId: examId),
    );
  }
}

class _QuizView extends StatelessWidget {
  final String examId;
  const _QuizView({required this.examId});

  Future<void> _submit(BuildContext context) async {
    final cubit = context.read<QuizCubit>();
    final unanswered = cubit.state.totalQuestions - cubit.state.answeredCount;

    if (unanswered > 0) {
      final proceed = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Submit exam?'),
          content: Text('$unanswered question(s) are unanswered.'),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: const Text('Keep working')),
            TextButton(
                onPressed: () => Navigator.pop(ctx, true),
                child: const Text('Submit anyway',
                    style: TextStyle(color: AppColors.warning))),
          ],
        ),
      );
      if (proceed != true || !context.mounted) return;
    }

    final result = await cubit.submit();
    if (result != null && context.mounted) {
      context.pushReplacement('/result/${result.sessionId}', extra: result);
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<QuizCubit, QuizState>(
      listenWhen: (prev, curr) => prev.error != curr.error && curr.error != null,
      listener: (context, state) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(state.error!)));
      },
      builder: (context, state) {
        if (state.isLoading) {
          return const Scaffold(
            body: LoadingWidget(message: 'Loading exam...'),
          );
        }
        if (state.exam == null || state.currentQuestion == null) {
          return Scaffold(
            appBar: AppBar(title: const Text('Quiz')),
            body: AppErrorWidget(
              message: state.error ?? 'This exam has no questions.',
              onRetry: () => context.read<QuizCubit>().load(examId),
            ),
          );
        }

        final cubit = context.read<QuizCubit>();
        final question = state.currentQuestion!;

        return PopScope(
          canPop: false,
          child: Scaffold(
            appBar: AppBar(
              title: Text(
                  'Question ${state.currentIndex + 1} of ${state.totalQuestions}'),
              automaticallyImplyLeading: false,              actions: [
                const _QuizTimer(),
                IconButton(
                  icon: Icon(
                    state.isBookmarked ? Icons.bookmark : Icons.bookmark_border,
                    color: state.isBookmarked ? AppColors.warning : null,
                  ),
                  onPressed: cubit.toggleBookmark,
                ),
                IconButton(
                  icon: const Icon(Icons.grid_view_outlined),
                  onPressed: () => _showQuestionGrid(context, state),
                ),
              ],
            ),
            body: Column(
              children: [
                if (state.isOffline)
                  Container(
                    width: double.infinity,
                    color: AppColors.warningLight,
                    padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.base, vertical: AppSpacing.sm),
                    child: Row(
                      children: [
                        const Icon(Icons.wifi_off,
                            size: 16, color: AppColors.warning),
                        const SizedBox(width: AppSpacing.sm),
                        Expanded(
                          child: Text(
                            'Offline — answers are saved on this device',
                            style: AppTypography.caption
                                .copyWith(color: AppColors.neutral800),
                          ),
                        ),
                      ],
                    ),
                  ),
                LinearProgressIndicator(
                  value: state.answeredCount / state.totalQuestions,
                  minHeight: 4,
                  backgroundColor: AppColors.neutral200,
                  valueColor:
                      const AlwaysStoppedAnimation<Color>(AppColors.primary),
                ),
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(AppSpacing.base),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (question.topic != null)
                          Padding(
                            padding:
                                const EdgeInsets.only(bottom: AppSpacing.sm),
                            child: Row(
                              children: [
                                _chip(question.topic!),
                                const SizedBox(width: AppSpacing.sm),
                                if (question.difficulty != null)
                                  _chip(question.difficulty!),
                              ],
                            ),
                          ),
                        Text(question.content,
                            style: AppTypography.bodyLarge
                                .copyWith(fontSize: 18, height: 1.4)),
                        const SizedBox(height: AppSpacing.base),
                        ...List.generate(question.options.length, (i) {
                          final selected = state.currentAnswer == i;
                          return Padding(
                            padding: const EdgeInsets.only(
                                bottom: AppSpacing.sm),
                            child: _OptionTile(
                              label: String.fromCharCode(65 + i),
                              text: question.options[i],
                              selected: selected,
                              onTap: () => cubit.selectAnswer(i),
                            ),
                          );
                        }),
                      ],
                    ),
                  ),
                ),
                SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.all(AppSpacing.base),
                    child: Row(
                      children: [
                        Expanded(
                          child: AppButton(
                            label: 'Previous',
                            isOutlined: true,
                            onPressed: state.currentIndex > 0
                                ? cubit.previous
                                : null,
                          ),
                        ),
                        const SizedBox(width: AppSpacing.sm),
                        Expanded(
                          flex: 2,
                          child: state.isLast
                              ? AppButton(
                                  label: 'Submit',
                                  onPressed: state.isSubmitting
                                      ? null
                                      : () => _submit(context),
                                  isLoading: state.isSubmitting,
                                  icon: Icons.check,
                                )
                              : AppButton(
                                  label: 'Next',
                                  onPressed: cubit.next,
                                  icon: Icons.arrow_forward,
                                ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _chip(String label) {
    return Container(
      padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.sm, vertical: AppSpacing.xs),
      decoration: BoxDecoration(
        color: AppColors.neutral100,
        borderRadius: BorderRadius.circular(100),
      ),
      child: Text(label, style: AppTypography.caption),
    );
  }

  void _showQuestionGrid(BuildContext context, QuizState state) {
    final cubit = context.read<QuizCubit>();
    showModalBottomSheet<void>(
      context: context,
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.base),
          child: GridView.count(
            crossAxisCount: 5,
            shrinkWrap: true,
            childAspectRatio: 1.2,
            children: List.generate(state.totalQuestions, (i) {
              final q = state.exam!.questions[i];
              final answered = state.answers.containsKey(q.id);
              final isCurrent = i == state.currentIndex;
              final isBookmarked = state.bookmarks.contains(q.id);
              return Padding(
                padding: const EdgeInsets.all(AppSpacing.xs),
                child: InkWell(
                  borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
                  onTap: () {
                    cubit.goTo(i);
                    Navigator.pop(ctx);
                  },
                  child: Container(
                    decoration: BoxDecoration(
                      color: answered
                          ? AppColors.primary
                          : AppColors.neutral100,
                      borderRadius:
                          BorderRadius.circular(AppSpacing.cardRadius),
                      border: Border.all(
                        color: isCurrent
                            ? AppColors.warning
                            : answered
                                ? AppColors.primary
                                : AppColors.neutral300,
                        width: isCurrent ? 2 : 1,
                      ),
                    ),
                    child: Stack(
                      children: [
                        Center(
                          child: Text(
                            '${i + 1}',
                            style: AppTypography.labelLarge.copyWith(
                              color: answered
                                  ? Colors.white
                                  : AppColors.textPrimary,
                            ),
                          ),
                        ),
                        if (isBookmarked)
                          const Positioned(
                            top: 2,
                            right: 4,
                            child: Icon(Icons.bookmark,
                                size: 12, color: AppColors.warning),
                          ),
                      ],
                    ),
                  ),
                ),
              );
            }),
          ),
        ),
      ),
    );
  }
}

class _OptionTile extends StatelessWidget {
  final String label;
  final String text;
  final bool selected;
  final VoidCallback onTap;

  const _OptionTile({
    required this.label,
    required this.text,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return AppCard(
      color: selected ? AppColors.primary.withValues(alpha: 0.06) : null,
      onTap: onTap,
      padding: const EdgeInsets.all(AppSpacing.base),
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: selected ? AppColors.primary : AppColors.neutral100,
              border: Border.all(
                color: selected ? AppColors.primary : AppColors.neutral300,
              ),
            ),
            child: Text(
              label,
              style: AppTypography.labelLarge.copyWith(
                color: selected ? Colors.white : AppColors.textPrimary,
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.base),
          Expanded(
            child: Text(text, style: AppTypography.bodyLarge),
          ),
        ],
      ),
    );
  }
}
