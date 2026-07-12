import 'api_service.dart';
import 'auth_service.dart';

class RaffleItem {
  final int id;
  final int raffleId;
  final String title;
  final String? description;
  final bool isDrawn;
  final bool isCompleted;

  const RaffleItem({
    required this.id,
    required this.raffleId,
    required this.title,
    this.description,
    required this.isDrawn,
    required this.isCompleted,
  });

  factory RaffleItem.fromJson(Map<String, dynamic> json) {
    return RaffleItem(
      id: json['id'] as int,
      raffleId: json['raffle_id'] as int,
      title: json['title'] as String,
      description: json['description'] as String?,
      isDrawn: json['is_drawn'] as bool? ?? false,
      isCompleted: json['is_completed'] as bool? ?? false,
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

  const Raffle({
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
      id: json['id'] as int,
      coupleId: json['couple_id'] as int,
      name: json['name'] as String,
      description: json['description'] as String?,
      icon: json['icon'] as String? ?? 'ðŸŽ²',
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
    final raffles = (data as List)
        .map(
          (item) => Raffle.fromJson(
            Map<String, dynamic>.from(item as Map),
          ),
        )
        .toList();

    final result = <Raffle>[];

    for (final raffle in raffles) {
      final items = await getItems(raffle.id);
      final available =
          items.where((item) => !item.isDrawn).length;

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

    return (data as List)
        .map(
          (item) => RaffleItem.fromJson(
            Map<String, dynamic>.from(item as Map),
          ),
        )
        .toList();
  }

  static Future<RaffleItem> draw(int raffleId) async {
    final userId = await AuthService.getUserId();

    if (userId == null) {
      throw Exception(
        'Usuário não encontrado. Faça login novamente.',
      );
    }

    final data = await ApiService.post(
      '/draws/$raffleId?user_id=$userId',
      {},
    );

    return RaffleItem.fromJson(
      Map<String, dynamic>.from(data['sorteado'] as Map),
    );
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
      'icon': 'ðŸŽ²',
      'color': '#ff4f8b',
      'allow_repeat': false,
      'created_by_user_id': userId,
    });

    return Raffle.fromJson(
      Map<String, dynamic>.from(data as Map),
    );
  }

  static Future<Raffle> updateRaffle({
    required int raffleId,
    required String name,
    required String description,
  }) async {
    final data = await ApiService.patch(
      '/raffles/$raffleId',
      {
        'name': name,
        'description': description,
      },
    );

    return Raffle.fromJson(
      Map<String, dynamic>.from(data as Map),
    );
  }

  static Future<void> deleteRaffle(int raffleId) async {
    await ApiService.delete('/raffles/$raffleId');
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

    return RaffleItem.fromJson(
      Map<String, dynamic>.from(data as Map),
    );
  }

  static Future<RaffleItem> updateItem({
    required int itemId,
    required String title,
    required String description,
  }) async {
    final data = await ApiService.patch(
      '/items/$itemId',
      {
        'title': title,
        'description': description,
      },
    );

    return RaffleItem.fromJson(
      Map<String, dynamic>.from(data as Map),
    );
  }

  static Future<void> deleteItem(int itemId) async {
    await ApiService.delete('/items/$itemId');
  }
}