import 'package:flutter/material.dart';

import '../../../core/api/api_service.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../shared/widgets/app_card.dart';

class StatsScreen extends StatefulWidget {
  const StatsScreen({super.key});

  @override
  State<StatsScreen> createState() => _StatsScreenState();
}

class _StatsScreenState extends State<StatsScreen> {
  bool _loading = true;
  String? _error;
  Map<String, dynamic>? _overview;
  List<Map<String, dynamic>> _topicStats = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final results = await Future.wait([
        ApiService.instance.getOverview(),
        ApiService.instance.getTopicStats(),
      ]);
      if (!mounted) return;
      setState(() {
        _overview = results[0] as Map<String, dynamic>;
        _topicStats = results[1] as List<Map<String, dynamic>>;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = extractErrorMessage(e);
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Statistics'),
        backgroundColor: Colors.white,
        foregroundColor: AppColors.neutral900,
        elevation: 0,
      ),
      body: RefreshIndicator(
        onRefresh: _load,
        child: _buildBody(),
      ),
    );
  }

  Widget _buildBody() {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline,
                  size: 48, color: AppColors.neutral300),
              const SizedBox(height: AppSpacing.sm),
              Text(_error!, style: AppTypography.bodyMedium,
                  textAlign: TextAlign.center),
              const SizedBox(height: AppSpacing.base),
              ElevatedButton(
                onPressed: _load,
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }
    if (_overview == null) {
      return const Center(
        child: Text('No statistics available.', style: AppTypography.bodyMedium),
      );
    }

    return ListView(
      padding: const EdgeInsets.all(AppSpacing.base),
      children: [
        _buildOverview(),
        const SizedBox(height: AppSpacing.lg),
        _buildTopicBreakdown(),
      ],
    );
  }

  Widget _buildOverview() {
    final totalExams = _overview!['total_exams'] ?? 0;
    final avgScore = (_overview!['average_score'] as num?)?.toDouble() ?? 0.0;
    final bestScore = (_overview!['best_score'] as num?)?.toDouble() ?? 0.0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Overview', style: AppTypography.headlineMedium),
        const SizedBox(height: AppSpacing.sm),
        Row(
          children: [
            Expanded(
              child: _overviewCard(
                label: 'Total Exams',
                value: '$totalExams',
                icon: Icons.description_outlined,
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: _overviewCard(
                label: 'Avg Score',
                value: '${(avgScore * 100).round()}%',
                icon: Icons.trending_up,
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: _overviewCard(
                label: 'Best Score',
                value: '${(bestScore * 100).round()}%',
                icon: Icons.emoji_events_outlined,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _overviewCard({
    required String label,
    required String value,
    required IconData icon,
  }) {
    return AppCard(
      child: Column(
        children: [
          Icon(icon, color: AppColors.primary, size: 24),
          const SizedBox(height: AppSpacing.xs),
          Text(
            value,
            style: AppTypography.headlineLarge.copyWith(color: AppColors.primary),
          ),
          Text(label,
              style: AppTypography.caption, textAlign: TextAlign.center),
        ],
      ),
    );
  }

  Widget _buildTopicBreakdown() {
    if (_topicStats.isEmpty) {
      return const AppCard(
        child: Column(
          children: [
            Icon(Icons.bar_chart_outlined, size: 40, color: AppColors.neutral300),
            SizedBox(height: AppSpacing.sm),
            Text('No topic data yet', style: AppTypography.bodyMedium),
            SizedBox(height: AppSpacing.xs),
            Text(
              'Complete some exams to see topic statistics',
              style: AppTypography.caption,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Topic Breakdown', style: AppTypography.headlineMedium),
        const SizedBox(height: AppSpacing.sm),
        ..._topicStats.map((t) => _topicRow(t)),
      ],
    );
  }

  Widget _topicRow(Map<String, dynamic> t) {
    final topic = t['topic'] as String? ?? 'Unknown';
    final percentage = (t['percentage'] as num?)?.toDouble() ?? 0.0;
    final total = t['total'] as int? ?? 0;
    final correct = t['correct'] as int? ?? 0;

    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: AppCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    topic,
                    style: AppTypography.labelLarge,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Text(
                  '${(percentage * 100).round()}%',
                  style: AppTypography.labelLarge
                      .copyWith(color: AppColors.primary),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.xs),
            LinearProgressIndicator(
              value: percentage.clamp(0.0, 1.0),
              backgroundColor: AppColors.neutral300,
              valueColor: const AlwaysStoppedAnimation<Color>(AppColors.primary),
              borderRadius: BorderRadius.circular(4),
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              '$correct / $total correct',
              style: AppTypography.caption,
            ),
          ],
        ),
      ),
    );
  }
}
