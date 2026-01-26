import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'services/hive_service.dart';
import 'services/notification_service.dart';
import 'screens/main_screen.dart';
import 'providers/theme_provider.dart' as theme_provider;

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Inicializar formato de fechas en español
  await initializeDateFormatting('es', null);

  // Inicializar Hive
  final hiveService = HiveService();
  await hiveService.initialize();

  // Inicializar servicio de notificaciones
  final notificationService = NotificationService();
  await notificationService.initialize();
  await notificationService.requestPermissions();

  runApp(const ProviderScope(child: MyApp()));
}

class MyApp extends ConsumerWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(theme_provider.themeProvider);

    return MaterialApp(
      title: 'Gestión de Calendario - Miguel Ángel Rosales',
      debugShowCheckedModeBanner: false,
      theme: theme_provider.lightTheme,
      darkTheme: theme_provider.darkTheme,
      themeMode: _getFlutterThemeMode(themeMode),
      home: const MainScreen(),
    );
  }

  ThemeMode _getFlutterThemeMode(theme_provider.ThemeMode mode) {
    switch (mode) {
      case theme_provider.ThemeMode.light:
        return ThemeMode.light;
      case theme_provider.ThemeMode.dark:
        return ThemeMode.dark;
      case theme_provider.ThemeMode.system:
        return ThemeMode.system;
    }
  }
}
