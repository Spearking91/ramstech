import 'package:flutter/material.dart';
import 'package:ramstech/data/notifiers.dart';

class NavBar extends StatelessWidget {
  const NavBar({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder(
      valueListenable: pageNotifier,
      builder: (context, page, child) {
        return NavigationBar(
            destinations: const [
              NavigationDestination(
                icon: Icon(Icons.home),
                label: 'Home',
              ),
              NavigationDestination(
                icon: Icon(Icons.add_chart_sharp),
                label: 'Charts',
              ),
              NavigationDestination(
                icon: Icon(Icons.devices),
                label: 'Devices',
              ),
              NavigationDestination(
                icon: Icon(Icons.person),
                label: 'Profile',
              ),
            ],
            selectedIndex: page,
            onDestinationSelected: (index) {
              pageNotifier.value = index;
            });
      },
    );
  }
}
