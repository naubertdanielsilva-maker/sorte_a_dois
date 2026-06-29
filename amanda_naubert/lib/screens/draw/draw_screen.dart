import 'package:flutter/material.dart';

import '../../services/dashboard_service.dart';
import '../../services/raffle_service.dart';
import '../../theme/app_theme.dart';
import '../../widgets/info_tile.dart';
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
  RaffleItem? selectedItem;
  List<RaffleItem> items = [];

  @override
  void initState() {
    super.initState();
    loadRaffles();
  }

  Future<void> loadRaffles() async {
    setState(() => isLoading = true);

    try {
      final data = await RaffleService.getRafflesWithCounts();

      setState(() {
        raffles = data;
        selectedRaffle = data.isNotEmpty ? data.first : null;
      });

      if (selectedRaffle != null) {
        await loadItems(selectedRaffle!.id);
      }
    } catch (error) {
      showMessage(error.toString());
    } finally {
      setState(() => isLoading = false);
    }
  }

  Future<void> loadItems(int raffleId) async {
    final data = await RaffleService.getItems(raffleId);
    setState(() => items = data);
  }

  Future<void> handleDraw() async {
    if (selectedRaffle == null) return;

    setState(() {
      isDrawing = true;
      selectedItem = null;
    });

    try {
      await Future.delayed(const Duration(milliseconds: 700));

      final item = await RaffleService.draw(selectedRaffle!.id);

      setState(() {
        selectedItem = item;
      });

      await loadRaffles();

      if (!mounted) return;

      showDialog(
        context: context,
        builder: (_) => AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
          title: const Text('🎉 Sorteado!'),
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
              if (item.description != null && item.description!.isNotEmpty) ...[
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
              onPressed: () => Navigator.pop(context),
              child: const Text('Fechar'),
            ),
          ],
        ),
      );
    } catch (error) {
      showMessage(error.toString());
    } finally {
      setState(() => isDrawing = false);
    }
  }

  Future<void> openCreateRaffleDialog() async {
    final nameController = TextEditingController();
    final descriptionController = TextEditingController();

    final dashboard = await DashboardService.loadDashboard();

    if (!mounted) return;

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Novo sorteio'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              decoration: const InputDecoration(labelText: 'Nome'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: descriptionController,
              decoration: const InputDecoration(labelText: 'Descrição'),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () async {
              try {
                await RaffleService.createRaffle(
                  coupleId: dashboard.coupleId,
                  name: nameController.text.trim(),
                  description: descriptionController.text.trim(),
                );

                if (!mounted) return;
                Navigator.pop(context);
                await loadRaffles();
              } catch (error) {
                showMessage(error.toString());
              }
            },
            child: const Text('Criar'),
          ),
        ],
      ),
    );
  }

  Future<void> openCreateItemDialog() async {
    if (selectedRaffle == null) return;

    final titleController = TextEditingController();
    final descriptionController = TextEditingController();

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text('Novo item em ${selectedRaffle!.name}'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: titleController,
              decoration: const InputDecoration(labelText: 'Ideia'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: descriptionController,
              decoration: const InputDecoration(labelText: 'Descrição'),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () async {
              try {
                await RaffleService.createItem(
                  raffleId: selectedRaffle!.id,
                  title: titleController.text.trim(),
                  description: descriptionController.text.trim(),
                );

                if (!mounted) return;
                Navigator.pop(context);
                await loadRaffles();
              } catch (error) {
                showMessage(error.toString());
              }
            },
            child: const Text('Adicionar'),
          ),
        ],
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      floatingActionButton: FloatingActionButton.extended(
        onPressed: openCreateRaffleDialog,
        icon: const Icon(Icons.add),
        label: const Text('Sorteio'),
      ),
      body: SafeArea(
        child: isLoading
            ? const Center(child: CircularProgressIndicator())
            : ListView(
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

                  if (raffles.isEmpty)
                    PremiumCard(
                      child: Column(
                        children: [
                          const Text('🎲', style: TextStyle(fontSize: 70)),
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
                            style: TextStyle(color: AppTheme.mutedText),
                          ),
                          const SizedBox(height: 18),
                          FilledButton(
                            onPressed: openCreateRaffleDialog,
                            child: const Text('Criar sorteio'),
                          ),
                        ],
                      ),
                    )
                  else ...[
                    PremiumCard(
                      child: Column(
                        children: [
                          AnimatedContainer(
                            duration: const Duration(milliseconds: 300),
                            width: 150,
                            height: 205,
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                colors: [Color(0xFF7B2FF7), Color(0xFFFF4F8B)],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              borderRadius: BorderRadius.circular(26),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.18),
                                  blurRadius: 24,
                                  offset: const Offset(0, 12),
                                ),
                              ],
                            ),
                            child: Center(
                              child: Text(
                                isDrawing ? '🎴' : selectedRaffle?.icon ?? '🎲',
                                style: const TextStyle(fontSize: 76),
                              ),
                            ),
                          ),
                          const SizedBox(height: 18),
                          Text(
                            selectedRaffle?.name ?? 'Escolha um sorteio',
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              color: AppTheme.darkText,
                              fontWeight: FontWeight.w900,
                              fontSize: 24,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            selectedRaffle?.description ?? '',
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              color: AppTheme.mutedText,
                              fontSize: 15,
                            ),
                          ),
                          const SizedBox(height: 20),
                          FilledButton(
                            onPressed: isDrawing ? null : handleDraw,
                            child: Text(
                              isDrawing ? 'Sorteando...' : '🎲 Sortear agora',
                            ),
                          ),
                          const SizedBox(height: 10),
                          TextButton(
                            onPressed: openCreateItemDialog,
                            child: const Text('Adicionar ideia nesta categoria'),
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
                      (raffle) => InfoTile(
                        icon: raffle.icon,
                        title: raffle.name,
                        subtitle:
                            '${raffle.availableItems}/${raffle.totalItems} ideias disponíveis',
                        onTap: () async {
                          setState(() {
                            selectedRaffle = raffle;
                            selectedItem = null;
                          });

                          await loadItems(raffle.id);
                        },
                      ),
                    ),
                    const SizedBox(height: 10),
                    const Text(
                      'Itens desta categoria',
                      style: TextStyle(
                        color: AppTheme.darkText,
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 12),
                    if (items.isEmpty)
                      const InfoTile(
                        icon: '📝',
                        title: 'Nenhum item ainda',
                        subtitle: 'Adicione ideias para este sorteio.',
                      )
                    else
                      ...items.map(
                        (item) => InfoTile(
                          icon: item.isDrawn ? '✅' : '🎯',
                          title: item.title,
                          subtitle: item.description?.isNotEmpty == true
                              ? item.description!
                              : item.isDrawn
                                  ? 'Já sorteado'
                                  : 'Disponível',
                        ),
                      ),
                  ],
                ],
              ),
      ),
    );
  }
}