import 'package:flutter/material.dart';

import 'draw/draw_screen.dart';
import 'home/home_screen.dart';
import 'memories/memories_screen.dart';
import 'profile/profile_screen.dart';
import 'wishlist/wishlist_screen.dart';

class MainShell extends StatefulWidget {
  const MainShell({super.key});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int selectedIndex = 0;

  void goToTab(int index) {
    setState(() => selectedIndex = index);
  }

  @override
  Widget build(BuildContext context) {
    final screens = [
      HomeScreen(onDrawPressed: () => goToTab(1)),
      const DrawScreen(),
      const MemoriesScreen(),
      const WishlistScreen(),
      const ProfileScreen(),
    ];

    return Scaffold(
      body: screens[selectedIndex],
      bottomNavigationBar: NavigationBar(
        selectedIndex: selectedIndex,
        onDestinationSelected: goToTab,
        destinations: const [
          NavigationDestination(icon: Icon(Icons.home_rounded), label: 'Início'),
          NavigationDestination(icon: Icon(Icons.casino_rounded), label: 'Sortear'),
          NavigationDestination(icon: Icon(Icons.photo_camera_rounded), label: 'Memórias'),
          NavigationDestination(icon: Icon(Icons.card_giftcard_rounded), label: 'Desejos'),
          NavigationDestination(icon: Icon(Icons.favorite_rounded), label: 'Perfil'),
        ],
      ),
    );
  }
}