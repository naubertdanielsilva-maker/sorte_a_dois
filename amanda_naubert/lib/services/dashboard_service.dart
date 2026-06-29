import 'api_service.dart';
import 'auth_service.dart';

class DashboardData {
  final String userName;
  final int coupleId;
  final int totalRaffles;
  final int totalIdeas;
  final int totalMemories;
  final int totalPoints;

  DashboardData({
    required this.userName,
    required this.coupleId,
    required this.totalRaffles,
    required this.totalIdeas,
    required this.totalMemories,
    required this.totalPoints,
  });
}

class DashboardService {
  static Future<DashboardData> loadDashboard() async {
    final userName = await AuthService.getName() ?? 'Vocês';

    final couples = await ApiService.get('/couples/');
    final coupleId = couples.isNotEmpty ? couples[0]['id'] : 0;

    if (coupleId == 0) {
      return DashboardData(
        userName: userName,
        coupleId: 0,
        totalRaffles: 0,
        totalIdeas: 0,
        totalMemories: 0,
        totalPoints: 0,
      );
    }

    final stats = await ApiService.get('/stats/couple/$coupleId');
    final memories = await ApiService.get('/memories/couple/$coupleId');
    final points = await ApiService.get('/achievements/points/couple/$coupleId');

    return DashboardData(
      userName: userName,
      coupleId: coupleId,
      totalRaffles: stats['total_raffles'] ?? 0,
      totalIdeas: stats['total_items'] ?? 0,
      totalMemories: memories.length ?? 0,
      totalPoints: points['total_points'] ?? 0,
    );
  }
}