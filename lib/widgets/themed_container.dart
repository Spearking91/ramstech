import 'package:flutter/material.dart';

class CContainer extends StatelessWidget {
  const CContainer({super.key, required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: [
          Theme.of(context).colorScheme.inversePrimary,
          Theme.of(context).colorScheme.onPrimaryFixedVariant,
        ]),
      ),
      child: child,
    );
  }
}

class Themes {
  Themes._();
  static ThemeData get lightTheme => ThemeData();
  static ThemeData get darkTheme => ThemeData();
}

extension CContainerMod on BuildContext {
  Container themeContainer(Widget child) => Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: Theme.of(this).brightness == Brightness.dark
                ? [Theme.of(this).colorScheme.onPrimary, Colors.lightGreen]
                : [Colors.grey, Colors.blueGrey],
          ),
        ),
        child: child,
      );
}
