import 'package:flutter/material.dart';

import '../../services/auth_service.dart';
import '../../services/dashboard_service.dart';
import '../../theme/app_theme.dart';
import '../../widgets/info_tile.dart';
import '../../widgets/stats_grid.dart';
import '../login/login_screen.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  Future<void> logout(BuildContext context) async {
    await AuthService.logout();

    if (!context.mounted) return;

    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const LoginScreen()),
      (_) => false,
    );
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
                const Text(
                  'PERFIL',
                  style: TextStyle(
                    color: AppTheme.purple,
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 4),
                const Text(
                  'Vocês dois',
                  style: TextStyle(
                    color: AppTheme.darkText,
                    fontSize: 34,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 22),

                StatsGrid(
                  raffles: data.totalRaffles.toString(),
                  ideas: data.totalIdeas.toString(),
                  memories: data.totalMemories.toString(),
                  points: data.totalPoints.toString(),
                ),

                const SizedBox(height: 18),

                InfoTile(
                  icon: '♡',
                  title: 'Amanda & Naubert',
                  subtitle:
                      '${data.totalRaffles} sorteios • ${data.totalMemories} memórias • ${data.totalPoints} pontos',
                ),

                InfoTile(
                  icon: '◎',
                  title: 'Usuário logado',
                  subtitle: data.userName,
                ),

                const InfoTile(
                  icon: '✓',
                  title: 'Status da V1',
                  subtitle: 'Login, sorteios e memórias funcionando',
                ),

                const SizedBox(height: 18),

                FilledButton(
                  style: FilledButton.styleFrom(
                    backgroundColor: Colors.red,
                  ),
                  onPressed: () => logout(context),
                  child: const Text('Sair da conta'),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}