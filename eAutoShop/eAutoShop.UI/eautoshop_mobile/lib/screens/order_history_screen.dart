import 'dart:math' as math;

import 'package:eautoshop_mobile/models/order/order.dart';
import 'package:eautoshop_mobile/models/order/order_search_object.dart';
import 'package:eautoshop_mobile/models/order_item/order_item.dart';
import 'package:eautoshop_mobile/models/product_review/product_review_insert.dart';
import 'package:eautoshop_mobile/providers/order_item_provider.dart';
import 'package:eautoshop_mobile/providers/order_provider.dart';
import 'package:eautoshop_mobile/providers/product_review_provider.dart';
import 'package:eautoshop_mobile/screens/master_screen.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

class OrderHistoryScreen extends StatefulWidget {
  const OrderHistoryScreen({super.key});

  @override
  State<OrderHistoryScreen> createState() => _OrderHistoryScreenState();
}

class _OrderHistoryScreenState extends State<OrderHistoryScreen> {
  static const int _pageSize = 8;

  final TextEditingController _minAmountController = TextEditingController();
  final TextEditingController _maxAmountController = TextEditingController();

  int _page = 1;
  String? _stateFilter;
  bool? _discountFilter;
  int? _loadingOrderId;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadOrders());
  }

  @override
  void dispose() {
    _minAmountController.dispose();
    _maxAmountController.dispose();
    super.dispose();
  }

  Future<void> _loadOrders() async {
    final search = OrderSearchObject(
      state: _stateFilter,
      minTotalAmount: double.tryParse(_minAmountController.text.trim()),
      maxTotalAmount: double.tryParse(_maxAmountController.text.trim()),
      hasDiscount: _discountFilter,
    );

    await context.read<OrderProvider>().getByClient(
      pageNumber: _page,
      pageSize: _pageSize,
      orderSearch: search,
    );
  }

  String _formatDate(Object? value) {
    if (value == null) return 'Nije određeno';

    final date = value is DateTime
        ? value
        : DateTime.tryParse(value.toString());

    return date == null
        ? value.toString()
        : DateFormat('dd.MM.yyyy').format(date);
  }

  String _stateLabel(String state) {
    switch (state.toLowerCase()) {
      case 'initial':
        return 'Kreirana';
      case 'missingpayment':
        return 'Čeka plaćanje';
      case 'paymentfailed':
        return 'Plaćanje neuspješno';
      case 'onhold':
        return 'Plaćeno – čeka obradu';
      case 'accepted':
        return 'Prihvaćena';
      case 'rejected':
        return 'Odbijena';
      case 'cancelled':
        return 'Otkazana';
      case 'completed':
        return 'Završena';
      case 'pending':
        return 'Na čekanju';
      case 'shipped':
        return 'Poslana';
      case 'delivered':
        return 'Isporučena';
      default:
        return state;
    }
  }

  Color _stateColor(BuildContext context, String state) {
    switch (state.toLowerCase()) {
      case 'completed':
      case 'delivered':
        return Colors.green.shade700;
      case 'accepted':
      case 'shipped':
        return Colors.blue.shade700;
      case 'onhold':
      case 'pending':
      case 'missingpayment':
        return Colors.orange.shade800;
      case 'rejected':
      case 'cancelled':
      case 'paymentfailed':
        return Theme.of(context).colorScheme.error;
      default:
        return Theme.of(context).colorScheme.onSurfaceVariant;
    }
  }

  bool _canReview(String state) {
    final normalized = state.toLowerCase();
    return normalized == 'completed' || normalized == 'delivered';
  }

  Future<void> _openOrderDetails(Order order) async {
    setState(() => _loadingOrderId = order.id);

    try {
      final items = await context.read<OrderItemProvider>().getByOrder(
        order.id,
      );

      if (!mounted) return;

      await showModalBottomSheet<void>(
        context: context,
        isScrollControlled: true,
        useSafeArea: true,
        showDragHandle: true,
        builder: (sheetContext) {
          return DraggableScrollableSheet(
            expand: false,
            initialChildSize: 0.82,
            minChildSize: 0.55,
            maxChildSize: 0.95,
            builder: (context, scrollController) {
              return ListView(
                controller: scrollController,
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                children: [
                  Text(
                    'Narudžba #${order.id}',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  _OrderInfoCard(order: order, formatDate: _formatDate),
                  const SizedBox(height: 16),
                  Text(
                    'Proizvodi',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  if (items.isEmpty)
                    const Card(
                      child: Padding(
                        padding: EdgeInsets.all(16),
                        child: Text('Narudžba nema stavki.'),
                      ),
                    )
                  else
                    ...items.map(
                      (item) => _OrderItemCard(
                        item: item,
                        canReview: _canReview(order.state),
                        onReview: () => _showReviewDialog(item),
                      ),
                    ),
                  const SizedBox(height: 16),
                  if (order.state.toLowerCase() == 'onhold')
                    FilledButton.icon(
                      onPressed: () async {
                        final changed = await _confirmCancel(order.id);
                        if (changed && sheetContext.mounted) {
                          Navigator.pop(sheetContext);
                        }
                      },
                      icon: const Icon(Icons.cancel_outlined),
                      label: const Text('Otkaži narudžbu'),
                      style: FilledButton.styleFrom(
                        backgroundColor: Theme.of(context).colorScheme.error,
                      ),
                    ),
                  if (order.state.toLowerCase() == 'completed')
                    OutlinedButton.icon(
                      onPressed: () async {
                        final changed = await _confirmDelete(order.id);
                        if (changed && sheetContext.mounted) {
                          Navigator.pop(sheetContext);
                        }
                      },
                      icon: const Icon(Icons.delete_outline),
                      label: const Text('Ukloni iz moje istorije'),
                    ),
                ],
              );
            },
          );
        },
      );
    } catch (e) {
      if (mounted) _showMessage(e.toString(), isError: true);
    } finally {
      if (mounted) setState(() => _loadingOrderId = null);
    }
  }

  Future<void> _showReviewDialog(OrderItem item) async {
    final commentController = TextEditingController();
    final reviewProvider = context.read<ProductReviewProvider>();
    var rating = 0;
    var isSubmitting = false;
    String? errorMessage;

    final saved = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text(
                'Ocijeni proizvod',
                textAlign: TextAlign.center,
              ),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      item.productName,
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: List.generate(5, (index) {
                        final value = index + 1;
                        return IconButton(
                          tooltip: '$value/5',
                          onPressed: isSubmitting
                              ? null
                              : () {
                                  setDialogState(() {
                                    rating = value;
                                    errorMessage = null;
                                  });
                                },
                          iconSize: 36,
                          color: Colors.amber.shade700,
                          icon: Icon(
                            value <= rating ? Icons.star : Icons.star_border,
                          ),
                        );
                      }),
                    ),
                    if (errorMessage != null) ...[
                      const SizedBox(height: 4),
                      Text(
                        errorMessage!,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.error,
                        ),
                      ),
                    ],
                    const SizedBox(height: 12),
                    TextField(
                      controller: commentController,
                      enabled: !isSubmitting,
                      minLines: 3,
                      maxLines: 6,
                      maxLength: 1000,
                      decoration: const InputDecoration(
                        labelText: 'Komentar (nije obavezan)',
                        alignLabelWithHint: true,
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: isSubmitting
                      ? null
                      : () => Navigator.pop(dialogContext, false),
                  child: const Text('Odustani'),
                ),
                FilledButton.icon(
                  onPressed: isSubmitting
                      ? null
                      : () async {
                          if (rating == 0) {
                            setDialogState(() {
                              errorMessage = 'Izaberite ocjenu od 1 do 5.';
                            });
                            return;
                          }

                          FocusScope.of(dialogContext).unfocus();
                          setDialogState(() {
                            isSubmitting = true;
                            errorMessage = null;
                          });

                          try {
                            final comment = commentController.text.trim();

                            await reviewProvider.addReview(
                              ProductReviewInsert(
                                item.productId,
                                rating,
                                comment.isEmpty ? null : comment,
                              ),
                            );

                            if (dialogContext.mounted) {
                              Navigator.pop(dialogContext, true);
                            }
                          } catch (e) {
                            if (!dialogContext.mounted) return;

                            setDialogState(() {
                              isSubmitting = false;
                              errorMessage = e.toString().replaceFirst(
                                'Exception: ',
                                '',
                              );
                            });
                          }
                        },
                  icon: isSubmitting
                      ? const SizedBox.square(
                          dimension: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.send_outlined),
                  label: Text(isSubmitting ? 'Šaljem...' : 'Pošalji'),
                ),
              ],
            );
          },
        );
      },
    );

    commentController.dispose();

    if (saved == true && mounted) {
      _showMessage('Hvala! Recenzija je uspješno sačuvana.');
    }
  }

  Future<bool> _confirmCancel(int orderId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Otkazivanje narudžbe'),
        content: const Text('Da li ste sigurni da želite otkazati narudžbu?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Ne'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Da, otkaži'),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return false;

    try {
      await context.read<OrderProvider>().cancel(orderId);
      await _loadOrders();
      if (mounted) _showMessage('Narudžba je otkazana.');
      return true;
    } catch (e) {
      if (mounted) _showMessage(e.toString(), isError: true);
      return false;
    }
  }

  Future<bool> _confirmDelete(int orderId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Uklanjanje narudžbe'),
        content: const Text(
          'Narudžba će biti uklonjena samo iz vašeg prikaza istorije.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Odustani'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Ukloni'),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return false;

    try {
      await context.read<OrderProvider>().delete(orderId);
      await _loadOrders();
      if (mounted) _showMessage('Narudžba je uklonjena iz istorije.');
      return true;
    } catch (e) {
      if (mounted) _showMessage(e.toString(), isError: true);
      return false;
    }
  }

  Future<void> _showFilters() async {
    final applied = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (sheetContext) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Padding(
              padding: EdgeInsets.fromLTRB(
                20,
                0,
                20,
                20 + MediaQuery.viewInsetsOf(context).bottom,
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      'Filteri',
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.headlineSmall,
                    ),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<String>(
                      key: ValueKey(_stateFilter),
                      initialValue: _stateFilter,
                      hint: const Text('Sva stanja'),
                      decoration: const InputDecoration(
                        labelText: 'Status',
                        border: OutlineInputBorder(),
                      ),
                      items: const [
                        DropdownMenuItem(
                          value: 'onhold',
                          child: Text('Na čekanju'),
                        ),
                        DropdownMenuItem(
                          value: 'accepted',
                          child: Text('Prihvaćena'),
                        ),
                        DropdownMenuItem(
                          value: 'completed',
                          child: Text('Završena'),
                        ),
                        DropdownMenuItem(
                          value: 'cancelled',
                          child: Text('Otkazana'),
                        ),
                        DropdownMenuItem(
                          value: 'rejected',
                          child: Text('Odbijena'),
                        ),
                        DropdownMenuItem(
                          value: 'paymentfailed',
                          child: Text('Plaćanje neuspješno'),
                        ),
                      ],
                      onChanged: (value) =>
                          setModalState(() => _stateFilter = value),
                    ),
                    Align(
                      alignment: Alignment.centerRight,
                      child: TextButton(
                        onPressed: () =>
                            setModalState(() => _stateFilter = null),
                        child: const Text('Očisti status'),
                      ),
                    ),
                    DropdownButtonFormField<bool>(
                      key: ValueKey(_discountFilter),
                      initialValue: _discountFilter,
                      hint: const Text('Sve narudžbe'),
                      decoration: const InputDecoration(
                        labelText: 'Popust',
                        border: OutlineInputBorder(),
                      ),
                      items: const [
                        DropdownMenuItem(
                          value: true,
                          child: Text('Sa popustom'),
                        ),
                        DropdownMenuItem(
                          value: false,
                          child: Text('Bez popusta'),
                        ),
                      ],
                      onChanged: (value) =>
                          setModalState(() => _discountFilter = value),
                    ),
                    Align(
                      alignment: Alignment.centerRight,
                      child: TextButton(
                        onPressed: () =>
                            setModalState(() => _discountFilter = null),
                        child: const Text('Očisti popust'),
                      ),
                    ),
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _minAmountController,
                            keyboardType: const TextInputType.numberWithOptions(
                              decimal: true,
                            ),
                            decoration: const InputDecoration(
                              labelText: 'Min. iznos (€)',
                              border: OutlineInputBorder(),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: TextField(
                            controller: _maxAmountController,
                            keyboardType: const TextInputType.numberWithOptions(
                              decimal: true,
                            ),
                            decoration: const InputDecoration(
                              labelText: 'Maks. iznos (€)',
                              border: OutlineInputBorder(),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    FilledButton(
                      onPressed: () => Navigator.pop(sheetContext, true),
                      child: const Text('Primijeni filtere'),
                    ),
                    TextButton(
                      onPressed: () {
                        setModalState(() {
                          _stateFilter = null;
                          _discountFilter = null;
                          _minAmountController.clear();
                          _maxAmountController.clear();
                        });
                      },
                      child: const Text('Očisti sve'),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );

    if (applied == true && mounted) {
      setState(() => _page = 1);
      await _loadOrders();
    }
  }

  void _showMessage(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message.replaceFirst('Exception: ', '')),
        backgroundColor: isError ? Theme.of(context).colorScheme.error : null,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<OrderProvider>();
    final totalPages = math.max(1, (provider.countOfItems / _pageSize).ceil());

    return MasterScreen(
      child: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Moje narudžbe',
                          style: Theme.of(context).textTheme.headlineSmall
                              ?.copyWith(fontWeight: FontWeight.bold),
                        ),
                        Text(
                          '${provider.countOfItems} ukupno',
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                      ],
                    ),
                  ),
                  IconButton.filledTonal(
                    tooltip: 'Filteri',
                    onPressed: provider.isLoading ? null : _showFilters,
                    icon: const Icon(Icons.tune),
                  ),
                ],
              ),
            ),
            Expanded(
              child: provider.isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : provider.orders.isEmpty
                  ? const _EmptyOrders()
                  : RefreshIndicator(
                      onRefresh: _loadOrders,
                      child: ListView.separated(
                        physics: const AlwaysScrollableScrollPhysics(),
                        padding: const EdgeInsets.fromLTRB(12, 8, 12, 16),
                        itemCount: provider.orders.length,
                        separatorBuilder: (context, index) =>
                            const SizedBox(height: 8),
                        itemBuilder: (context, index) {
                          final order = provider.orders[index];
                          final color = _stateColor(context, order.state);

                          return Card(
                            clipBehavior: Clip.antiAlias,
                            child: InkWell(
                              onTap: _loadingOrderId == null
                                  ? () => _openOrderDetails(order)
                                  : null,
                              child: Padding(
                                padding: const EdgeInsets.all(16),
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    CircleAvatar(
                                      backgroundColor: color.withValues(
                                        alpha: 0.12,
                                      ),
                                      foregroundColor: color,
                                      child: const Icon(
                                        Icons.receipt_long_outlined,
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Row(
                                            children: [
                                              Expanded(
                                                child: Text(
                                                  'Narudžba #${order.id}',
                                                  style: Theme.of(context)
                                                      .textTheme
                                                      .titleMedium
                                                      ?.copyWith(
                                                        fontWeight:
                                                            FontWeight.bold,
                                                      ),
                                                ),
                                              ),
                                              Text(
                                                '${order.totalAmount.toStringAsFixed(2)} €',
                                                style: Theme.of(context)
                                                    .textTheme
                                                    .titleMedium
                                                    ?.copyWith(
                                                      fontWeight:
                                                          FontWeight.bold,
                                                    ),
                                              ),
                                            ],
                                          ),
                                          const SizedBox(height: 6),
                                          Text(_formatDate(order.orderDate)),
                                          const SizedBox(height: 8),
                                          Container(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 10,
                                              vertical: 5,
                                            ),
                                            decoration: BoxDecoration(
                                              color: color.withValues(
                                                alpha: 0.12,
                                              ),
                                              borderRadius:
                                                  BorderRadius.circular(999),
                                            ),
                                            child: Text(
                                              _stateLabel(order.state),
                                              style: TextStyle(
                                                color: color,
                                                fontWeight: FontWeight.w600,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    _loadingOrderId == order.id
                                        ? const SizedBox.square(
                                            dimension: 22,
                                            child: CircularProgressIndicator(
                                              strokeWidth: 2,
                                            ),
                                          )
                                        : const Icon(Icons.chevron_right),
                                  ],
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
            ),
            if (!provider.isLoading && provider.orders.isNotEmpty)
              SafeArea(
                top: false,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(12, 4, 12, 10),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      IconButton(
                        tooltip: 'Prethodna stranica',
                        onPressed: _page > 1
                            ? () async {
                                setState(() => _page--);
                                await _loadOrders();
                              }
                            : null,
                        icon: const Icon(Icons.chevron_left),
                      ),
                      Text('Stranica $_page od $totalPages'),
                      IconButton(
                        tooltip: 'Sljedeća stranica',
                        onPressed: _page < totalPages
                            ? () async {
                                setState(() => _page++);
                                await _loadOrders();
                              }
                            : null,
                        icon: const Icon(Icons.chevron_right),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _OrderInfoCard extends StatelessWidget {
  final Order order;
  final String Function(Object?) formatDate;

  const _OrderInfoCard({required this.order, required this.formatDate});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            _InfoRow(
              label: 'Datum narudžbe',
              value: formatDate(order.orderDate),
            ),
            _InfoRow(
              label: 'Datum slanja',
              value: formatDate(order.shippingDate),
            ),
            _InfoRow(
              label: 'Ukupno',
              value: '${order.totalAmount.toStringAsFixed(2)} €',
            ),
            _InfoRow(label: 'Grad', value: order.shippingCity),
            _InfoRow(label: 'Adresa', value: order.shippingAddress),
            _InfoRow(label: 'Poštanski broj', value: order.shippingPostalCode),
          ],
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;

  const _InfoRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Text(
              label,
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
          const SizedBox(width: 12),
          Flexible(child: Text(value, textAlign: TextAlign.end)),
        ],
      ),
    );
  }
}

class _OrderItemCard extends StatelessWidget {
  final OrderItem item;
  final bool canReview;
  final VoidCallback onReview;

  const _OrderItemCard({
    required this.item,
    required this.canReview,
    required this.onReview,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              item.productName,
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text('Količina: ${item.quantity}'),
            Text('Cijena komada: ${item.unitPrice.toStringAsFixed(2)} €'),
            Text(
              'Ukupno: ${item.totalItemsPriceDiscounted.toStringAsFixed(2)} €',
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
            if (item.discount > 0)
              Text('Popust: ${(item.discount * 100).toStringAsFixed(0)}%'),
            if (canReview) ...[
              const SizedBox(height: 10),
              Align(
                alignment: Alignment.centerRight,
                child: OutlinedButton.icon(
                  onPressed: onReview,
                  icon: const Icon(Icons.star_outline),
                  label: const Text('Ocijeni proizvod'),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _EmptyOrders extends StatelessWidget {
  const _EmptyOrders();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.receipt_long_outlined,
              size: 72,
              color: Theme.of(context).colorScheme.outline,
            ),
            const SizedBox(height: 16),
            Text(
              'Nema narudžbi za prikaz.',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.titleMedium,
            ),
          ],
        ),
      ),
    );
  }
}
