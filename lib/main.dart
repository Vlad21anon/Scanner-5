import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hydrated_bloc/hydrated_bloc.dart';
import 'package:owl_tech_pdf_scaner/app/app_colors.dart';
import 'package:owl_tech_pdf_scaner/blocs/files_cubit/files_cubit.dart';
import 'package:owl_tech_pdf_scaner/blocs/scan_files_cubit/scan_files_cubit.dart';
import 'package:owl_tech_pdf_scaner/screens/files_page.dart';
import 'package:owl_tech_pdf_scaner/screens/settings_page.dart';
import 'package:owl_tech_pdf_scaner/services/navigation_service.dart';
import 'package:owl_tech_pdf_scaner/widgets/custom_navigation_bar.dart';
import 'package:path_provider/path_provider.dart';

import 'blocs/filter_cubit.dart';


void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  HydratedBloc.storage = await HydratedStorage.build(
    storageDirectory: kIsWeb
        ? HydratedStorageDirectory.web
        : HydratedStorageDirectory((await getTemporaryDirectory()).path),
  );
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
      ],
      child: MaterialApp(
        navigatorKey: NavigationService().navigatorKey,
        title: 'PDF Scanner',
        debugShowCheckedModeBanner: false,
        home: MainScreen(),
      ),
    );
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
