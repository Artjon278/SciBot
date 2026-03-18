import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'core/theme/app_theme.dart';
import 'core/theme/theme_provider.dart';
import 'services/auth_service.dart';
import 'services/chat_service.dart';
import 'services/bot_helper_service.dart';
import 'services/quiz_stats_service.dart';
import 'services/homework_service.dart';
import 'services/audiobook_service.dart';
import 'services/streak_service.dart';
import 'services/gamification_service.dart';
import 'services/mastery_service.dart';
import 'services/spaced_repetition_service.dart';
import 'services/curriculum_service.dart';
import 'services/weekly_report_service.dart';
import 'services/adaptive_ai_service.dart';
import 'services/daily_challenge_service.dart';
import 'services/notification_service.dart';
import 'screens/auth/login_screen.dart';
import 'screens/home/home_screen.dart';
import 'screens/onboarding/onboarding_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    await dotenv.load(fileName: '.env');

    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(statusBarColor: Colors.transparent),
    );

    runApp(
      MultiProvider(
        providers: [
          ChangeNotifierProvider(create: (_) => ThemeProvider()),
          ChangeNotifierProvider(create: (_) => AuthService()),
          ChangeNotifierProvider(create: (_) => ChatService()),
          ChangeNotifierProvider(create: (_) => QuizStatsService()),
          ChangeNotifierProxyProvider<AuthService, HomeworkService>(
            create: (context) => HomeworkService(context.read<AuthService>()),
            update: (context, auth, previous) => previous!..updateAuth(auth),
          ),
          ChangeNotifierProxyProvider<AuthService, AudiobookService>(
            create: (context) => AudiobookService(context.read<AuthService>()),
            update: (context, auth, previous) => previous!..updateAuth(auth),
          ),
          ChangeNotifierProvider(create: (_) {
            final service = BotHelperService();
            service.loadPreferences();
            return service;
          }),
          ChangeNotifierProvider(create: (_) {
            final service = StreakService();
            service.load();
            return service;
          }),
          ChangeNotifierProvider(create: (_) {
            final service = GamificationService();
            service.load();
            return service;
          }),
          ChangeNotifierProvider(create: (_) {
            final service = MasteryService();
            service.load();
            return service;
          }),
          ChangeNotifierProvider(create: (_) {
            final service = SpacedRepetitionService();
            service.load();
            return service;
          }),
          ChangeNotifierProvider(create: (_) {
            final service = CurriculumService();
            service.load();
            return service;
          }),
          ChangeNotifierProvider(create: (_) {
            final service = WeeklyReportService();
            service.load();
            return service;
          }),
          ChangeNotifierProvider(create: (_) {
            final service = AdaptiveAIService();
            service.load();
            return service;
          }),
          ChangeNotifierProvider(create: (_) {
            final service = DailyChallengeService();
            service.load();
            return service;
          }),
          ChangeNotifierProvider(create: (_) {
            final service = NotificationService();
            service.init();
            return service;
          }),
        ],
        child: const SciBot(),
      ),
    );
  } catch (e, stackTrace) {
    print('Error initializing app: $e');
    print('Stack trace: $stackTrace');
    runApp(
      MaterialApp(
        home: Scaffold(
          body: Center(
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, size: 48, color: Colors.red),
                  const SizedBox(height: 20),
                  const Text('Gabim në inicializimin e aplikacionit', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 10),
                  Text(e.toString(), textAlign: TextAlign.center, style: const TextStyle(fontSize: 14)),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class SciBot extends StatelessWidget {
  const SciBot({super.key});

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);

    return MaterialApp(
      title: 'SciBot',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: themeProvider.themeMode,
      home: const AuthHandler(),
    );
  }
}

class AuthHandler extends StatefulWidget {
  const AuthHandler({super.key});

  @override
  State<AuthHandler> createState() => _AuthHandlerState();
}

class _AuthHandlerState extends State<AuthHandler> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkAuthState();
    });
  }

  Future<void> _checkAuthState() async {
    if (!mounted) return;

    final authService = context.read<AuthService>();

    while (authService.isLoading) {
      await Future.delayed(const Duration(milliseconds: 100));
      if (!mounted) return;
    }

    if (!mounted) return;

    if (!authService.isLoggedIn) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const LoginScreen()),
      );
      return;
    }

    final botService = context.read<BotHelperService>();
    while (!botService.isLoaded) {
      await Future.delayed(const Duration(milliseconds: 100));
      if (!mounted) return;
    }

    if (!botService.onboardingCompleted) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (_) => OnboardingScreen(
            onComplete: () async {
              await botService.completeOnboarding();
            },
          ),
        ),
      );
    } else {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const HomeScreen()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(body: Center(child: CircularProgressIndicator()));
  }
}
