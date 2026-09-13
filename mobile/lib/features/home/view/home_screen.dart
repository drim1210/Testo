import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/api/api_service.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../data/models/models.dart';
import '../../../shared/widgets/app_card.dart';
import '../../../shared/widgets/server_config_dialog.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  List<SessionHistoryItem> _recent = const [];
  int _totalExams = 0;
  double _avgScore = 0;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final history = await ApiService.instance.getHistory();
      if (!mounted) return;
      setState(() {
        _recent = history.take(3).toList();
        _totalExams = history.length;
        _avgScore = history.isEmpty
            ? 0
            : history.fold<double>(0, (s, e) => s + e.score) / history.length;
      });
    } catch (_) {
      // Home works fine offline; empty state covers it.
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) context.go('/home');
      },
      child: Scaffold(
        body: SafeArea(
          child: RefreshIndicator(
            onRefresh: _load,
            child: CustomScrollView(
              physics: const AlwaysScrollableScrollPhysics(
                  parent: BouncingScrollPhysics()),
              slivers: [
                _buildHeader(context),
                _buildCreateSection(context),
                _buildRecentSection(context),
                _buildStatsSection(context),
                const SliverToBoxAdapter(
                    child: SizedBox(height: AppSpacing.xl)),
              ],
            ),
          ),
        ),
        bottomNavigationBar: _buildBottomNav(context),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.base, AppSpacing.lg, AppSpacing.base, AppSpacing.sm,
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Good day! 👋', style: AppTypography.bodyMedium),
                  SizedBox(height: AppSpacing.xs),
                  Text('What are you studying today?',
                      style: AppTypography.displayMedium),
                ],
              ),
            ),
            IconButton(
              icon: const Icon(Icons.dns_outlined, color: AppColors.primary),
              tooltip: 'Cài đặt máy chủ',
              onPressed: () => showServerConfigDialog(context, onSaved: _load),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCreateSection(BuildContext context) {
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.base),
        child: Container(
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [AppColors.primary, AppColors.primaryDark],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
          ),
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(Icons.auto_awesome, color: Colors.white, size: 32),
              const SizedBox(height: AppSpacing.sm),
              Text(
                'Create Exam from PDF',
                style: AppTypography.headlineLarge.copyWith(color: Colors.white),
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(
                'Upload any document and AI will generate quiz questions for you.',
                style: AppTypography.bodyMedium.copyWith(color: Colors.white70),
              ),
              const SizedBox(height: AppSpacing.base),
              ElevatedButton.icon(
                onPressed: () => context.push('/pick-document'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: AppColors.primary,
                  minimumSize: const Size(double.infinity, 48),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppSpacing.buttonRadius),
                  ),
                ),
                icon: const Icon(Icons.upload_file),
                label: const Text('Create New Exam',
                    style: AppTypography.labelLarge),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRecentSection(BuildContext context) {
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.base),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: AppSpacing.base),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Recent Exams', style: AppTypography.headlineMedium),
                if (_recent.isNotEmpty)
                  TextButton(
                    onPressed: () => context.push('/history'),
                    child: const Text('See all'),
                  ),
              ],
            ),
            const SizedBox(height: AppSpacing.sm),
            if (_recent.isEmpty)
              const AppCard(
                child: Column(
                  children: [
                    Icon(Icons.quiz_outlined,
                        size: 40, color: AppColors.neutral300),
                    SizedBox(height: AppSpacing.sm),
                    Text('No exams yet', style: AppTypography.bodyMedium),
                    SizedBox(height: AppSpacing.xs),
                    Text(
                      'Upload a PDF to create your first exam',
                      style: AppTypography.caption,
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              )
            else
              ..._recent.map((item) => Padding(
                    padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                    child: AppCard(
                      onTap: () => context.push('/result/${item.sessionId}'),
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(
                              item.examTitle ?? 'Exam',
                              style: AppTypography.labelLarge,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          Text(
                            '${(item.score * 100).round()}%',
                            style: AppTypography.labelLarge
                                .copyWith(color: AppColors.primary),
                          ),
                        ],
                      ),
                    ),
                  )),
          ],
        ),
      ),
    );
  }

  Widget _buildStatsSection(BuildContext context) {
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.base),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Quick Stats', style: AppTypography.headlineMedium),
            const SizedBox(height: AppSpacing.sm),
            Row(
              children: [
                Expanded(
                    child: _statCard('$_totalExams', 'Exams Created',
                        Icons.description_outlined)),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                    child: _statCard(
                        '${(_avgScore * 100).round()}%',
                        'Avg Score',
                        Icons.trending_up)),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                    child: _statCard('${_recent.length}', 'Recent',
                        Icons.bolt_outlined)),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _statCard(String value, String label, IconData icon) {
    return AppCard(
      child: Column(
        children: [
          Icon(icon, color: AppColors.primary, size: 20),
          const SizedBox(height: AppSpacing.xs),
          Text(value,
              style:
                  AppTypography.headlineLarge.copyWith(color: AppColors.primary)),
          Text(label, style: AppTypography.caption, textAlign: TextAlign.center),
        ],
      ),
    );
  }

  Widget _buildBottomNav(BuildContext context) {
    return NavigationBar(
      selectedIndex: 0,
      backgroundColor: Colors.white,
      elevation: 0,
      destinations: const [
        NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home),
            label: 'Home'),
        NavigationDestination(
            icon: Icon(Icons.history_outlined),
            selectedIcon: Icon(Icons.history),
            label: 'History'),
        NavigationDestination(
            icon: Icon(Icons.bar_chart_outlined),
            selectedIcon: Icon(Icons.bar_chart),
            label: 'Stats'),
      ],
      onDestinationSelected: (index) {
        if (index == 1) context.push('/history');
        if (index == 2) context.push('/stats');
      },
    );
  }
}
