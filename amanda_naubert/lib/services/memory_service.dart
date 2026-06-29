import 'dart:io';

import 'api_service.dart';
import 'auth_service.dart';
import 'dashboard_service.dart';

class MemoryItem {
  final int id;
  final String title;
  final String? description;
  final String? photoUrl;
  final String? placeName;
  final int? rating;

  MemoryItem({
    required this.id,
    required this.title,
    this.description,
    this.photoUrl,
    this.placeName,
    this.rating,
  });

  factory MemoryItem.fromJson(Map<String, dynamic> json) {
    return MemoryItem(
      id: json['id'],
      title: json['title'],
      description: json['description'],
      photoUrl: json['photo_url'],
      placeName: json['place_name'],
      rating: json['rating'],
    );
  }
}

class MemoryService {
  static Future<List<MemoryItem>> getMemories() async {
    final dashboard = await DashboardService.loadDashboard();

    if (dashboard.coupleId == 0) return [];

    final data = await ApiService.get('/memories/couple/${dashboard.coupleId}');

    return (data as List).map((e) => MemoryItem.fromJson(e)).toList();
  }

  static Future<String?> uploadMemoryPhoto(File? file) async {
    if (file == null) return null;

    final data = await ApiService.uploadPhoto('/uploads/photo', file);
    return data['url'];
  }

  static Future<void> createMemory({
    required String title,
    required String description,
    required String placeName,
    required int rating,
    File? photoFile,
  }) async {
    final dashboard = await DashboardService.loadDashboard();
    final userId = await AuthService.getUserId();

    if (userId == null) {
      throw Exception('Usuário não encontrado.');
    }

    final photoUrl = await uploadMemoryPhoto(photoFile);

    await ApiService.post('/memories/', {
      'couple_id': dashboard.coupleId,
      'title': title,
      'description': description,
      'photo_url': photoUrl,
      'place_name': placeName,
      'latitude': null,
      'longitude': null,
      'rating': rating,
      'created_by_user_id': userId,
    });
  }
}