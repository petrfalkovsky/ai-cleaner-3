import 'package:ai_cleaner_2/generated/l10n.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import '../core/router/router.dart';
import '../core/theme/theme_data.dart';
import 'package:flutter/material.dart';

final appRouter = AppRouter();

class App extends StatelessWidget {
  const App({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      debugShowCheckedModeBanner: false,
      routerConfig: appRouter.config(),
      theme: theme(context),
      localizationsDelegates: const [
        Locales.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ],
      supportedLocales: const [Locale('en')],
    );
  }
}
