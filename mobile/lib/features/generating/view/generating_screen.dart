import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/api/api_service.dart';
import '../../../core/config/app_config.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../shared/widgets/app_button.dart';

const _steps = [
  (1, 'Reading document', Icons.description_outlined),
  (2, 'Analyzing content', Icons.psychology_outlined),
  (3, 'Identifying key concepts', Icons.lightbulb_outline),
  (4, 'Generating questions', Icons.edit_outlined),
  (5, 'Validating questions', Icons.fact_check_outlined),
  (6, 'Preparing your exam', Icons.check_circle_outline),
];

class GeneratingScreen extends StatefulWidget {
  final String examId;
  const GeneratingScreen({super.key, required this.examId});

  @override
  State<GeneratingScreen> createState() => _GeneratingScreenState();
}

class _GeneratingScreenState extends State<GeneratingScreen> {
  int _currentStep = 0;
  bool _failed = false;
  String _errorMessage = '';
  Timer? _pollTimer;
  DateTime? _startedAt;

  @override
  void initState() {
    super.initState();
    _startedAt = DateTime.now();
    _pollTimer = Timer.periodic(AppConfig.pollInterval, (_) => _poll());
    _poll();
  }

  Future<void> _poll() async {
    if (_startedAt != null &&
        DateTime.now().difference(_startedAt!) > const Duration(minutes: 10)) {
      _fail('Generation is taking too long. Please check backend server and try again.');
      return;
    }
    try {
      final status = await ApiService.instance.getExamStatus(widget.examId);
      if (!mounted) return;
      setState(() {
        _currentStep = (status.progressStep - 1).clamp(0, _steps.length - 1);
      });
      switch (status.status) {
        case 'ready':
          _pollTimer?.cancel();
          context.pushReplacement('/quiz/${widget.examId}');
        case 'failed':
          _fail(status.errorMessage ?? 'Question generation failed.');
        default:
          break;
      }
    } catch (e) {
      if (!mounted) return;
      _fail(extractErrorMessage(e));
    }
  }

  void _fail(String message) {
    _pollTimer?.cancel();
    if (!mounted) return;
    setState(() {
      _failed = true;
      _errorMessage = message;
    });
  }

  @override
  void dispose() {
    _pollTimer?.cancel();
    super.dispose();
  }

  Future<void> _confirmCancel() async {
    final shouldCancel = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Cancel generation?'),
        content: const Text(
            'Questions currently being created will be lost.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Keep waiting')),
          TextButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Cancel',
                  style: TextStyle(color: AppColors.error))),
        ],
      ),
    );
    if (shouldCancel == true && mounted) {
      _pollTimer?.cancel();
      context.go('/home');
    }
  }

  @override
  Widget build(BuildContext context) {
    final progress = (_currentStep + 1) / _steps.length;

    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        actions: [
          IconButton(
            icon: const Icon(Icons.close),
            onPressed: _failed ? () => context.go('/home') : _confirmCancel,
          ),
        ],
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: AppSpacing.xl),
              Icon(
                _failed ? Icons.error_outline : Icons.auto_awesome,
                size: 48,
                color: _failed ? AppColors.error : AppColors.primary,
              ),
              const SizedBox(height: AppSpacing.base),
              Text(
                _failed ? 'Generation Failed' : 'Creating Your Exam',
                style: AppTypography.displayMedium,
                textAlign: TextAlign.center,
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: AppSpacing.xs),
                child: Text(
                  _failed ? _errorMessage : 'Please wait while AI processes your document',
                  style: _failed
                      ? AppTypography.bodyMedium.copyWith(color: AppColors.error)
                      : AppTypography.bodyMedium,
                  textAlign: TextAlign.center,
                ),
              ),
              if (!_failed) ...[
                const SizedBox(height: AppSpacing.xl),
                ClipRRect(
                  borderRadius: BorderRadius.circular(100),
                  child: LinearProgressIndicator(
                    value: progress,
                    minHeight: 8,
                    backgroundColor: AppColors.neutral200,
                    valueColor:
                        const AlwaysStoppedAnimation<Color>(AppColors.primary),
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
                Text(
                  'Step ${_currentStep + 1} of ${_steps.length}',
                  style: AppTypography.caption,
                  textAlign: TextAlign.center,
                ),
              ],
              const SizedBox(height: AppSpacing.xl),
              Expanded(
                child: ListView.separated(
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: _steps.length,
                  separatorBuilder: (_, __) =>
                      const SizedBox(height: AppSpacing.sm),
                  itemBuilder: (context, i) {
                    final (num, label, icon) = _steps[i];
                    final isDone = !_failed && i < _currentStep;
                    final isCurrent = !_failed && i == _currentStep;
                    return _StepTile(
                      label: label,
                      icon: icon,
                      isDone: isDone,
                      isCurrent: isCurrent,
                    );
                  },
                ),
              ),
              if (_failed) ...[
                const SizedBox(height: AppSpacing.base),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(AppSpacing.buttonRadius),
                          ),
                        ),
                        onPressed: () => context.go('/home'),
                        icon: const Icon(Icons.home_outlined),
                        label: const Text('Trang chủ'),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(
                      child: AppButton(
                        label: 'Thử lại',
                        onPressed: () {
                          setState(() {
                            _failed = false;
                            _errorMessage = '';
                            _startedAt = DateTime.now();
                          });
                          _pollTimer?.cancel();
                          _pollTimer = Timer.periodic(AppConfig.pollInterval, (_) => _poll());
                          _poll();
                        },
                        icon: Icons.refresh,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.xs),
                Center(
                  child: TextButton.icon(
                    onPressed: () => context.go('/pick-document'),
                    icon: const Icon(Icons.description_outlined, size: 16),
                    label: const Text('Chọn tài liệu khác', style: TextStyle(color: AppColors.textSecondary)),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _StepTile extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool isDone;
  final bool isCurrent;

  const _StepTile(
      {required this.label,
      required this.icon,
      required this.isDone,
      required this.isCurrent});

  @override
  Widget build(BuildContext context) {
    final color = isDone
        ? AppColors.success
        : isCurrent
            ? AppColors.primary
            : AppColors.neutral300;
    return Container(
      padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.base, vertical: AppSpacing.sm),
      decoration: BoxDecoration(
        color: isCurrent ? AppColors.primary.withValues(alpha: 0.08) : Colors.transparent,
        borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
        border: Border.all(
            color: isCurrent ? AppColors.primary : Colors.transparent),
      ),
      child: Row(
        children: [
          isDone
              ? const Icon(Icons.check_circle,
                  color: AppColors.success, size: 24)
              : isCurrent
                  ? SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(
                          strokeWidth: 2.5, color: color))
                  : Icon(icon, color: color, size: 24),
          const SizedBox(width: AppSpacing.sm),
          Text(
            label,
            style: AppTypography.bodyLarge.copyWith(
              color: isDone
                  ? AppColors.textSecondary
                  : isCurrent
                      ? AppColors.primary
                      : AppColors.neutral300,
              fontWeight:
                  isCurrent ? FontWeight.w600 : FontWeight.w400,
            ),
          ),
        ],
      ),
    );
  }
}
