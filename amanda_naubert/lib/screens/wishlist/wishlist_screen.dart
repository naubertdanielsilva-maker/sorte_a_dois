import 'package:flutter/material.dart';

import '../../theme/app_theme.dart';
import '../../widgets/info_tile.dart';

class WishlistScreen extends StatelessWidget {
  const WishlistScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      body: SafeArea(
        child: ListView(
          padding: EdgeInsets.all(20),
          children: [
            Text('SONHOS E PLANOS', style: TextStyle(color: AppTheme.purple, fontWeight: FontWeight.bold, fontSize: 13)),
            SizedBox(height: 4),
            Text('Desejos', style: TextStyle(color: AppTheme.darkText, fontSize: 34, fontWeight: FontWeight.w900)),
            SizedBox(height: 22),
            InfoTile(icon: '🎁', title: 'Presentes', subtitle: 'Ideias de presentes e surpresas.'),
            InfoTile(icon: '✈️', title: 'Viagens', subtitle: 'Lugares que vocês querem conhecer.'),
            InfoTile(icon: '🍝', title: 'Comidas', subtitle: 'Restaurantes, cafés e experiências gastronômicas.'),
            InfoTile(icon: '🎬', title: 'Filmes e programas', subtitle: 'Coisas para assistir ou fazer juntos.'),
          ],
        ),
      ),
    );
  }
}