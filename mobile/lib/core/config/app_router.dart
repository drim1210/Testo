import 'package:go_router/go_router.dart';

// Feature imports
import '../../features/splash/view/splash_screen.dart';
import '../../features/home/view/home_screen.dart';
import '../../features/stats/view/stats_screen.dart';
import '../../features/document_picker/view/document_picker_screen.dart';
import '../../features/exam_config/view/exam_config_screen.dart';
import '../../features/generating/view/generating_screen.dart';
import '../../features/quiz/view/quiz_screen.dart';
import '../../features/result/view/result_screen.dart';
import '../../features/review/view/review_screen.dart';
import '../../features/history/view/history_screen.dart';

class AppRouter {
  static final GoRouter router = GoRouter(
    initialLocation: '/',
    routes: [
      GoRoute(path: '/', builder: (_, __) => const SplashScreen()),
      GoRoute(path: '/home', builder: (_, __) => const HomeScreen()),
      GoRoute(path: '/stats', builder: (_, __) => const StatsScreen()),
      GoRoute(path: '/pick-document', builder: (_, __) => const DocumentPickerScreen()),
      GoRoute(
        path: '/configure',
        builder: (context, state) {
          final docId = state.extra as String? ?? '';
          return ExamConfigScreen(documentId: docId);
        },
      ),
      GoRoute(
        path: '/generating/:examId',
        builder: (context, state) {
          return GeneratingScreen(examId: state.pathParameters['examId']!);
        },
      ),
      GoRoute(
        path: '/quiz/:examId',
        builder: (context, state) {
          return QuizScreen(examId: state.pathParameters['examId']!);
        },
      ),
      GoRoute(
        path: '/result/:sessionId',
        builder: (context, state) {
          return ResultScreen(sessionId: state.pathParameters['sessionId']!);
        },
      ),
      GoRoute(
        path: '/review/:sessionId',
        builder: (context, state) {
          return ReviewScreen(sessionId: state.pathParameters['sessionId']!);
        },
      ),
      GoRoute(path: '/history', builder: (_, __) => const HistoryScreen()),
    ],
  );
}
