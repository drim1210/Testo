import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:go_router/go_router.dart';
import '../../../core/api/api_service.dart';
import '../../../core/config/app_config.dart';
import '../../../data/models/models.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../shared/widgets/app_button.dart';
import '../../../shared/widgets/server_config_dialog.dart';

class DocumentPickerScreen extends StatefulWidget {
  const DocumentPickerScreen({super.key});

  @override
  State<DocumentPickerScreen> createState() => _DocumentPickerScreenState();
}

class _DocumentPickerScreenState extends State<DocumentPickerScreen> {
  PlatformFile? _selectedFile;
  String? _error;
  bool _isBusy = false;
  String _statusLabel = '';

  static const int _maxFileSizeMB = 50;

  Future<void> _pickFile() async {
    setState(() {
      _error = null;
    });

    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf', 'docx', 'doc'],
      withData: false,
      withReadStream: false,
    );

    if (result == null || result.files.isEmpty) return;

    final file = result.files.first;

    if (file.size > _maxFileSizeMB * 1024 * 1024) {
      setState(() {
        _error = 'File too large. Maximum ${_maxFileSizeMB}MB allowed.';
      });
      return;
    }

    setState(() {
      _selectedFile = file;
    });
  }

  Future<void> _uploadAndProcess() async {
    final picked = _selectedFile;
    if (picked == null || picked.path == null) return;

    setState(() {
      _isBusy = true;
      _error = null;
      _statusLabel = 'Uploading...';
    });

    try {
      final doc = await ApiService.instance
          .uploadDocument(File(picked.path!), onProgress: (p) {
        if (!mounted) return;
        setState(() {
          _statusLabel = 'Uploading... ${(p * 100).toStringAsFixed(0)}%';
        });
      });

      final status = await _pollDocumentReady(doc.id);
      if (!mounted) return;
      if (!_isBusy) {
        // User cancelled
        return;
      }

      if (status.status == 'ready') {
        setState(() {
          _isBusy = false;
          _statusLabel = '';
        });
        await context.push('/configure', extra: doc.id);
        if (mounted) {
          setState(() {
            _isBusy = false;
            _statusLabel = '';
          });
        }
      } else {
        setState(() {
          _isBusy = false;
          _statusLabel = '';
          _error = status.errorMessage ??
              'Could not read this PDF. Make sure it contains selectable text.';
        });
      }
    } catch (e) {
      if (!mounted || !_isBusy) return;
      setState(() {
        _isBusy = false;
        _statusLabel = '';
        _error = extractErrorMessage(e);
      });
    } finally {
      if (mounted) {
        setState(() {
          _isBusy = false;
          _statusLabel = '';
        });
      }
    }
  }

  Future<DocumentStatus> _pollDocumentReady(String docId) async {
    final deadline = DateTime.now().add(const Duration(seconds: 60));
    while (DateTime.now().isBefore(deadline)) {
      if (!mounted || !_isBusy) {
        return DocumentStatus(id: docId, status: 'failed', errorMessage: 'Cancelled');
      }
      final status = await ApiService.instance.getDocumentStatus(docId);
      if (status.status == 'ready' || status.status == 'failed') {
        return status;
      }
      if (!mounted || !_isBusy) {
        return DocumentStatus(id: docId, status: 'failed', errorMessage: 'Cancelled');
      }
      setState(() {
        _statusLabel = status.status == 'processing'
            ? 'Reading document...'
            : 'Queued for processing...';
      });
      await Future.delayed(AppConfig.pollInterval);
    }
    return DocumentStatus(
        id: docId, status: 'failed', errorMessage: 'Processing timed out.');
  }

  String _formatSize(int bytes) {
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    return '${(bytes / 1024 / 1024).toStringAsFixed(1)} MB';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Select Document'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            setState(() {
              _isBusy = false;
              _statusLabel = '';
            });
            context.pop();
          },
        ),
      ),
      body: PopScope(
        canPop: true,
        onPopInvokedWithResult: (didPop, _) {
          if (didPop) {
            _isBusy = false;
            _statusLabel = '';
          }
        },
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.base),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                'Chọn tài liệu PDF hoặc Word (.docx) để tạo đề thi trắc nghiệm.',
                style: AppTypography.bodyMedium,
              ),
              const SizedBox(height: AppSpacing.lg),
              _pickArea(),
              if (_error != null) ...[
                const SizedBox(height: AppSpacing.sm),
                Container(
                  padding: const EdgeInsets.all(AppSpacing.sm),
                  decoration: BoxDecoration(
                    color: AppColors.error.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
                    border: Border.all(color: AppColors.error.withValues(alpha: 0.3)),
                  ),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.error_outline,
                              color: AppColors.error, size: 18),
                          const SizedBox(width: AppSpacing.xs),
                          Expanded(
                            child: Text(
                              _error!,
                              style: AppTypography.caption
                                  .copyWith(color: AppColors.error),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Align(
                        alignment: Alignment.centerRight,
                        child: TextButton.icon(
                          onPressed: () => showServerConfigDialog(context),
                          icon: const Icon(Icons.settings, size: 14),
                          label: const Text('Đổi IP máy chủ', style: TextStyle(fontSize: 12)),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              const Spacer(),
              if (_isBusy && _statusLabel.isNotEmpty) ...[
                const LinearProgressIndicator(
                  minHeight: 4,
                  backgroundColor: AppColors.neutral200,
                  valueColor:
                      AlwaysStoppedAnimation<Color>(AppColors.primary),
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(_statusLabel, style: AppTypography.caption),
                    TextButton(
                      onPressed: () {
                        setState(() {
                          _isBusy = false;
                          _statusLabel = '';
                        });
                      },
                      child: const Text('Hủy', style: TextStyle(color: AppColors.error, fontSize: 13)),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.sm),
              ],
              AppButton(
                label: 'Continue',
                onPressed: _selectedFile != null && !_isBusy
                    ? _uploadAndProcess
                    : null,
                isLoading: _isBusy,
                icon: Icons.arrow_forward,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _pickArea() {
    return GestureDetector(
      onTap: _isBusy ? null : _pickFile,
      child: Container(
        height: 180,
        decoration: BoxDecoration(
          color: AppColors.neutral100,
          borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
          border: Border.all(
            color: _selectedFile != null ? AppColors.primary : AppColors.neutral300,
            width: _selectedFile != null ? 2 : 1,
          ),
        ),
        child: _selectedFile == null
            ? Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.upload_file,
                      size: 48, color: AppColors.neutral400),
                  const SizedBox(height: AppSpacing.sm),
                  const Text('Chạm để chọn tài liệu',
                      style: AppTypography.bodyMedium),
                  const SizedBox(height: AppSpacing.xs),
                  Text('Hỗ trợ PDF, Word (.docx) • Tối đa ${_maxFileSizeMB}MB',
                      style: AppTypography.caption),
                ],
              )
            : Padding(
                padding: const EdgeInsets.all(AppSpacing.base),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      _selectedFile!.name.toLowerCase().endsWith('.docx')
                          ? Icons.description
                          : Icons.picture_as_pdf,
                      size: 48,
                      color: _selectedFile!.name.toLowerCase().endsWith('.docx')
                          ? AppColors.primary
                          : AppColors.error,
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    Text(
                      _selectedFile!.name,
                      style: AppTypography.labelLarge,
                      textAlign: TextAlign.center,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Text(_formatSize(_selectedFile!.size),
                        style: AppTypography.caption),
                    const SizedBox(height: AppSpacing.sm),
                    TextButton.icon(
                      onPressed: _isBusy ? null : _pickFile,
                      icon: const Icon(Icons.swap_horiz, size: 16),
                      label: const Text('Chọn tài liệu khác'),
                    ),
                  ],
                ),
              ),
      ),
    );
  }
}
