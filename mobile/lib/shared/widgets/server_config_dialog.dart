import 'package:flutter/material.dart';
import '../../core/config/app_config.dart';
import '../../core/theme/app_colors.dart';

Future<void> showServerConfigDialog(BuildContext context, {VoidCallback? onSaved}) async {
  final controller = TextEditingController(text: AppConfig.apiBaseUrl);
  final newUrl = await showDialog<String>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: const Row(
        children: [
          Icon(Icons.dns, color: AppColors.primary),
          SizedBox(width: 8),
          Text('Cài đặt máy chủ', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        ],
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Nhập địa chỉ IP máy tính chạy backend:',
            style: TextStyle(fontSize: 13),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: controller,
            decoration: const InputDecoration(
              hintText: 'http://192.168.101.10:8000',
              labelText: 'Server Base URL',
              border: OutlineInputBorder(),
              isDense: true,
            ),
            keyboardType: TextInputType.url,
          ),
          const SizedBox(height: 10),
          const Text(
            'Gợi ý:\n• Wi-Fi cùng máy tính: http://192.168.101.10:8000\n• Cắm cáp USB (adb reverse): http://127.0.0.1:8000',
            style: TextStyle(fontSize: 11, color: Colors.grey),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(ctx),
          child: const Text('Hủy'),
        ),
        ElevatedButton(
          onPressed: () => Navigator.pop(ctx, controller.text.trim()),
          child: const Text('Lưu'),
        ),
      ],
    ),
  );

  if (newUrl != null && newUrl.isNotEmpty) {
    await AppConfig.setBaseUrl(newUrl);
    onSaved?.call();
  }
}
