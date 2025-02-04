import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hydrated_bloc/hydrated_bloc.dart';
import 'package:owl_tech_pdf_scaner/app/app_colors.dart';
import 'package:owl_tech_pdf_scaner/blocs/files_cubit/files_cubit.dart';
import 'package:owl_tech_pdf_scaner/blocs/scan_files_cubit/scan_files_cubit.dart';
import 'package:owl_tech_pdf_scaner/blocs/text_edit_cubit.dart';
import 'package:owl_tech_pdf_scaner/screens/files_page.dart';
import 'package:owl_tech_pdf_scaner/screens/loading_screen.dart';
import 'package:owl_tech_pdf_scaner/screens/settings_page.dart';
import 'package:owl_tech_pdf_scaner/services/navigation_service.dart';
import 'package:owl_tech_pdf_scaner/services/permission_service.dart';
import 'package:owl_tech_pdf_scaner/services/revenuecat_service.dart';
import 'package:owl_tech_pdf_scaner/widgets/custom_navigation_bar.dart';
import 'package:owl_tech_pdf_scaner/screens/onboarding_screen.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'blocs/filter_cubit.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  HydratedBloc.storage = await HydratedStorage.build(
    storageDirectory: kIsWeb
        ? HydratedStorageDirectory.web
        : HydratedStorageDirectory((await getTemporaryDirectory()).path),
  );

  // Инициализируем RevenueCat через новый метод configure()
  await RevenueCatService().init();

  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(
          create: (context) => ScanFilesCubit(),
        ),
        BlocProvider(
          create: (context) => FilesCubit(),
        ),
        BlocProvider(
          create: (context) => FilterCubit(),
        ),
        BlocProvider(
          create: (context) => TextEditCubit(),
        ),
      ],
      child: MaterialApp(
        navigatorKey: NavigationService().navigatorKey,
        title: 'PDF Scanner',
        debugShowCheckedModeBanner: false,
        home: const LaunchDecider(),
      ),
    );
  }
}

/// Этот виджет определяет, показывать ли экран онбординга или основной экран.
class LaunchDecider extends StatefulWidget {
  const LaunchDecider({super.key});

  @override
  State<LaunchDecider> createState() => _LaunchDeciderState();
}

class _LaunchDeciderState extends State<LaunchDecider> {
  bool _isFirstLaunch = true;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _checkFirstLaunch();
  }

  Future<void> _checkFirstLaunch() async {
    final prefs = await SharedPreferences.getInstance();
    // Если флага нет, значит приложение запускается впервые
    final alreadyLaunched = prefs.getBool('alreadyLaunched') ?? false;
    if (alreadyLaunched) {
      _isFirstLaunch = false;
    } else {
      _isFirstLaunch = true;
      await prefs.setBool('alreadyLaunched', true);
    }
    setState(() {
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      // Можно вернуть загрузочный экран или пустой контейнер
      return const LoadingScreen();
    }
    return _isFirstLaunch ? const OnboardingScreen() : const MainScreen();
  }
}

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _selectedIndex = 0;

  final List<Widget> _screens = [
    FilesPage(),
    SettingsScreen(),
  ];

  @override
  void initState() {
    super.initState();
    // Запрашиваем разрешения на камеру и микрофон при запуске экрана
    PermissionService().requestCameraAndMicrophonePermissions();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Stack(
        alignment: Alignment.center,
        children: [
          IndexedStack(
            index: _selectedIndex,
            children: _screens,
          ),
          Positioned(
            bottom: 46,
            child: CustomNavigationBar(
              currentIndex: _selectedIndex,
              onTap: (index) => setState(() => _selectedIndex = index),
            ),
          )
        ],
      ),
    );
  }
}
