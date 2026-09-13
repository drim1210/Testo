import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/api/api_service.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../shared/widgets/app_button.dart';
import '../../../shared/widgets/app_card.dart';

class ExamConfigScreen extends StatefulWidget {
  final String documentId;
  const ExamConfigScreen({super.key, required this.documentId});

  @override
  State<ExamConfigScreen> createState() => _ExamConfigScreenState();
}

class _ExamConfigScreenState extends State<ExamConfigScreen> {
  int _numQuestions = 20;
  String _difficulty = 'mixed';
  String _questionType = 'mcq';
  bool _focusImportant = true;
  bool _isGenerating = false;
  String? _error;

  final _questionCounts = [10, 20, 30, 50];
  final _difficulties = {'easy': 'Easy', 'medium': 'Medium', 'hard': 'Hard', 'mixed': 'Mixed'};
  final _questionTypes = {'mcq': 'Multiple Choice', 'true_false': 'True / False'};

  Future<void> _generate() async {
    setState(() { _isGenerating = true; _error = null; });
    try {
      final examId = await ApiService.instance.createExam(
        documentId: widget.documentId,
        numQuestions: _numQuestions,
        difficulty: _difficulty,
        questionType: _questionType,
        focusImportant: _focusImportant,
      );
      if (!mounted) return;
      context.pushReplacement('/generating/$examId');
    } catch (e) {
      if (!mounted) return;
      setState(() { _isGenerating = false; _error = extractErrorMessage(e); });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Configure Exam'),
        leading: IconButton(icon: const Icon(Icons.arrow_back), onPressed: () => context.pop()),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.base),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _section(
              'Number of Questions',
              Wrap(
                spacing: AppSpacing.sm,
                children: _questionCounts.map((n) => ChoiceChip(
                  label: Text('$n'),
                  selected: _numQuestions == n,
                  selectedColor: AppColors.primary,
                  labelStyle: TextStyle(
                    color: _numQuestions == n ? Colors.white : AppColors.textPrimary,
                    fontWeight: FontWeight.w600,
                  ),
                  onSelected: (_) => setState(() => _numQuestions = n),
                )).toList(),
              ),
            ),

            const SizedBox(height: AppSpacing.base),
            _section(
              'Difficulty',
              Wrap(
                spacing: AppSpacing.sm,
                runSpacing: AppSpacing.sm,
                children: _difficulties.entries.map((e) => ChoiceChip(
                  label: Text(e.value),
                  selected: _difficulty == e.key,
                  selectedColor: AppColors.primary,
                  labelStyle: TextStyle(
                    color: _difficulty == e.key ? Colors.white : AppColors.textPrimary,
                    fontWeight: FontWeight.w600,
                  ),
                  onSelected: (_) => setState(() => _difficulty = e.key),
                )).toList(),
              ),
            ),

            const SizedBox(height: AppSpacing.base),
            _section(
              'Question Type',
              Wrap(
                spacing: AppSpacing.sm,
                children: _questionTypes.entries.map((e) => ChoiceChip(
                  label: Text(e.value),
                  selected: _questionType == e.key,
                  selectedColor: AppColors.primary,
                  labelStyle: TextStyle(
                    color: _questionType == e.key ? Colors.white : AppColors.textPrimary,
                    fontWeight: FontWeight.w600,
                  ),
                  onSelected: (_) => setState(() => _questionType = e.key),
                )).toList(),
              ),
            ),

            const SizedBox(height: AppSpacing.base),
            AppCard(
              child: SwitchListTile(
                title: const Text('Focus on Important Concepts', style: AppTypography.labelLarge),
                subtitle: const Text('AI will prioritize key topics from the document', style: AppTypography.caption),
                value: _focusImportant,
                onChanged: (v) => setState(() => _focusImportant = v),
                activeThumbColor: AppColors.primary,
                contentPadding: EdgeInsets.zero,
              ),
            ),

            const SizedBox(height: AppSpacing.lg),
            _summaryCard(),
            if (_error != null) ...[
              const SizedBox(height: AppSpacing.sm),
              Text(_error!, style: AppTypography.caption.copyWith(color: AppColors.error)),
            ],
            const SizedBox(height: AppSpacing.lg),
            AppButton(
              label: 'Generate Exam',
              onPressed: _isGenerating ? null : _generate,
              isLoading: _isGenerating,
              icon: Icons.auto_awesome,
            ),
          ],
        ),
      ),
    );
  }

  Widget _section(String title, Widget child) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: AppTypography.headlineMedium),
        const SizedBox(height: AppSpacing.sm),
        child,
      ],
    );
  }

  Widget _summaryCard() {
    return AppCard(
      color: AppColors.neutral100,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Exam Summary', style: AppTypography.labelLarge),
          const Divider(height: AppSpacing.base),
          _row('Questions', '$_numQuestions'),
          _row('Difficulty', _difficulties[_difficulty]!),
          _row('Type', _questionTypes[_questionType]!),
          _row('Focus Mode', _focusImportant ? 'On' : 'Off'),
        ],
      ),
    );
  }

  Widget _row(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: AppTypography.bodyMedium),
          Text(value, style: AppTypography.labelLarge.copyWith(color: AppColors.primary)),
        ],
      ),
    );
  }
}
