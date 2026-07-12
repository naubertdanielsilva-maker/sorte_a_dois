import 'api_service.dart';
import 'auth_service.dart';
import 'dashboard_service.dart';

class WishItem {
  final int id;
  final int coupleId;
  final String title;
  final String? description;
  final String? category;
  final int createdByUserId;

  WishItem({
    required this.id,
    required this.coupleId,
    required this.title,
    this.description,
    this.category,
    required this.createdByUserId,
  });

  factory WishItem.fromJson(Map<String, dynamic> json) {
    return WishItem(
      id: json['id'],
      coupleId: json['couple_id'],
      title: json['title'],
      description: json['description'],
      category: json['category'],
      createdByUserId: json['created_by_user_id'],
    );
  }
}

class WishService {
  static Future<List<WishItem>> getWishes() async {
    final dashboard = await DashboardService.loadDashboard();

    if (dashboard.coupleId == 0) return [];

    final data = await ApiService.get('/wishes/couple/${dashboard.coupleId}');

    return (data as List).map((e) => WishItem.fromJson(e)).toList();
  }

  static Future<void> createWish({
    required String title,
    required String description,
    required String category,
  }) async {
    final dashboard = await DashboardService.loadDashboard();
if (dashboard.coupleId == 0) {
  throw Exception('Nenhum casal encontrado para este usuário.');
}
    final userId = await AuthService.getUserId();

    if (userId == null) {
      throw Exception('Usuário não encontrado.');
    }

    await ApiService.post('/wishes/', {
      'couple_id': dashboard.coupleId,
      'title': title,
      'description': description,
      'category': category,
      'created_by_user_id': userId,
    });
  }

  static Future<void> deleteWish(int wishId) async {
    await ApiService.delete('/wishes/$wishId');
  }
}