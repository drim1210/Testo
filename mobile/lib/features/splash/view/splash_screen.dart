import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/api/api_service.dart';
import '../../../core/config/app_config.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../shared/widgets/server_config_dialog.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  String? _errorMessage;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _startInit();
  }

  Future<void> _startInit() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    await AppConfig.loadSavedUrl();
    await Future.delayed(const Duration(milliseconds: 1000));
    if (!mounted) return;

    try {
      await ApiService.instance.auth.ensureAuthenticated();
      if (!mounted) return;
      context.go('/home');
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _errorMessage = extractErrorMessage(e);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.primary,
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Spacer(),
                const Icon(
                  Icons.auto_awesome,
                  size: 72,
                  color: Colors.white,
                ),
                const SizedBox(height: AppSpacing.base),
                Text(
                  'Testo',
                  style: AppTypography.displayLarge.copyWith(color: Colors.white),
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  'AI-Powered Learning',
                  style: AppTypography.bodyMedium.copyWith(color: Colors.white70),
                ),
                const Spacer(),

                if (_isLoading) ...[
                  const CircularProgressIndicator(color: Colors.white),
                  const SizedBox(height: AppSpacing.base),
                  Text(
                    'Đang kết nối: ${AppConfig.apiBaseUrl}',
                    style: const TextStyle(color: Colors.white60, fontSize: 12),
                    textAlign: TextAlign.center,
                  ),
                ] else if (_errorMessage != null) ...[
                  Container(
                    padding: const EdgeInsets.all(AppSpacing.base),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
                    ),
                    child: Column(
                      children: [
                        const Icon(Icons.wifi_off, color: Colors.white, size: 36),
                        const SizedBox(height: AppSpacing.sm),
                        Text(
                          'Không thể kết nối máy chủ',
                          style: AppTypography.headlineMedium.copyWith(color: Colors.white),
                        ),
                        const SizedBox(height: AppSpacing.xs),
                        Text(
                          'Máy chủ hiện tại:\n${AppConfig.apiBaseUrl}',
                          style: const TextStyle(color: Colors.white70, fontSize: 12),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: AppSpacing.base),
                        Row(
                          children: [
                            Expanded(
                              child: OutlinedButton(
                                onPressed: () => showServerConfigDialog(context, onSaved: _startInit),
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: Colors.white,
                                  side: const BorderSide(color: Colors.white70),
                                ),
                                child: const Text('Đổi IP máy chủ'),
                              ),
                            ),
                            const SizedBox(width: AppSpacing.sm),
                            Expanded(
                              child: ElevatedButton(
                                onPressed: _startInit,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.white,
                                  foregroundColor: AppColors.primary,
                                ),
                                child: const Text('Thử lại'),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
                const SizedBox(height: AppSpacing.lg),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
