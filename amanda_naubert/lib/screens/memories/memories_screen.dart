import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../../services/memory_service.dart';
import '../../theme/app_theme.dart';
import '../../widgets/info_tile.dart';
import '../../widgets/premium_card.dart';

class MemoriesScreen extends StatefulWidget {
  const MemoriesScreen({super.key});

  @override
  State<MemoriesScreen> createState() => _MemoriesScreenState();
}

class _MemoriesScreenState extends State<MemoriesScreen> {
  bool isLoading = true;
  List<MemoryItem> memories = [];

  @override
  void initState() {
    super.initState();
    loadMemories();
  }

  Future<void> loadMemories() async {
    setState(() => isLoading = true);

    try {
      final data = await MemoryService.getMemories();
      setState(() => memories = data);
    } catch (error) {
      showMessage(error.toString());
    } finally {
      setState(() => isLoading = false);
    }
  }

  Future<void> openCreateMemoryDialog() async {
    final titleController = TextEditingController();
    final descriptionController = TextEditingController();
    final placeController = TextEditingController();
    final ratingController = TextEditingController(text: '5');

    File? selectedPhoto;

    await showDialog(
      context: context,
      builder: (_) => StatefulBuilder(
        builder: (context, setDialogState) {
          Future<void> pickPhoto() async {
            final picker = ImagePicker();
            final picked = await picker.pickImage(
              source: ImageSource.gallery,
              imageQuality: 75,
            );

            if (picked != null) {
              setDialogState(() {
                selectedPhoto = File(picked.path);
              });
            }
          }

          return AlertDialog(
            title: const Text('Nova memória'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (selectedPhoto != null)
                    ClipRRect(
                      borderRadius: BorderRadius.circular(16),
                      child: Image.file(
                        selectedPhoto!,
                        height: 150,
                        width: double.infinity,
                        fit: BoxFit.cover,
                      ),
                    )
                  else
                    Container(
                      height: 130,
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: AppTheme.softPurple,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: const Center(
                        child: Icon(
                          Icons.photo_camera_rounded,
                          size: 42,
                          color: AppTheme.purple,
                        ),
                      ),
                    ),
                  const SizedBox(height: 12),
                  OutlinedButton.icon(
                    onPressed: pickPhoto,
                    icon: const Icon(Icons.image_rounded),
                    label: const Text('Escolher foto'),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: titleController,
                    decoration: const InputDecoration(labelText: 'Título'),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: descriptionController,
                    decoration: const InputDecoration(labelText: 'Descrição'),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: placeController,
                    decoration: const InputDecoration(labelText: 'Lugar'),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: ratingController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(labelText: 'Nota de 1 a 5'),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancelar'),
              ),
              FilledButton(
                onPressed: () async {
                  try {
                    await MemoryService.createMemory(
                      title: titleController.text.trim(),
                      description: descriptionController.text.trim(),
                      placeName: placeController.text.trim(),
                      rating: int.tryParse(ratingController.text.trim()) ?? 5,
                      photoFile: selectedPhoto,
                    );

                    if (!mounted) return;

                    Navigator.pop(context);
                    await loadMemories();

                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Memória salva com sucesso')),
                    );
                  } catch (error) {
                    showMessage(error.toString());
                  }
                },
                child: const Text('Salvar'),
              ),
            ],
          );
        },
      ),
    );
  }

  void showMessage(String message) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message.replaceAll('Exception: ', '')),
        backgroundColor: Colors.red,
      ),
    );
  }

  String ratingText(int? rating) {
    final value = rating ?? 0;
    return value > 0 ? 'Nota $value/5' : 'Sem nota';
  }

  String fullPhotoUrl(String? url) {
    if (url == null || url.isEmpty) return '';
    if (url.startsWith('http')) return url;
    return 'http://10.0.2.2:8000$url';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      floatingActionButton: FloatingActionButton.extended(
        onPressed: openCreateMemoryDialog,
        icon: const Icon(Icons.add),
        label: const Text('Memória'),
      ),
      body: SafeArea(
        child: isLoading
            ? const Center(child: CircularProgressIndicator())
            : ListView(
                padding: const EdgeInsets.all(20),
                children: [
                  const Text(
                    'LINHA DO TEMPO',
                    style: TextStyle(
                      color: AppTheme.purple,
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                    ),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'Memórias',
                    style: TextStyle(
                      color: AppTheme.darkText,
                      fontSize: 34,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 22),
                  PremiumCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(
                          Icons.photo_camera_rounded,
                          size: 54,
                          color: AppTheme.purple,
                        ),
                        const SizedBox(height: 12),
                        const Text(
                          'Guarde os melhores momentos',
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          memories.isEmpty
                              ? 'Nenhuma memória ainda.'
                              : '${memories.length} memória(s) salva(s).',
                          style: const TextStyle(color: AppTheme.mutedText),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 18),
                  if (memories.isEmpty)
                    const InfoTile(
                      icon: '♡',
                      title: 'Nenhuma memória ainda',
                      subtitle: 'Toque em Memória para registrar a primeira.',
                    )
                  else
                    ...memories.map(
                      (memory) {
                        final photo = fullPhotoUrl(memory.photoUrl);

                        return Container(
                          margin: const EdgeInsets.only(bottom: 14),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(24),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.08),
                                blurRadius: 18,
                                offset: const Offset(0, 8),
                              ),
                            ],
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              if (photo.isNotEmpty)
                                ClipRRect(
                                  borderRadius: const BorderRadius.vertical(
                                    top: Radius.circular(24),
                                  ),
                                  child: Image.network(
                                    photo,
                                    height: 190,
                                    width: double.infinity,
                                    fit: BoxFit.cover,
                                    errorBuilder: (_, __, ___) => Container(
                                      height: 150,
                                      color: AppTheme.softPurple,
                                      child: const Center(
                                        child: Icon(Icons.broken_image_rounded),
                                      ),
                                    ),
                                  ),
                                ),
                              Padding(
                                padding: const EdgeInsets.all(18),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      memory.title,
                                      style: const TextStyle(
                                        fontSize: 20,
                                        fontWeight: FontWeight.w900,
                                        color: AppTheme.darkText,
                                      ),
                                    ),
                                    const SizedBox(height: 6),
                                    if (memory.description != null &&
                                        memory.description!.isNotEmpty)
                                      Text(
                                        memory.description!,
                                        style: const TextStyle(
                                          color: AppTheme.mutedText,
                                        ),
                                      ),
                                    const SizedBox(height: 10),
                                    Text(
                                      '${memory.placeName ?? "Lugar não informado"} • ${ratingText(memory.rating)}',
                                      style: const TextStyle(
                                        color: AppTheme.purple,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                ],
              ),
      ),
    );
  }
}