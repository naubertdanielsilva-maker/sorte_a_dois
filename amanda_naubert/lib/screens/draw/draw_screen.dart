import 'package:flutter/material.dart';

import '../../services/dashboard_service.dart';
import '../../services/raffle_service.dart';
import '../../theme/app_theme.dart';
import '../../widgets/premium_card.dart';

class DrawScreen extends StatefulWidget {
  const DrawScreen({super.key});

  @override
  State<DrawScreen> createState() => _DrawScreenState();
}

class _DrawScreenState extends State<DrawScreen> {
  bool isLoading = true;
  bool isDrawing = false;

  List<Raffle> raffles = [];
  Raffle? selectedRaffle;
  List<RaffleItem> items = [];

  @override
  void initState() {
    super.initState();
    loadRaffles();
  }

  Future<void> loadRaffles({
    int? selectedId,
  }) async {
    if (mounted) {
      setState(() => isLoading = true);
    }

    try {
      final previousId =
          selectedId ?? selectedRaffle?.id;
      final data =
          await RaffleService.getRafflesWithCounts();

      Raffle? nextSelected;

      if (data.isNotEmpty) {
        for (final raffle in data) {
          if (raffle.id == previousId) {
            nextSelected = raffle;
            break;
          }
        }

        nextSelected ??= data.first;
      }

      final loadedItems = nextSelected == null
          ? <RaffleItem>[]
          : await RaffleService.getItems(
              nextSelected.id,
            );

      if (!mounted) {
        return;
      }

      setState(() {
        raffles = data;
        selectedRaffle = nextSelected;
        items = loadedItems;
      });
    } catch (error) {
      showMessage(error.toString(), isError: true);
    } finally {
      if (mounted) {
        setState(() => isLoading = false);
      }
    }
  }

  Future<void> selectRaffle(Raffle raffle) async {
    try {
      final loadedItems =
          await RaffleService.getItems(raffle.id);

      if (!mounted) {
        return;
      }

      setState(() {
        selectedRaffle = raffle;
        items = loadedItems;
      });
    } catch (error) {
      showMessage(error.toString(), isError: true);
    }
  }

