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

  const MemoryItem({
    required this.id,
    required this.title,
    this.description,
    this.photoUrl,
    this.placeName,
    this.rating,
  });

  factory MemoryItem.fromJson(Map<String, dynamic> json) {
    return MemoryItem(
      id: json['id'] as int,
      title: json['title'] as String,
      description: json['description'] as String?,
      photoUrl: json['photo_url'] as String?,
      placeName: json['place_name'] as String?,
      rating: json['rating'] as int?,
    );
  }
}

class MemoryService {
  static Future<List<MemoryItem>> getMemories() async {
    final dashboard = await DashboardService.loadDashboard();

    if (dashboard.coupleId == 0) {
      return [];
    }

    final data = await ApiService.get(
      '/memories/couple/${dashboard.coupleId}',
    );

    return (data as List)
        .map(
          (item) => MemoryItem.fromJson(
            Map<String, dynamic>.from(item as Map),
          ),
        )
        .toList();
  }

  static Future<String?> uploadMemoryPhoto(File? file) async {
    if (file == null) {
      return null;
    }

    final data = await ApiService.uploadPhoto(
      '/api/uploads/photo',
      file,
    );

    return data['url'] as String?;
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

  static Future<void> updateMemory({
    required int memoryId,
    required String title,
    required String description,
    required String placeName,
    required int rating,
    required String? currentPhotoUrl,
    File? newPhotoFile,
  }) async {
    final photoUrl = newPhotoFile == null
        ? currentPhotoUrl
        : await uploadMemoryPhoto(newPhotoFile);

    await ApiService.patch('/memories/$memoryId', {
      'title': title,
      'description': description,
      'photo_url': photoUrl,
      'place_name': placeName,
      'rating': rating,
    });
  }

  static Future<void> deleteMemory(int memoryId) async {
    await ApiService.delete('/memories/$memoryId');
  }
}