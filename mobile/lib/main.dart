import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'core/app_state.dart';
import 'core/app_theme.dart';
import 'screens/login_screen.dart';
import 'widgets/bottom_nav_shell.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);
  runApp(const Spatial3DHomeApp());
}

/// Alias for compatibility with default Flutter test runners
class MyApp extends Spatial3DHomeApp {
  const MyApp({super.key});
}

class Spatial3DHomeApp extends StatefulWidget {
  const Spatial3DHomeApp({super.key});

  @override
  State<Spatial3DHomeApp> createState() => _Spatial3DHomeAppState();
}

class _Spatial3DHomeAppState extends State<Spatial3DHomeApp> {
  late final AppState _state;

  @override
  void initState() {
    super.initState();
    _state = AppState();
  }

  @override
  void dispose() {
    _state.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _state,
      builder: (context, _) {
        final palette =
            _state.isDarkMode ? SpatialPalette.dark : SpatialPalette.light;
        final theme = AppTheme.build(_state.isDarkMode);

        return MaterialApp(
          title: 'Spatial 3D Home',
          debugShowCheckedModeBanner: false,
          theme: theme,
          home: _state.isAuthenticated
              ? BottomNavShell(state: _state, palette: palette)
              : LoginScreen(state: _state, palette: palette),
        );
      },
    );
  }
}
