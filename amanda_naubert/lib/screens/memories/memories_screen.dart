import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../../services/api_service.dart';
import '../../services/memory_service.dart';
import '../../theme/app_theme.dart';
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
    if (mounted) {
      setState(() => isLoading = true);
    }

    try {
      final data = await MemoryService.getMemories();

      if (!mounted) {
        return;
      }

      setState(() => memories = data);
    } catch (error) {
      showMessage(error.toString(), isError: true);
    } finally {
      if (mounted) {
        setState(() => isLoading = false);
      }
    }
  }

  Future<void> openMemoryDialog({
    MemoryItem? memory,
  }) async {
    final isEditing = memory != null;
    final titleController = TextEditingController(
      text: memory?.title ?? '',
    );
    final descriptionController = TextEditingController(
      text: memory?.description ?? '',
    );
    final placeController = TextEditingController(
      text: memory?.placeName ?? '',
    );
    final ratingController = TextEditingController(
      text: (memory?.rating ?? 5).toString(),
    );

    File? selectedPhoto;
    bool saving = false;

    await showDialog<void>(
      context: context,
      barrierDismissible: !saving,
      builder: (dialogContext) => StatefulBuilder(
        builder: (dialogContext, setDialogState) {
          Future<void> pickPhoto() async {
            final picked = await ImagePicker().pickImage(
              source: ImageSource.gallery,
              imageQuality: 75,
              maxWidth: 1600,
            );

            if (picked != null) {
              setDialogState(() {
                selectedPhoto = File(picked.path);
              });
            }
          }

          Widget photoPreview() {
            if (selectedPhoto != null) {
              return Image.file(
                selectedPhoto!,
                height: 170,
                width: double.infinity,
                fit: BoxFit.cover,
              );
            }

            final currentPhoto = fullPhotoUrl(memory?.photoUrl);

            if (currentPhoto.isNotEmpty) {
              return Image.network(
                currentPhoto,
                height: 170,
                width: double.infinity,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) =>
                    const _PhotoPlaceholder(),
              );
            }

            return const _PhotoPlaceholder();
          }

          Future<void> save() async {
            final title = titleController.text.trim();
            final rating =
                int.tryParse(ratingController.text.trim()) ?? 5;

            if (title.isEmpty) {
              showMessage(
                'Informe o título da memória.',
                isError: true,
              );
              return;
            }

            if (rating < 1 || rating > 5) {
              showMessage(
                'A nota deve estar entre 1 e 5.',
                isError: true,
              );
              return;
            }

            setDialogState(() => saving = true);

            try {
              if (isEditing) {
                await MemoryService.updateMemory(
                  memoryId: memory.id,
                  title: title,
                  description:
                      descriptionController.text.trim(),
                  placeName: placeController.text.trim(),
                  rating: rating,
                  currentPhotoUrl: memory.photoUrl,
                  newPhotoFile: selectedPhoto,
                );
              } else {
                await MemoryService.createMemory(
                  title: title,
                  description:
                      descriptionController.text.trim(),
                  placeName: placeController.text.trim(),
                  rating: rating,
                  photoFile: selectedPhoto,
                );
              }

              if (!mounted) {
                return;
              }

              Navigator.of(dialogContext).pop();
              await loadMemories();

              showMessage(
                isEditing
                    ? 'Memória atualizada com sucesso.'
                    : 'Memória salva com sucesso.',
              );
            } catch (error) {
              showMessage(error.toString(), isError: true);
              setDialogState(() => saving = false);
            }
          }

          return AlertDialog(
            title: Text(
              isEditing ? 'Editar memória' : 'Nova memória',
            ),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: photoPreview(),
                  ),
                  const SizedBox(height: 12),
                  OutlinedButton.icon(
                    onPressed: saving ? null : pickPhoto,
                    icon: const Icon(Icons.image_rounded),
                    label: Text(
                      selectedPhoto == null
                          ? 'Escolher foto'
                          : 'Trocar foto',
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: titleController,
                    enabled: !saving,
                    decoration: const InputDecoration(
                      labelText: 'Título',
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: descriptionController,
                    enabled: !saving,
                    maxLines: 3,
                    decoration: const InputDecoration(
                      labelText: 'Descrição',
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: placeController,
                    enabled: !saving,
                    decoration: const InputDecoration(
                      labelText: 'Lugar',
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: ratingController,
                    enabled: !saving,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Nota de 1 a 5',
                    ),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: saving
                    ? null
                    : () => Navigator.of(dialogContext).pop(),
                child: const Text('Cancelar'),
              ),
              FilledButton(
                onPressed: saving ? null : save,
                child: saving
                    ? const SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : Text(isEditing ? 'Salvar alterações' : 'Salvar'),
              ),
            ],
          );
        },
      ),
    );

    titleController.dispose();
    descriptionController.dispose();
    placeController.dispose();
    ratingController.dispose();
  }

  Future<void> confirmDelete(MemoryItem memory) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Excluir memória?'),
        content: Text(
          'A memória "${memory.title}" será removida.',
        ),
        actions: [
          TextButton(
            onPressed: () =>
                Navigator.of(dialogContext).pop(false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: Colors.red,
            ),
            onPressed: () =>
                Navigator.of(dialogContext).pop(true),
            child: const Text('Excluir'),
          ),
        ],
      ),
    );

    if (confirmed != true) {
      return;
    }

    try {
      await MemoryService.deleteMemory(memory.id);
      await loadMemories();
      showMessage('Memória excluída.');
    } catch (error) {
      showMessage(error.toString(), isError: true);
    }
  }

  void showMessage(
    String message, {
    bool isError = false,
  }) {
    if (!mounted) {
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message.replaceAll('Exception: ', ''),
        ),
        backgroundColor:
            isError ? Colors.red : AppTheme.purple,
      ),
    );
  }

  String ratingText(int? rating) {
    final value = rating ?? 0;
    return value > 0 ? 'Nota $value/5' : 'Sem nota';
  }

  String fullPhotoUrl(String? url) {
    if (url == null || url.isEmpty) {
      return '';
    }

    if (url.startsWith('http')) {
      return url;
    }

    return '${ApiService.baseUrl}$url';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => openMemoryDialog(),
        icon: const Icon(Icons.add),
        label: const Text('Memória'),
      ),
      body: SafeArea(
        child: isLoading
            ? const Center(
                child: CircularProgressIndicator(),
              )
            : RefreshIndicator(
                onRefresh: loadMemories,
                child: ListView(
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
                        crossAxisAlignment:
                            CrossAxisAlignment.start,
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
                            style: const TextStyle(
                              color: AppTheme.mutedText,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 18),
                    if (memories.isEmpty)
                      const _EmptyMemoryCard()
                    else
                      ...memories.map(
                        (memory) => _MemoryCard(
                          memory: memory,
                          photoUrl:
                              fullPhotoUrl(memory.photoUrl),
                          ratingText:
                              ratingText(memory.rating),
                          onEdit: () =>
                              openMemoryDialog(memory: memory),
                          onDelete: () =>
                              confirmDelete(memory),
                        ),
                      ),
                    const SizedBox(height: 80),
                  ],
                ),
              ),
      ),
    );
  }
}