  Future<void> handleDraw() async {
    final raffle = selectedRaffle;

    if (raffle == null) {
      return;
    }

    setState(() => isDrawing = true);

    try {
      await Future.delayed(
        const Duration(milliseconds: 650),
      );

      final item =
          await RaffleService.draw(raffle.id);

      await loadRaffles(selectedId: raffle.id);

      if (!mounted) {
        return;
      }

      await showDialog<void>(
        context: context,
        builder: (dialogContext) => AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
          title: const Row(
            children: [
              Icon(
                Icons.celebration_rounded,
                color: AppTheme.purple,
              ),
              SizedBox(width: 10),
              Text('Sorteado!'),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                item.title,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.w900,
                  color: AppTheme.purple,
                ),
              ),
              if (item.description != null &&
                  item.description!.isNotEmpty) ...[
                const SizedBox(height: 12),
                Text(
                  item.description!,
                  textAlign: TextAlign.center,
                ),
              ],
            ],
          ),
          actions: [
            TextButton(
              onPressed: () =>
                  Navigator.of(dialogContext).pop(),
              child: const Text('Fechar'),
            ),
          ],
        ),
      );
    } catch (error) {
      showMessage(error.toString(), isError: true);
    } finally {
      if (mounted) {
        setState(() => isDrawing = false);
      }
    }
  }

  Future<void> openRaffleDialog({
    Raffle? raffle,
  }) async {
    final isEditing = raffle != null;
    final nameController = TextEditingController(
      text: raffle?.name ?? '',
    );
    final descriptionController = TextEditingController(
      text: raffle?.description ?? '',
    );
    bool saving = false;

    await showDialog<void>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (dialogContext, setDialogState) {
          Future<void> save() async {
            final name = nameController.text.trim();

            if (name.isEmpty) {
              showMessage(
                'Informe o nome do sorteio.',
                isError: true,
              );
              return;
            }

            setDialogState(() => saving = true);

            try {
              int selectedId;

              if (isEditing) {
                final updated =
                    await RaffleService.updateRaffle(
                  raffleId: raffle.id,
                  name: name,
                  description:
                      descriptionController.text.trim(),
                );
                selectedId = updated.id;
              } else {
                final dashboard =
                    await DashboardService.loadDashboard();

                final created =
                    await RaffleService.createRaffle(
                  coupleId: dashboard.coupleId,
                  name: name,
                  description:
                      descriptionController.text.trim(),
                );
                selectedId = created.id;
              }

              if (!mounted) {
                return;
              }

              Navigator.of(dialogContext).pop();
              await loadRaffles(selectedId: selectedId);

              showMessage(
                isEditing
                    ? 'Sorteio atualizado.'
                    : 'Sorteio criado.',
              );
            } catch (error) {
              showMessage(
                error.toString(),
                isError: true,
              );
              setDialogState(() => saving = false);
            }
          }

          return AlertDialog(
            title: Text(
              isEditing
                  ? 'Editar sorteio'
                  : 'Novo sorteio',
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameController,
                  enabled: !saving,
                  decoration: const InputDecoration(
                    labelText: 'Nome',
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
              ],
            ),
            actions: [
              TextButton(
                onPressed: saving
                    ? null
                    : () =>
                        Navigator.of(dialogContext).pop(),
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
                    : Text(
                        isEditing
                            ? 'Salvar alterações'
                            : 'Criar',
                      ),
              ),
            ],
          );
        },
      ),
    );

    nameController.dispose();
    descriptionController.dispose();
  }

  Future<void> openItemDialog({
    RaffleItem? item,
  }) async {
    final raffle = selectedRaffle;

    if (raffle == null) {
      return;
    }

    final isEditing = item != null;
    final titleController = TextEditingController(
      text: item?.title ?? '',
    );
    final descriptionController = TextEditingController(
      text: item?.description ?? '',
    );
    bool saving = false;

    await showDialog<void>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (dialogContext, setDialogState) {
          Future<void> save() async {
            final title = titleController.text.trim();

            if (title.isEmpty) {
              showMessage(
                'Informe a ideia.',
                isError: true,
              );
              return;
            }

            setDialogState(() => saving = true);

            try {
              if (isEditing) {
                await RaffleService.updateItem(
                  itemId: item.id,
                  title: title,
                  description:
                      descriptionController.text.trim(),
                );
              } else {
                await RaffleService.createItem(
                  raffleId: raffle.id,
                  title: title,
                  description:
                      descriptionController.text.trim(),
                );
              }

              if (!mounted) {
                return;
              }

              Navigator.of(dialogContext).pop();
              await loadRaffles(selectedId: raffle.id);

              showMessage(
                isEditing
                    ? 'Ideia atualizada.'
                    : 'Ideia adicionada.',
              );
            } catch (error) {
              showMessage(
                error.toString(),
                isError: true,
              );
              setDialogState(() => saving = false);
            }
          }

          return AlertDialog(
            title: Text(
              isEditing
                  ? 'Editar ideia'
                  : 'Nova ideia em ${raffle.name}',
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: titleController,
                  enabled: !saving,
                  decoration: const InputDecoration(
                    labelText: 'Ideia',
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
              ],
            ),
            actions: [
              TextButton(
                onPressed: saving
                    ? null
                    : () =>
                        Navigator.of(dialogContext).pop(),
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
                    : Text(
                        isEditing
                            ? 'Salvar alterações'
                            : 'Adicionar',
                      ),
              ),
            ],
          );
        },
      ),
    );

    titleController.dispose();
    descriptionController.dispose();
  }

  Future<void> confirmDeleteRaffle(
    Raffle raffle,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Excluir sorteio?'),
        content: Text(
          'O sorteio "${raffle.name}" e todas as ideias dele serão excluídos.',
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
      await RaffleService.deleteRaffle(raffle.id);
      await loadRaffles();
      showMessage('Sorteio excluído.');
    } catch (error) {
      showMessage(error.toString(), isError: true);
    }
  }

  Future<void> confirmDeleteItem(
    RaffleItem item,
  ) async {
    final raffle = selectedRaffle;

    if (raffle == null) {
      return;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Excluir ideia?'),
        content: Text(
          'A ideia "${item.title}" será excluída.',
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
      await RaffleService.deleteItem(item.id);
      await loadRaffles(selectedId: raffle.id);
      showMessage('Ideia excluída.');
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

  @override
  Widget build(BuildContext context) {
    final selected = selectedRaffle;

    return Scaffold(
      backgroundColor: AppTheme.background,
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => openRaffleDialog(),
        icon: const Icon(Icons.add),
        label: const Text('Sorteio'),
      ),
      body: SafeArea(
        child: isLoading
            ? const Center(
                child: CircularProgressIndicator(),
              )
            : RefreshIndicator(
                onRefresh: loadRaffles,
                child: ListView(
                  padding: const EdgeInsets.all(20),
                  children: [
                    const Text(
                      'MOMENTO SURPRESA',
                      style: TextStyle(
                        color: AppTheme.purple,
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                      ),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'Sortear',
                      style: TextStyle(
                        color: AppTheme.darkText,
                        fontSize: 34,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 22),
                    if (selected == null)
                      PremiumCard(
                        child: Column(
                          children: [
                            const Icon(
                              Icons.casino_rounded,
                              size: 70,
                              color: AppTheme.purple,
                            ),
                            const SizedBox(height: 12),
                            const Text(
                              'Nenhum sorteio criado ainda',
                              style: TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            const SizedBox(height: 8),
                            const Text(
                              'Crie o primeiro sorteio para começar.',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: AppTheme.mutedText,
                              ),
                            ),
                            const SizedBox(height: 18),
                            FilledButton(
                              onPressed: () =>
                                  openRaffleDialog(),
                              child: const Text(
                                'Criar sorteio',
                              ),
                            ),
                          ],
                        ),
                      )
                    else ...[
                      PremiumCard(
                        child: Column(
                          children: [
                            AnimatedContainer(
                              duration:
                                  const Duration(milliseconds: 300),
                              width: 150,
                              height: 205,
                              decoration: BoxDecoration(
                                gradient:
                                    const LinearGradient(
                                  colors: [
                                    Color(0xFF7B2FF7),
                                    Color(0xFFFF4F8B),
                                  ],
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                ),
                                borderRadius:
                                    BorderRadius.circular(26),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black
                                        .withValues(alpha: 0.18),
                                    blurRadius: 24,
                                    offset:
                                        const Offset(0, 12),
                                  ),
                                ],
                              ),
                              child: Center(
                                child: Icon(
                                  isDrawing
                                      ? Icons.style_rounded
                                      : Icons.casino_rounded,
                                  size: 78,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                            const SizedBox(height: 18),
                            Text(
                              selected.name,
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                color: AppTheme.darkText,
                                fontWeight: FontWeight.w900,
                                fontSize: 24,
                              ),
                            ),
                            if (selected.description != null &&
                                selected
                                    .description!.isNotEmpty) ...[
                              const SizedBox(height: 8),
                              Text(
                                selected.description!,
                                textAlign: TextAlign.center,
                                style: const TextStyle(
                                  color: AppTheme.mutedText,
                                  fontSize: 15,
                                ),
                              ),
                            ],
                            const SizedBox(height: 20),
                            FilledButton.icon(
                              onPressed: isDrawing ||
                                      selected.availableItems == 0
                                  ? null
                                  : handleDraw,
                              icon: const Icon(
                                Icons.casino_rounded,
                              ),
                              label: Text(
                                isDrawing
                                    ? 'Sorteando...'
                                    : 'Sortear agora',
                              ),
                            ),
                            const SizedBox(height: 10),
                            TextButton.icon(
                              onPressed: () =>
                                  openItemDialog(),
                              icon: const Icon(
                                Icons.add_rounded,
                              ),
                              label: const Text(
                                'Adicionar ideia nesta categoria',
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 18),
                      const Text(
                        'Categorias',
                        style: TextStyle(
                          color: AppTheme.darkText,
                          fontSize: 22,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 12),
                      ...raffles.map(
                        (raffle) => _RaffleCard(
                          raffle: raffle,
                          selected:
                              raffle.id == selected.id,
                          onTap: () =>
                              selectRaffle(raffle),
                          onEdit: () =>
                              openRaffleDialog(
                            raffle: raffle,
                          ),
                          onDelete: () =>
                              confirmDeleteRaffle(raffle),
                        ),
                      ),
                      const SizedBox(height: 18),
                      Row(
                        children: [
                          const Expanded(
                            child: Text(
                              'Itens desta categoria',
                              style: TextStyle(
                                color: AppTheme.darkText,
                                fontSize: 22,
                                fontWeight:
                                    FontWeight.w800,
                              ),
                            ),
                          ),
                          IconButton(
                            tooltip: 'Adicionar ideia',
                            onPressed: () =>
                                openItemDialog(),
                            icon: const Icon(
                              Icons.add_circle_outline_rounded,
                              color: AppTheme.purple,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      if (items.isEmpty)
                        const _EmptyItemCard()
                      else
                        ...items.map(
                          (item) => _ItemCard(
                            item: item,
                            onEdit: () =>
                                openItemDialog(item: item),
                            onDelete: () =>
                                confirmDeleteItem(item),
                          ),
                        ),
                    ],
                    const SizedBox(height: 80),
                  ],
                ),
              ),
      ),
    );
  }
}

class _RaffleCard extends StatelessWidget {
  final Raffle raffle;
  final bool selected;
  final VoidCallback onTap;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _RaffleCard({
    required this.raffle,
    required this.selected,
    required this.onTap,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: selected
              ? AppTheme.purple
              : Colors.transparent,
          width: 2,
        ),
      ),
      child: ListTile(
        onTap: onTap,
        leading: CircleAvatar(
          backgroundColor: AppTheme.softPurple,
          child: const Icon(
            Icons.casino_rounded,
            color: AppTheme.purple,
          ),
        ),
        title: Text(
          raffle.name,
          style: const TextStyle(
            fontWeight: FontWeight.w800,
          ),
        ),
        subtitle: Text(
          '${raffle.availableItems}/${raffle.totalItems} ideias disponíveis',
        ),
        trailing: PopupMenuButton<String>(
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
      ),
    );
  }
}

class _ItemCard extends StatelessWidget {
  final RaffleItem item;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _ItemCard({
    required this.item,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final status = item.isCompleted
        ? 'Concluído'
        : item.isDrawn
            ? 'Já sorteado'
            : 'Disponível';

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
      ),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: AppTheme.softPurple,
          child: Icon(
            item.isCompleted
                ? Icons.check_circle_rounded
                : item.isDrawn
                    ? Icons.done_rounded
                    : Icons.lightbulb_rounded,
            color: AppTheme.purple,
          ),
        ),
        title: Text(
          item.title,
          style: const TextStyle(
            fontWeight: FontWeight.w800,
          ),
        ),
        subtitle: Text(
          item.description?.isNotEmpty == true
              ? '${item.description} • $status'
              : status,
        ),
        trailing: PopupMenuButton<String>(
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
      ),
    );
  }
}

class _EmptyItemCard extends StatelessWidget {
  const _EmptyItemCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
      ),
      child: const Row(
        children: [
          Icon(
            Icons.lightbulb_outline_rounded,
            color: AppTheme.purple,
          ),
          SizedBox(width: 12),
          Expanded(
            child: Text(
              'Nenhuma ideia ainda. Adicione a primeira.',
              style: TextStyle(
                color: AppTheme.mutedText,
              ),
            ),
          ),
        ],
      ),
    );
  }
}