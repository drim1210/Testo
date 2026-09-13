import 'package:flutter/material.dart';
import 'package:logger/logger.dart';

import 'app.dart';
import 'core/api/api_service.dart';

final logger = Logger();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    await AuthService().ensureAuthenticated();
  } catch (e) {
    logger.w('Anonymous auth failed — will retry on first request', error: e);
  }
  runApp(const TestoApp());
}
