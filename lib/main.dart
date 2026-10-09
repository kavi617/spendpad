import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';

import 'models/category.dart';
import 'models/expense.dart';
import 'screen/main_screen.dart';
import 'screen/startup_screen.dart';
import 'services/category_service.dart';
import 'services/launch_experience_service.dart';
import 'services/settings_service.dart';
import 'theme/app_theme.dart';
import 'utils/app_format.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const SpendPad());
}

Future<({String? error, bool showIntro})> _initialize() async {
  try {
    await Hive.initFlutter();
    if (!Hive.isAdapterRegistered(0)) Hive.registerAdapter(ExpenseAdapter());
    if (!Hive.isAdapterRegistered(1)) Hive.registerAdapter(CategoryAdapter());

    // Detect older installs before opening boxes creates new ones. A pending
    // marker survives interrupted first launches without treating them as an
    // update on the next process start.
    final hadSettings = await Hive.boxExists(SettingsService.boxName);
    final hadExpenses = await Hive.boxExists('expenses');
    final hadCategories = await Hive.boxExists(CategoryService.boxName);
    final settings = await SettingsService.openBox();
    AppFormat.symbol = settings.get('currency', defaultValue: '₹') as String;

    final completed =
        settings.get('introCompleted', defaultValue: false) as bool;
    final pending = settings.get('introPending', defaultValue: false) as bool;
    final existingInstall = hadSettings || hadExpenses || hadCategories;
    final showIntro = LaunchExperienceService.shouldShowIntro(
      introCompleted: completed,
      introPending: pending,
      existingInstall: existingInstall,
    );
    if (showIntro && !pending) await settings.put('introPending', true);

    // Opening categories also restores category names from the saved expense
    // box. Do this before selecting the landing route or showing the intro.
    await CategoryService.getCategories();

    // Older versions did not store the intro flag. Their settings box marks
    // them as existing installs, so they skip the long intro after updating.
    if (existingInstall && !completed && !showIntro) {
      await settings.put('introCompleted', true);
    }
    return (error: null, showIntro: showIntro);
  } catch (_) {
    return (
      error:
          'SpendPad could not open its saved data. Check available storage and try again.',
      showIntro: false,
    );
  }
}

enum _StartupPhase { initializing, intro, ready, error }

class SpendPad extends StatefulWidget {
  const SpendPad({super.key});

  @override
  State<SpendPad> createState() => _SpendPadState();
}

class _SpendPadState extends State<SpendPad> {
  _StartupPhase _phase = _StartupPhase.initializing;
  String? _startupError;

  @override
  void initState() {
    super.initState();
    _initializeApp();
  }

  Future<void> _initializeApp() async {
    setState(() {
      _phase = _StartupPhase.initializing;
      _startupError = null;
    });
    final result = await _initialize();
    if (!mounted) return;
    if (result.error != null) {
      setState(() {
        _phase = _StartupPhase.error;
        _startupError = result.error;
      });
      return;
    }
    setState(
      () =>
          _phase = result.showIntro ? _StartupPhase.intro : _StartupPhase.ready,
    );
  }

  Future<void> _completeIntro() async {
    try {
      final settings = await SettingsService.openBox();
      // Mark complete before clearing the pending marker. If the latter fails,
      // the completed flag still prevents the intro from replaying.
      await settings.put('introCompleted', true);
      await settings.delete('introPending');
      if (mounted) setState(() => _phase = _StartupPhase.ready);
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _phase = _StartupPhase.error;
        _startupError =
            'SpendPad could not save its first-launch setup. Please try again.';
      });
    }
  }

  Widget _pageForPhase() => switch (_phase) {
    _StartupPhase.initializing => const _StartupLoading(
      key: ValueKey('loading'),
    ),
    _StartupPhase.intro => StartupScreen(
      key: const ValueKey('intro'),
      onComplete: _completeIntro,
    ),
    _StartupPhase.ready => const MainScreen(key: ValueKey('main')),
    _StartupPhase.error => _StartupError(
      key: const ValueKey('error'),
      message: _startupError ?? 'SpendPad could not start.',
      onRetry: _initializeApp,
    ),
  };

  @override
  Widget build(BuildContext context) => MaterialApp(
    debugShowCheckedModeBanner: false,
    title: 'SpendPad',
    theme: AppTheme.light(),
    darkTheme: AppTheme.dark(),
    themeMode: ThemeMode.system,
    home: AnimatedSwitcher(
      duration: MediaQuery.disableAnimationsOf(context)
          ? Duration.zero
          : const Duration(milliseconds: 220),
      switchInCurve: Curves.easeOutCubic,
      switchOutCurve: Curves.easeInCubic,
      transitionBuilder: (child, animation) => FadeTransition(
        opacity: animation,
        child: ScaleTransition(
          scale: Tween<double>(begin: .985, end: 1).animate(animation),
          child: child,
        ),
      ),
      child: _pageForPhase(),
    ),
  );
}

class _StartupLoading extends StatelessWidget {
  const _StartupLoading({super.key});

  @override
  Widget build(BuildContext context) => const Scaffold(
    backgroundColor: StartupScreen.navy,
    body: Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          StartupBrandMark(size: 64),
          SizedBox(height: 20),
          SizedBox(
            width: 22,
            height: 22,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: Color(0xFF69B5FF),
            ),
          ),
        ],
      ),
    ),
  );
}

class _StartupError extends StatelessWidget {
  const _StartupError({
    super.key,
    required this.message,
    required this.onRetry,
  });
  final String message;
  final Future<void> Function() onRetry;

  @override
  Widget build(BuildContext context) => Scaffold(
    body: Center(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.storage_rounded, size: 44),
            const SizedBox(height: 16),
            Text(message, textAlign: TextAlign.center),
            const SizedBox(height: 16),
            FilledButton(onPressed: onRetry, child: const Text('Try again')),
          ],
        ),
      ),
    ),
  );
}
