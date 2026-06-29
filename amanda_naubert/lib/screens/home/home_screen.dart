import 'package:flutter/material.dart';

import '../../services/dashboard_service.dart';
import '../../theme/app_theme.dart';
import '../../widgets/info_tile.dart';
import '../../widgets/premium_card.dart';
import '../../widgets/stats_grid.dart';

class HomeScreen extends StatelessWidget {
  final VoidCallback onDrawPressed;

  const HomeScreen({
    super.key,
    required this.onDrawPressed,
  });

  Future<void> refresh(BuildContext context) async {
    await DashboardService.loadDashboard();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      body: SafeArea(
        child: FutureBuilder<DashboardData>(
          future: DashboardService.loadDashboard(),
          builder: (context, snapshot) {
            if (!snapshot.hasData) {
              return const Center(child: CircularProgressIndicator());
            }

            final data = snapshot.data!;

            return ListView(
              padding: const EdgeInsets.all(20),
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Bem-vindos',
                            style: TextStyle(
                              color: AppTheme.purple,
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Olá, ${data.userName}',
                            style: const TextStyle(
                              color: AppTheme.darkText,
                              fontSize: 32,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      width: 54,
                      height: 54,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(50),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.10),
                            blurRadius: 18,
                            offset: const Offset(0, 8),
                          ),
                        ],
                      ),
                      child: const Center(
                        child: Text('❤️', style: TextStyle(fontSize: 28)),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 22),
                PremiumCard(
                  gradient: const [
                    Color(0xFFFF4F8B),
                    Color(0xFF7B2FF7),
                  ],
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'O que vamos viver hoje?',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 27,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Escolha uma experiência, registre uma memória ou veja as conquistas de vocês.',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 15,
                          height: 1.35,
                        ),
                      ),
                      const SizedBox(height: 20),
                      FilledButton(
                        style: FilledButton.styleFrom(
                          backgroundColor: Colors.white,
                          foregroundColor: AppTheme.purple,
                        ),
                        onPressed: onDrawPressed,
                        child: const Text('🎲 Sortear agora'),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 18),
                StatsGrid(
                  raffles: data.totalRaffles.toString(),
                  ideas: data.totalIdeas.toString(),
                  memories: data.totalMemories.toString(),
                  points: data.totalPoints.toString(),
                ),
                const SizedBox(height: 18),
                const InfoTile(
                  icon: '🔥',
                  title: 'Sequência',
                  subtitle: 'Em breve: streak de aventuras do casal',
                ),
                const InfoTile(
                  icon: '🪙',
                  title: 'Moedas',
                  subtitle: 'Pontuação real do casal já aparece acima',
                ),
                const InfoTile(
                  icon: '📅',
                  title: 'Próximo encontro',
                  subtitle: 'Calendário entra na próxima etapa',
                ),
                const InfoTile(
                  icon: '📸',
                  title: 'Memórias',
                  subtitle: 'Veja quantas memórias vocês já salvaram',
                ),
                const InfoTile(
                  icon: '🏆',
                  title: 'Conquistas',
                  subtitle: 'Acompanhe a evolução de vocês',
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}