class _PhotoPlaceholder extends StatelessWidget {
  const _PhotoPlaceholder();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 170,
      width: double.infinity,
      color: AppTheme.softPurple,
      child: const Center(
        child: Icon(
          Icons.photo_camera_rounded,
          size: 48,
          color: AppTheme.purple,
        ),
      ),
    );
  }
}

class _EmptyMemoryCard extends StatelessWidget {
  const _EmptyMemoryCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
      ),
      child: const Column(
        children: [
          Icon(
            Icons.favorite_border_rounded,
            size: 48,
            color: AppTheme.purple,
          ),
          SizedBox(height: 12),
          Text(
            'Nenhuma memória ainda',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w800,
            ),
          ),
          SizedBox(height: 6),
          Text(
            'Toque em Memória para registrar o primeiro momento.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: AppTheme.mutedText,
            ),
          ),
        ],
      ),
    );
  }
}

class _MemoryCard extends StatelessWidget {
  final MemoryItem memory;
  final String photoUrl;
  final String ratingText;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _MemoryCard({
    required this.memory,
    required this.photoUrl,
    required this.ratingText,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
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
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (photoUrl.isNotEmpty)
            Image.network(
              photoUrl,
              height: 190,
              width: double.infinity,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) =>
                  const _PhotoPlaceholder(),
            ),
          Padding(
            padding: const EdgeInsets.fromLTRB(
              18,
              14,
              8,
              18,
            ),
            child: Row(
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment:
                        CrossAxisAlignment.start,
                    children: [
                      Text(
                        memory.title,
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w900,
                          color: AppTheme.darkText,
                        ),
                      ),
                      if (memory.description != null &&
                          memory.description!.isNotEmpty) ...[
                        const SizedBox(height: 6),
                        Text(
                          memory.description!,
                          style: const TextStyle(
                            color: AppTheme.mutedText,
                          ),
                        ),
                      ],
                      const SizedBox(height: 10),
                      Text(
                        '${memory.placeName?.isNotEmpty == true ? memory.placeName : "Lugar não informado"} • $ratingText',
                        style: const TextStyle(
                          color: AppTheme.purple,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
                PopupMenuButton<String>(
                  onSelected: (value) {
                    if (value == 'edit') {
                      onEdit();
                    } else if (value == 'delete') {
                      onDelete();
                    }
                  },
                  itemBuilder: (_) => const [
                    PopupMenuItem(
                      value: 'edit',
                      child: ListTile(
                        dense: true,
                        leading: Icon(Icons.edit_rounded),
                        title: Text('Editar'),
                      ),
                    ),
                    PopupMenuItem(
                      value: 'delete',
                      child: ListTile(
                        dense: true,
                        leading: Icon(
                          Icons.delete_outline_rounded,
                          color: Colors.red,
                        ),
                        title: Text(
                          'Excluir',
                          style: TextStyle(
                            color: Colors.red,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}