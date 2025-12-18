import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:ramstech/data/notifiers.dart';
import 'package:ramstech/firebase_options.dart';
import 'package:ramstech/pages/splash_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(const MyApp());
  // precacheImage(, context);
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder(
      valueListenable: isDarkNotififier,
      builder: (context, isDark, child) {
        return MaterialApp(
          title: 'RamsTech',
          themeMode: isDark == null
              ? ThemeMode.system
              : isDark
                  ? ThemeMode.dark
                  : ThemeMode.light,
          theme: ThemeData(
            colorScheme: ColorScheme.fromSeed(
              seedColor: Colors.blue,
              brightness: Brightness.light,
            ),
            useMaterial3: true,
          ),
          darkTheme: ThemeData(
            colorScheme: ColorScheme.fromSeed(
              seedColor: Colors.blue,
              brightness: Brightness.dark,
            ),
            appBarTheme: const AppBarTheme(
              color: Colors.blue,
            ),
          ),
          home: SplashScreen(),
        );
      },
    );
  }
}
