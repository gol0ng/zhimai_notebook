import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'core/theme/app_theme.dart';
import 'data/database/database_manager.dart';
import 'data/repositories/note_repository_impl.dart';
import 'presentation/providers/note_provider.dart';
import 'presentation/providers/canvas_provider.dart';
import 'presentation/pages/home_page.dart';

class App extends StatelessWidget {
  const App({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        // Database
        Provider<DatabaseManager>(
          create: (_) => DatabaseManager.instance,
        ),
        // Repository
        ProxyProvider<DatabaseManager, NoteRepositoryImpl>(
          update: (_, dbManager, __) => NoteRepositoryImpl(dbManager),
        ),
        // Note Provider
        ChangeNotifierProxyProvider<NoteRepositoryImpl, NoteProvider>(
          create: (context) => NoteProvider(context.read<NoteRepositoryImpl>()),
          update: (_, repository, previous) =>
              previous ?? NoteProvider(repository),
        ),
        // Canvas Provider
        ChangeNotifierProxyProvider<NoteRepositoryImpl, CanvasProvider>(
          create: (context) => CanvasProvider(context.read<NoteRepositoryImpl>()),
          update: (_, repository, previous) =>
              previous ?? CanvasProvider(repository),
        ),
      ],
      child: MaterialApp(
        title: 'ZhiMaiNote',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.lightTheme,
        darkTheme: AppTheme.darkTheme,
        themeMode: ThemeMode.system,
        home: const HomePage(),
      ),
    );
  }
}
