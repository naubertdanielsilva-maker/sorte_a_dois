import 'api_service.dart';
import 'auth_service.dart';

class RaffleItem {
  final int id;
  final int raffleId;
  final String title;
  final String? description;
  final bool isDrawn;
  final bool isCompleted;

  RaffleItem({
    required this.id,
    required this.raffleId,
    required this.title,
    this.description,
    required this.isDrawn,
    required this.isCompleted,
  });

  factory RaffleItem.fromJson(Map<String, dynamic> json) {
    return RaffleItem(
      id: json['id'],
      raffleId: json['raffle_id'],
      title: json['title'],
      description: json['description'],
      isDrawn: json['is_drawn'] ?? false,
      isCompleted: json['is_completed'] ?? false,
    );
  }
}

class Raffle {
  final int id;
  final int coupleId;
  final String name;
  final String? description;
  final String icon;
  final int totalItems;
  final int availableItems;

  Raffle({
    required this.id,
    required this.coupleId,
    required this.name,
    this.description,
    required this.icon,
    this.totalItems = 0,
    this.availableItems = 0,
  });

  factory Raffle.fromJson(Map<String, dynamic> json) {
    return Raffle(
      id: json['id'],
      coupleId: json['couple_id'],
      name: json['name'],
      description: json['description'],
      icon: json['icon'] ?? '🎲',
    );
  }

  Raffle copyWithCount({
    required int totalItems,
    required int availableItems,
  }) {
    return Raffle(
      id: id,
      coupleId: coupleId,
      name: name,
      description: description,
      icon: icon,
      totalItems: totalItems,
      availableItems: availableItems,
    );
  }
}

class RaffleService {
  static Future<List<Raffle>> getRafflesWithCounts() async {
    final data = await ApiService.get('/raffles/');
    final raffles = (data as List).map((e) => Raffle.fromJson(e)).toList();

    final List<Raffle> result = [];

    for (final raffle in raffles) {
      final items = await getItems(raffle.id);
      final available = items.where((item) => !item.isDrawn).length;

      result.add(
        raffle.copyWithCount(
          totalItems: items.length,
          availableItems: available,
        ),
      );
    }

    return result;
  }

  static Future<List<RaffleItem>> getItems(int raffleId) async {
    final data = await ApiService.get('/items/raffle/$raffleId');
    return (data as List).map((e) => RaffleItem.fromJson(e)).toList();
  }

  static Future<RaffleItem> draw(int raffleId) async {
    final userId = await AuthService.getUserId();

    if (userId == null) {
      throw Exception('Usuário não encontrado. Faça login novamente.');
    }

    final data = await ApiService.post('/draws/$raffleId?user_id=$userId', {});
    return RaffleItem.fromJson(data['sorteado']);
  }

  static Future<Raffle> createRaffle({
    required int coupleId,
    required String name,
    required String description,
  }) async {
    final userId = await AuthService.getUserId();

    if (userId == null) {
      throw Exception('Usuário não encontrado.');
    }

    final data = await ApiService.post('/raffles/', {
      'couple_id': coupleId,
      'name': name,
      'description': description,
      'icon': '🎲',
      'color': '#ff4f8b',
      'allow_repeat': false,
      'created_by_user_id': userId,
    });

    return Raffle.fromJson(data);
  }

  static Future<RaffleItem> createItem({
    required int raffleId,
    required String title,
    required String description,
  }) async {
    final userId = await AuthService.getUserId();

    if (userId == null) {
      throw Exception('Usuário não encontrado.');
    }

    final data = await ApiService.post('/items/', {
      'raffle_id': raffleId,
      'title': title,
      'description': description,
      'is_secret': false,
      'created_by_user_id': userId,
    });

    return RaffleItem.fromJson(data);
  }
}