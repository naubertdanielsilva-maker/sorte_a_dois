import 'package:flutter/material.dart';

import '../../services/wish_service.dart';
import '../../theme/app_theme.dart';
import '../../widgets/premium_card.dart';

class WishlistScreen extends StatefulWidget {
  const WishlistScreen({super.key});

  @override
  State<WishlistScreen> createState() => _WishlistScreenState();
}

class _WishlistScreenState extends State<WishlistScreen> {
  bool isLoading = true;
  List<WishItem> wishes = [];

  @override
  void initState() {
    super.initState();
    loadWishes();
  }

  Future<void> loadWishes() async {
    setState(() => isLoading = true);

    try {
      final data = await WishService.getWishes();
      setState(() => wishes = data);
    } catch (error) {
      showMessage(error.toString());
      setState(() => wishes = []);
    }
  }

  Future<void> openCreateWishDialog() async {
    final titleController = TextEditingController();
    final descriptionController = TextEditingController();
    String category = 'Geral';

    await showDialog(
      context: context,
      builder: (_) => StatefulBuilder(
        builder: (context, setDialogState) {
          return AlertDialog(
            title: const Text('Novo desejo'),
            content: SingleChildScrollView(
              child: Column(
                children: [
                  TextField(
                    controller: titleController,
                    decoration: const InputDecoration(
                      labelText: 'Desejo',
                      hintText: 'Ex: Viajar para Tiradentes',
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: descriptionController,
                    decoration: const InputDecoration(
                      labelText: 'Descrição',
                      hintText: 'Algum detalhe especial',
                    ),
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    value: category,
                    decoration: const InputDecoration(labelText: 'Categoria'),
                    items: const [
                      DropdownMenuItem(value: 'Geral', child: Text('Geral')),
                      DropdownMenuItem(value: 'Presente', child: Text('Presente')),
                      DropdownMenuItem(value: 'Viagem', child: Text('Viagem')),
                      DropdownMenuItem(value: 'Restaurante', child: Text('Restaurante')),
                      DropdownMenuItem(value: 'Experiência', child: Text('Experiência')),
                    ],
                    onChanged: (value) {
                      if (value != null) {
                        setDialogState(() => category = value);
                      }
                    },
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
                  final title = titleController.text.trim();

                  if (title.isEmpty) {
                    showMessage('Digite um desejo.');
                    return;
                  }

                  try {
                    await WishService.createWish(
                      title: title,
                      description: descriptionController.text.trim(),
                      category: category,
                    );

                    if (!mounted) return;

                    Navigator.pop(context);
                    await loadWishes();
                    showMessage('Desejo salvo com sucesso.');
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

  Future<void> confirmDelete(WishItem wish) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Remover desejo?'),
        content: Text('Deseja remover "${wish.title}" da lista?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Remover'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      await WishService.deleteWish(wish.id);
      await loadWishes();
      showMessage('Desejo removido.');
    } catch (error) {
      showMessage(error.toString());
    }
  }

  void showMessage(String message) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message.replaceAll('Exception: ', ''))),
    );
  }

  IconData iconForCategory(String? category) {
    switch (category) {
      case 'Presente':
        return Icons.card_giftcard_rounded;
      case 'Viagem':
        return Icons.flight_takeoff_rounded;
      case 'Restaurante':
        return Icons.restaurant_rounded;
      case 'Experiência':
        return Icons.favorite_rounded;
      default:
        return Icons.star_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      floatingActionButton: FloatingActionButton.extended(
        onPressed: openCreateWishDialog,
        icon: const Icon(Icons.add),
        label: const Text('Desejo'),
      ),
      body: SafeArea(
        child: isLoading
            ? const Center(child: CircularProgressIndicator())
            : RefreshIndicator(
                onRefresh: loadWishes,
                child: ListView(
                  padding: const EdgeInsets.all(20),
                  children: [
                    const Text(
                      'LISTA DO CASAL',
                      style: TextStyle(
                        color: AppTheme.purple,
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                      ),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'Desejos',
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
                            Icons.card_giftcard_rounded,
                            size: 54,
                            color: AppTheme.purple,
                          ),
                          const SizedBox(height: 12),
                          const Text(
                            'Coisas que queremos viver',
                            style: TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            wishes.isEmpty
                                ? 'Nenhum desejo ainda.'
                                : '${wishes.length} desejo(s) na lista.',
                            style: const TextStyle(color: AppTheme.mutedText),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 18),
                    if (wishes.isEmpty)
                      const _EmptyWishCard()
                    else
                      ...wishes.map(
                        (wish) => Container(
                          margin: const EdgeInsets.only(bottom: 12),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(22),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.08),
                                blurRadius: 16,
                                offset: const Offset(0, 8),
                              ),
                            ],
                          ),
                          child: ListTile(
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 18,
                              vertical: 10,
                            ),
                            leading: CircleAvatar(
                              backgroundColor: AppTheme.softPurple,
                              child: Icon(
                                iconForCategory(wish.category),
                                color: AppTheme.purple,
                              ),
                            ),
                            title: Text(
                              wish.title,
                              style: const TextStyle(
                                fontWeight: FontWeight.w800,
                                color: AppTheme.darkText,
                              ),
                            ),
                            subtitle: Text(
                              [
                                wish.category ?? 'Geral',
                                if (wish.description != null &&
                                    wish.description!.isNotEmpty)
                                  wish.description!,
                              ].join(' • '),
                            ),
                            trailing: IconButton(
                              icon: const Icon(Icons.delete_outline_rounded),
                              onPressed: () => confirmDelete(wish),
                            ),
                          ),
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

class _EmptyWishCard extends StatelessWidget {
  const _EmptyWishCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
      ),
      child: const Column(
        children: [
          Icon(Icons.favorite_border_rounded, size: 46, color: AppTheme.purple),
          SizedBox(height: 12),
          Text(
            'A lista ainda está vazia',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
          ),
          SizedBox(height: 6),
          Text(
            'Adicione presentes, viagens, restaurantes ou experiências que vocês querem viver.',
            textAlign: TextAlign.center,
            style: TextStyle(color: AppTheme.mutedText),
          ),
        ],
      ),
    );
  }
}