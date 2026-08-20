import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';
import 'package:qr_scanner/app/shell.dart';
import 'package:qr_scanner/app/theme/app_theme.dart';
import 'package:qr_scanner/core/constants/app_constants.dart';
import 'package:qr_scanner/core/services/clipboard_service.dart';
import 'package:qr_scanner/core/services/launch_service.dart';
import 'package:qr_scanner/core/services/permission_service.dart';
import 'package:qr_scanner/core/services/share_service.dart';
import 'package:qr_scanner/features/history/data/history_controller.dart';

class OkutuyoApp extends StatelessWidget {
  const OkutuyoApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => HistoryController()),
        Provider(create: (_) => const ClipboardService()),
        Provider(create: (_) => const ShareService()),
        Provider(create: (_) => const LaunchService()),
        Provider(create: (_) => const PermissionService()),
      ],
      child: MaterialApp(
        title: AppConstants.appName,
        debugShowCheckedModeBanner: false,
        theme: buildLightTheme(),
        darkTheme: buildDarkTheme(),
        themeMode: ThemeMode.system,
        locale: const Locale('tr'),
        supportedLocales: const [Locale('tr'), Locale('en')],
        localizationsDelegates: const [
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        home: const AppShell(),
      ),
    );
  }
}
