import 'package:flutter/material.dart';
import 'package:ramstech/data/nav_bar.dart';
import 'package:ramstech/data/notifiers.dart';

import 'package:ramstech/pages/devices_page.dart';
import 'package:ramstech/pages/home_page.dart';
import 'package:ramstech/pages/profile_page.dart';

class WidgetTree extends StatefulWidget {
  const WidgetTree({super.key});

  @override
  State<WidgetTree> createState() => _WidgetTreeState();
}

class _WidgetTreeState extends State<WidgetTree> {
  final List<Widget> _pages = [
    const HomePage(),
    const DevicesPage(),
    const ProfilePage()
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: ValueListenableBuilder<int>(
        valueListenable: pageNotifier,
        builder: (context, currentPage, child) {
          return _pages[currentPage];
        },
      ),
      bottomNavigationBar: const NavBar(),
    );
  }
}
