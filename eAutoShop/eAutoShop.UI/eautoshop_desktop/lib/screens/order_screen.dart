import 'package:eautoshop_desktop/constants.dart';
import 'package:eautoshop_desktop/models/order/order.dart';
import 'package:eautoshop_desktop/models/order/order_accept.dart';
import 'package:eautoshop_desktop/models/order/order_search_object.dart';
import 'package:eautoshop_desktop/models/order_item/order_item.dart';
import 'package:eautoshop_desktop/providers/auth_provider.dart';
import 'package:eautoshop_desktop/providers/order_item_provider.dart';
import 'package:eautoshop_desktop/providers/order_provider.dart';
import 'package:eautoshop_desktop/utilities/custom_exception.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class OrderScreen extends StatefulWidget {
  const OrderScreen({super.key});

  @override
  State<OrderScreen> createState() => _OrderScreenState();
}

class _OrderScreenState extends State<OrderScreen> {
  static const Color _primaryBlue = Color(0xFF2848C7);
  static const int _pageSize = 10;

  final TextEditingController _customerController = TextEditingController();
  final ScrollController _horizontalScrollController = ScrollController();

  int _page = 1;
  _OrderFilters _filters = const _OrderFilters();
  bool _initialLoading = true;
  String? _loadError;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadInitialData());
  }

  @override
  void dispose() {
    _customerController.dispose();
    _horizontalScrollController.dispose();
    super.dispose();
  }

  Future<void> _loadInitialData() async {
    if (!mounted) return;

    setState(() {
      _initialLoading = true;
      _loadError = null;
    });

    try {
      await _loadOrders();
    } on CustomException catch (error) {
      _loadError = error.message;
    } catch (_) {
      _loadError = 'Narudžbe nisu mogle biti učitane.';
    }

    if (mounted) setState(() => _initialLoading = false);
  }

  Future<void> _loadOrders({bool resetPage = false}) async {
    if (resetPage) _page = 1;

    final search = OrderSearchObject(
      customerName: _emptyToNull(_customerController.text),
      state: _filters.state,
      minTotalAmount: _filters.minTotalAmount,
      maxTotalAmount: _filters.maxTotalAmount,
      minOrderDate: _filters.minOrderDate,
      maxOrderDate: _endOfDay(_filters.maxOrderDate),
      minShippingDate: _filters.minShippingDate,
      maxShippingDate: _endOfDay(_filters.maxShippingDate),
      hasDiscount: _filters.hasDiscount,
    );

    await context.read<OrderProvider>().getForShop(
      page: _page,
      pageSize: _pageSize,
      search: search,
    );
  }

  Future<void> _search() async {
    try {
      await _loadOrders(resetPage: true);
    } on CustomException catch (error) {
      _showMessage(error.message, isError: true);
    } catch (_) {
      _showMessage('Narudžbe nisu mogle biti učitane.', isError: true);
    }
  }

  Future<void> _clearSearch() async {
    _customerController.clear();
    setState(() {});
    await _search();
  }

  Future<void> _openFilters() async {
    final result = await showDialog<_OrderFilters>(
      context: context,
      builder: (_) => _OrderFilterDialog(initial: _filters),
    );

    if (result == null || !mounted) return;

    setState(() => _filters = result);
    await _search();
  }

  Future<void> _showDetails(Order order) async {
    final itemProvider = context.read<OrderItemProvider>();
    itemProvider.clearOrderItems();

    try {
      await itemProvider.getByOrder(orderId: order.id);
    } on CustomException catch (error) {
      _showMessage(error.message, isError: true);
      return;
    } catch (_) {
      _showMessage('Stavke narudžbe nisu mogle biti učitane.', isError: true);
      return;
    }

    if (!mounted) return;

    await showDialog<void>(
      context: context,
      builder: (_) => _OrderDetailsDialog(
        order: order,
        orderItems: List<OrderItem>.unmodifiable(itemProvider.orderItems),
      ),
    );
  }

  Future<void> _handleAction(Order order, _OrderAction action) async {
    final provider = context.read<OrderProvider>();

    if (action == _OrderAction.accept) {
      final selectedDate = await _selectShippingDate();
      if (selectedDate == null || !mounted) return;

      try {
        await provider.acceptOrder(
          id: order.id,
          request: OrderAccept(shippingDate: selectedDate),
        );
        if (!mounted) return;

        await _loadOrders();
        _showMessage('Narudžba je prihvaćena.');
      } on CustomException catch (error) {
        _showMessage(error.message, isError: true);
      } catch (_) {
        _showMessage('Prihvatanje narudžbe nije uspjelo.', isError: true);
      }
      return;
    }

    final configuration = _actionConfiguration(order, action);
    final confirmed = await _confirm(
      title: configuration.title,
      message: configuration.message,
      confirmLabel: configuration.confirmLabel,
    );

    if (!confirmed || !mounted) return;

    try {
      switch (action) {
        case _OrderAction.reject:
          await provider.rejectOrder(order.id);
          break;
        case _OrderAction.cancel:
          await provider.cancelOrder(order.id);
          break;
        case _OrderAction.complete:
          await provider.completeOrder(order.id);
          break;
        case _OrderAction.deleteHistory:
          await provider.softDeleteOrder(order.id);
          break;
        case _OrderAction.accept:
          break;
      }

      if (action == _OrderAction.deleteHistory &&
          _page > 1 &&
          provider.orders.length == 1) {
        _page--;
      }

      if (!mounted) return;

      await _loadOrders();
      _showMessage(configuration.successMessage);
    } on CustomException catch (error) {
      _showMessage(error.message, isError: true);
    } catch (_) {
      _showMessage('Akcija nad narudžbom nije uspjela.', isError: true);
    }
  }

  Future<DateTime?> _selectShippingDate() async {
    final now = DateTime.now();
    final firstDate = DateTime(now.year, now.month, now.day + 1);

    final selected = await showDatePicker(
      context: context,
      initialDate: firstDate,
      firstDate: firstDate,
      lastDate: DateTime(now.year + 5, 12, 31),
      helpText: 'Odaberite datum dostave',
      cancelText: 'Odustani',
      confirmText: 'Odaberi',
    );

    if (selected == null) return null;

    return DateTime.utc(selected.year, selected.month, selected.day, 12);
  }

  _ActionConfiguration _actionConfiguration(Order order, _OrderAction action) {
    switch (action) {
      case _OrderAction.reject:
        return _ActionConfiguration(
          title: 'Odbijanje narudžbe',
          message:
              'Da li želite odbiti narudžbu #${order.id}? Kupcu će biti izvršen povrat novca.',
          confirmLabel: 'Odbij',
          successMessage: 'Narudžba je odbijena.',
        );
      case _OrderAction.cancel:
        return _ActionConfiguration(
          title: 'Otkazivanje narudžbe',
          message:
              'Da li želite otkazati narudžbu #${order.id}? Kupcu će biti izvršen povrat novca.',
          confirmLabel: 'Otkaži',
          successMessage: 'Narudžba je otkazana.',
        );
      case _OrderAction.complete:
        return _ActionConfiguration(
          title: 'Završavanje narudžbe',
          message: 'Da li je narudžba #${order.id} uspješno završena?',
          confirmLabel: 'Završi',
          successMessage: 'Narudžba je označena kao završena.',
        );
      case _OrderAction.deleteHistory:
        return _ActionConfiguration(
          title: 'Uklanjanje iz historije',
          message:
              'Da li želite ukloniti narudžbu #${order.id} iz historije prodavnice?',
          confirmLabel: 'Ukloni',
          successMessage: 'Narudžba je uklonjena iz historije.',
        );
      case _OrderAction.accept:
        return const _ActionConfiguration(
          title: '',
          message: '',
          confirmLabel: '',
          successMessage: '',
        );
    }
  }

  Future<bool> _confirm({
    required String title,
    required String message,
    required String confirmLabel,
  }) async {
    return await showDialog<bool>(
          context: context,
          builder: (dialogContext) => AlertDialog(
            title: Text(title),
            content: Text(message),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(dialogContext, false),
                child: const Text('Odustani'),
              ),
              FilledButton(
                onPressed: () => Navigator.pop(dialogContext, true),
                child: Text(confirmLabel),
              ),
            ],
          ),
        ) ??
        false;
  }

  void _showMessage(String message, {bool isError = false}) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError
            ? const Color(0xFFB3261E)
            : const Color(0xFF1B7F3A),
      ),
    );
  }

  int _totalPages(int count) {
    final total = (count / _pageSize).ceil();
    return total < 1 ? 1 : total;
  }

  bool get _hasFilters => !_filters.isEmpty;

  @override
  Widget build(BuildContext context) {
    if (_initialLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_loadError != null) {
      return _LoadError(message: _loadError!, onRetry: _loadInitialData);
    }

    final provider = context.watch<OrderProvider>();
    final authProvider = context.watch<AuthProvider>();
    final totalPages = _totalPages(provider.countOfItems);

    return Padding(
      padding: const EdgeInsets.all(AppPadding.large),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildToolbar(provider),
          const SizedBox(height: AppPadding.medium),
          Expanded(
            child: Card(
              elevation: 0,
              color: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppRadius.card),
                side: const BorderSide(color: Color(0xFFE2E7F0)),
              ),
              child: provider.isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : provider.orders.isEmpty
                  ? const _EmptyOrders()
                  : _OrderTable(
                      orders: provider.orders,
                      canManage:
                          authProvider.isManager || authProvider.isSalesperson,
                      horizontalScrollController: _horizontalScrollController,
                      onDetails: _showDetails,
                      onAction: _handleAction,
                    ),
            ),
          ),
          const SizedBox(height: AppPadding.small),
          _buildPagination(provider, totalPages),
        ],
      ),
    );
  }

  Widget _buildToolbar(OrderProvider provider) {
    return Row(
      children: [
        SizedBox(
          width: 360,
          child: TextField(
            controller: _customerController,
            onSubmitted: (_) => _search(),
            onChanged: (_) => setState(() {}),
            decoration: InputDecoration(
              hintText: 'Pretraga po kupcu',
              prefixIcon: const Icon(Icons.search),
              suffixIcon: _customerController.text.isEmpty
                  ? null
                  : IconButton(
                      tooltip: 'Poništi pretragu',
                      onPressed: _clearSearch,
                      icon: const Icon(Icons.close),
                    ),
            ),
          ),
        ),
        const SizedBox(width: AppPadding.small),
        FilledButton.icon(
          onPressed: provider.isLoading ? null : _search,
          icon: const Icon(Icons.search),
          label: const Text('Pretraži'),
          style: FilledButton.styleFrom(
            minimumSize: const Size(120, 52),
            backgroundColor: _primaryBlue,
          ),
        ),
        const SizedBox(width: AppPadding.small),
        Badge(
          isLabelVisible: _hasFilters,
          child: OutlinedButton.icon(
            onPressed: provider.isLoading ? null : _openFilters,
            icon: const Icon(Icons.tune),
            label: const Text('Filteri'),
            style: OutlinedButton.styleFrom(minimumSize: const Size(120, 52)),
          ),
        ),
        const Spacer(),
        Text(
          'Ukupno: ${provider.countOfItems}',
          style: const TextStyle(
            color: Color(0xFF687385),
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  Widget _buildPagination(OrderProvider provider, int totalPages) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        IconButton(
          tooltip: 'Prethodna stranica',
          onPressed: !provider.isLoading && _page > 1
              ? () => _changePage(_page - 1)
              : null,
          icon: const Icon(Icons.chevron_left),
        ),
        Text('Stranica $_page od $totalPages'),
        IconButton(
          tooltip: 'Sljedeća stranica',
          onPressed: !provider.isLoading && _page < totalPages
              ? () => _changePage(_page + 1)
              : null,
          icon: const Icon(Icons.chevron_right),
        ),
      ],
    );
  }

  Future<void> _changePage(int newPage) async {
    final previousPage = _page;
    setState(() => _page = newPage);

    try {
      await _loadOrders();
    } on CustomException catch (error) {
      if (mounted) setState(() => _page = previousPage);
      _showMessage(error.message, isError: true);
    } catch (_) {
      if (mounted) setState(() => _page = previousPage);
      _showMessage('Stranica narudžbi nije mogla biti učitana.', isError: true);
    }
  }
}

class _OrderTable extends StatelessWidget {
  const _OrderTable({
    required this.orders,
    required this.canManage,
    required this.horizontalScrollController,
    required this.onDetails,
    required this.onAction,
  });

  final List<Order> orders;
  final bool canManage;
  final ScrollController horizontalScrollController;
  final ValueChanged<Order> onDetails;
  final void Function(Order order, _OrderAction action) onAction;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final tableWidth = constraints.maxWidth < 1100
            ? 1100.0
            : constraints.maxWidth;

        return Scrollbar(
          controller: horizontalScrollController,
          thumbVisibility: true,
          child: SingleChildScrollView(
            controller: horizontalScrollController,
            scrollDirection: Axis.horizontal,
            child: SizedBox(
              width: tableWidth,
              child: SingleChildScrollView(
                child: DataTable(
                  headingRowColor: WidgetStateProperty.all(
                    const Color(0xFFF0F3FF),
                  ),
                  horizontalMargin: 20,
                  columnSpacing: 24,
                  columns: const [
                    DataColumn(label: Text('Broj')),
                    DataColumn(label: Text('Kupac')),
                    DataColumn(label: Text('Datum narudžbe')),
                    DataColumn(label: Text('Datum dostave')),
                    DataColumn(label: Text('Iznos')),
                    DataColumn(label: Text('Grad')),
                    DataColumn(label: Text('Status')),
                    DataColumn(label: Text('Akcije')),
                  ],
                  rows: orders.map((order) {
                    return DataRow(
                      cells: [
                        DataCell(
                          Text(
                            '#${order.id}',
                            style: const TextStyle(fontWeight: FontWeight.w700),
                          ),
                        ),
                        DataCell(Text(order.username)),
                        DataCell(Text(_formatDate(order.orderDate))),
                        DataCell(
                          Text(
                            order.shippingDate == null
                                ? 'Nije određen'
                                : _formatDate(order.shippingDate!),
                          ),
                        ),
                        DataCell(
                          Text(
                            '${order.totalAmount.toStringAsFixed(2)} €',
                            style: const TextStyle(fontWeight: FontWeight.w600),
                          ),
                        ),
                        DataCell(Text(order.shippingCity)),
                        DataCell(_OrderStatusChip(state: order.state)),
                        DataCell(
                          Row(
                            children: [
                              IconButton(
                                tooltip: 'Detalji narudžbe',
                                onPressed: () => onDetails(order),
                                icon: const Icon(
                                  Icons.visibility_outlined,
                                  color: Color(0xFF2848C7),
                                ),
                              ),
                              if (canManage)
                                _OrderActionsMenu(
                                  order: order,
                                  onSelected: (action) =>
                                      onAction(order, action),
                                ),
                            ],
                          ),
                        ),
                      ],
                    );
                  }).toList(),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

class _OrderActionsMenu extends StatelessWidget {
  const _OrderActionsMenu({required this.order, required this.onSelected});

  final Order order;
  final ValueChanged<_OrderAction> onSelected;

  @override
  Widget build(BuildContext context) {
    final actions = _actionsForState(order.state);
    if (actions.isEmpty) return const SizedBox.shrink();

    return PopupMenuButton<_OrderAction>(
      tooltip: 'Akcije narudžbe',
      onSelected: onSelected,
      itemBuilder: (_) => actions.map((action) {
        return PopupMenuItem<_OrderAction>(
          value: action,
          child: Row(
            children: [
              Icon(_actionIcon(action), size: 20),
              const SizedBox(width: AppPadding.small),
              Text(_actionLabel(action)),
            ],
          ),
        );
      }).toList(),
    );
  }
}

class _OrderStatusChip extends StatelessWidget {
  const _OrderStatusChip({required this.state});

  final String state;

  @override
  Widget build(BuildContext context) {
    final colors = _statusColors(state);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: colors.background,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        _stateLabel(state),
        style: TextStyle(
          color: colors.foreground,
          fontSize: 12,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _OrderDetailsDialog extends StatelessWidget {
  const _OrderDetailsDialog({required this.order, required this.orderItems});

  final Order order;
  final List<OrderItem> orderItems;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Row(
        children: [
          Expanded(child: Text('Narudžba #${order.id}')),
          _OrderStatusChip(state: order.state),
        ],
      ),
      content: SizedBox(
        width: 820,
        height: 620,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Wrap(
              spacing: AppPadding.large,
              runSpacing: AppPadding.small,
              children: [
                _InfoItem(label: 'Kupac', value: order.username),
                _InfoItem(
                  label: 'Datum narudžbe',
                  value: _formatDateTime(order.orderDate),
                ),
                _InfoItem(
                  label: 'Datum dostave',
                  value: order.shippingDate == null
                      ? 'Nije određen'
                      : _formatDate(order.shippingDate!),
                ),
                _InfoItem(
                  label: 'Ukupan iznos',
                  value: '${order.totalAmount.toStringAsFixed(2)} €',
                ),
              ],
            ),
            const SizedBox(height: AppPadding.medium),
            Card(
              elevation: 0,
              color: const Color(0xFFF7F9FC),
              child: Padding(
                padding: const EdgeInsets.all(AppPadding.medium),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Adresa dostave',
                      style: TextStyle(fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(height: AppPadding.small),
                    Text(order.shippingAddress),
                    Text('${order.shippingPostalCode} ${order.shippingCity}'),
                  ],
                ),
              ),
            ),
            const SizedBox(height: AppPadding.medium),
            const Text(
              'Stavke narudžbe',
              style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: AppPadding.small),
            Expanded(
              child: orderItems.isEmpty
                  ? const Center(
                      child: Text('Narudžba nema evidentiranih stavki.'),
                    )
                  : ListView.separated(
                      itemCount: orderItems.length,
                      separatorBuilder: (_, _) => const Divider(height: 1),
                      itemBuilder: (context, index) {
                        return _OrderItemTile(item: orderItems[index]);
                      },
                    ),
            ),
          ],
        ),
      ),
      actions: [
        FilledButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Zatvori'),
        ),
      ],
    );
  }
}

class _OrderItemTile extends StatelessWidget {
  const _OrderItemTile({required this.item});

  final OrderItem item;

  @override
  Widget build(BuildContext context) {
    final hasDiscount = item.discount > 0;
    final effectiveTotal = hasDiscount
        ? item.totalItemsPriceDiscounted
        : item.totalItemsPrice;

    return ListTile(
      contentPadding: const EdgeInsets.symmetric(
        horizontal: AppPadding.small,
        vertical: 4,
      ),
      title: Text(
        item.productName,
        style: const TextStyle(fontWeight: FontWeight.w600),
      ),
      subtitle: Text(
        '${item.quantity} × ${item.unitPrice.toStringAsFixed(2)} €'
        '${hasDiscount ? ' • Popust ${(item.discount * 100).toStringAsFixed(0)}%' : ''}',
      ),
      trailing: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (hasDiscount)
            Text(
              '${item.totalItemsPrice.toStringAsFixed(2)} €',
              style: const TextStyle(
                color: Color(0xFF8B95A5),
                decoration: TextDecoration.lineThrough,
              ),
            ),
          Text(
            '${effectiveTotal.toStringAsFixed(2)} €',
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
          ),
        ],
      ),
    );
  }
}

class _InfoItem extends StatelessWidget {
  const _InfoItem({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 175,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(color: Color(0xFF687385), fontSize: 12),
          ),
          const SizedBox(height: 3),
          Text(value, style: const TextStyle(fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}

class _OrderFilters {
  const _OrderFilters({
    this.state,
    this.hasDiscount,
    this.minTotalAmount,
    this.maxTotalAmount,
    this.minOrderDate,
    this.maxOrderDate,
    this.minShippingDate,
    this.maxShippingDate,
  });

  final String? state;
  final bool? hasDiscount;
  final double? minTotalAmount;
  final double? maxTotalAmount;
  final DateTime? minOrderDate;
  final DateTime? maxOrderDate;
  final DateTime? minShippingDate;
  final DateTime? maxShippingDate;

  bool get isEmpty =>
      state == null &&
      hasDiscount == null &&
      minTotalAmount == null &&
      maxTotalAmount == null &&
      minOrderDate == null &&
      maxOrderDate == null &&
      minShippingDate == null &&
      maxShippingDate == null;
}

class _OrderFilterDialog extends StatefulWidget {
  const _OrderFilterDialog({required this.initial});

  final _OrderFilters initial;

  @override
  State<_OrderFilterDialog> createState() => _OrderFilterDialogState();
}

class _OrderFilterDialogState extends State<_OrderFilterDialog> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  late final TextEditingController _minAmountController;
  late final TextEditingController _maxAmountController;

  String? _state;
  bool? _hasDiscount;
  DateTime? _minOrderDate;
  DateTime? _maxOrderDate;
  DateTime? _minShippingDate;
  DateTime? _maxShippingDate;

  @override
  void initState() {
    super.initState();
    final initial = widget.initial;
    _state = initial.state;
    _hasDiscount = initial.hasDiscount;
    _minOrderDate = initial.minOrderDate;
    _maxOrderDate = initial.maxOrderDate;
    _minShippingDate = initial.minShippingDate;
    _maxShippingDate = initial.maxShippingDate;
    _minAmountController = TextEditingController(
      text: initial.minTotalAmount?.toStringAsFixed(2) ?? '',
    );
    _maxAmountController = TextEditingController(
      text: initial.maxTotalAmount?.toStringAsFixed(2) ?? '',
    );
  }

  @override
  void dispose() {
    _minAmountController.dispose();
    _maxAmountController.dispose();
    super.dispose();
  }

  Future<void> _pickDate(_DateFilter field) async {
    final current = switch (field) {
      _DateFilter.minOrder => _minOrderDate,
      _DateFilter.maxOrder => _maxOrderDate,
      _DateFilter.minShipping => _minShippingDate,
      _DateFilter.maxShipping => _maxShippingDate,
    };

    final firstDate = switch (field) {
      _DateFilter.maxOrder => _minOrderDate ?? DateTime(2000),
      _DateFilter.maxShipping => _minShippingDate ?? DateTime(2000),
      _ => DateTime(2000),
    };

    final selected = await showDatePicker(
      context: context,
      initialDate: current ?? firstDate,
      firstDate: firstDate,
      lastDate: DateTime(2100),
      cancelText: 'Odustani',
      confirmText: 'Odaberi',
    );

    if (selected == null || !mounted) return;

    setState(() {
      switch (field) {
        case _DateFilter.minOrder:
          _minOrderDate = selected;
          if (_maxOrderDate != null && _maxOrderDate!.isBefore(selected)) {
            _maxOrderDate = null;
          }
          break;
        case _DateFilter.maxOrder:
          _maxOrderDate = selected;
          break;
        case _DateFilter.minShipping:
          _minShippingDate = selected;
          if (_maxShippingDate != null &&
              _maxShippingDate!.isBefore(selected)) {
            _maxShippingDate = null;
          }
          break;
        case _DateFilter.maxShipping:
          _maxShippingDate = selected;
          break;
      }
    });
  }

  void _apply() {
    if (!_formKey.currentState!.validate()) return;

    final minAmount = _parseAmount(_minAmountController.text);
    final maxAmount = _parseAmount(_maxAmountController.text);

    if (minAmount != null && maxAmount != null && minAmount > maxAmount) {
      _showError('Minimalni iznos ne može biti veći od maksimalnog.');
      return;
    }

    Navigator.pop(
      context,
      _OrderFilters(
        state: _state,
        hasDiscount: _hasDiscount,
        minTotalAmount: minAmount,
        maxTotalAmount: maxAmount,
        minOrderDate: _minOrderDate,
        maxOrderDate: _maxOrderDate,
        minShippingDate: _minShippingDate,
        maxShippingDate: _maxShippingDate,
      ),
    );
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: const Color(0xFFB3261E),
      ),
    );
  }

  double? _parseAmount(String value) {
    final normalized = value.trim().replaceAll(',', '.');
    return normalized.isEmpty ? null : double.tryParse(normalized);
  }

  String? _amountValidator(String? value) {
    if (value == null || value.trim().isEmpty) return null;
    final amount = _parseAmount(value);
    if (amount == null) return 'Unesite ispravan iznos.';
    if (amount < 0) return 'Iznos ne može biti negativan.';
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Filteri narudžbi'),
      content: SizedBox(
        width: 680,
        child: SingleChildScrollView(
          child: Form(
            key: _formKey,
            child: Column(
              children: [
                Wrap(
                  spacing: AppPadding.medium,
                  runSpacing: AppPadding.medium,
                  children: [
                    SizedBox(
                      width: 310,
                      child: DropdownButtonFormField<String?>(
                        initialValue: _state,
                        decoration: const InputDecoration(labelText: 'Status'),
                        items: const [
                          DropdownMenuItem(
                            value: null,
                            child: Text('Svi statusi'),
                          ),
                          DropdownMenuItem(
                            value: 'onhold',
                            child: Text('Na čekanju'),
                          ),
                          DropdownMenuItem(
                            value: 'accepted',
                            child: Text('Prihvaćene'),
                          ),
                          DropdownMenuItem(
                            value: 'completed',
                            child: Text('Završene'),
                          ),
                          DropdownMenuItem(
                            value: 'rejected',
                            child: Text('Odbijene'),
                          ),
                          DropdownMenuItem(
                            value: 'cancelled',
                            child: Text('Otkazane'),
                          ),
                          DropdownMenuItem(
                            value: 'missingpayment',
                            child: Text('Nedostaje uplata'),
                          ),
                          DropdownMenuItem(
                            value: 'paymentfailed',
                            child: Text('Plaćanje neuspješno'),
                          ),
                        ],
                        onChanged: (value) => setState(() => _state = value),
                      ),
                    ),
                    SizedBox(
                      width: 310,
                      child: DropdownButtonFormField<bool?>(
                        initialValue: _hasDiscount,
                        decoration: const InputDecoration(labelText: 'Popust'),
                        items: const [
                          DropdownMenuItem(
                            value: null,
                            child: Text('Sve narudžbe'),
                          ),
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
                            setState(() => _hasDiscount = value),
                      ),
                    ),
                    _amountField(
                      controller: _minAmountController,
                      label: 'Minimalni iznos (€)',
                    ),
                    _amountField(
                      controller: _maxAmountController,
                      label: 'Maksimalni iznos (€)',
                    ),
                  ],
                ),
                const SizedBox(height: AppPadding.large),
                _DateRangeSection(
                  title: 'Period narudžbe',
                  startDate: _minOrderDate,
                  endDate: _maxOrderDate,
                  onStartPressed: () => _pickDate(_DateFilter.minOrder),
                  onEndPressed: () => _pickDate(_DateFilter.maxOrder),
                  onStartClear: () => setState(() {
                    _minOrderDate = null;
                    _maxOrderDate = null;
                  }),
                  onEndClear: () => setState(() => _maxOrderDate = null),
                ),
                const SizedBox(height: AppPadding.medium),
                _DateRangeSection(
                  title: 'Period dostave',
                  startDate: _minShippingDate,
                  endDate: _maxShippingDate,
                  onStartPressed: () => _pickDate(_DateFilter.minShipping),
                  onEndPressed: () => _pickDate(_DateFilter.maxShipping),
                  onStartClear: () => setState(() {
                    _minShippingDate = null;
                    _maxShippingDate = null;
                  }),
                  onEndClear: () => setState(() => _maxShippingDate = null),
                ),
              ],
            ),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, const _OrderFilters()),
          child: const Text('Poništi filtere'),
        ),
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Odustani'),
        ),
        FilledButton(onPressed: _apply, child: const Text('Primijeni')),
      ],
    );
  }

  Widget _amountField({
    required TextEditingController controller,
    required String label,
  }) {
    return SizedBox(
      width: 310,
      child: TextFormField(
        controller: controller,
        validator: _amountValidator,
        keyboardType: const TextInputType.numberWithOptions(decimal: true),
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: const Icon(Icons.euro),
        ),
      ),
    );
  }
}

class _DateRangeSection extends StatelessWidget {
  const _DateRangeSection({
    required this.title,
    required this.startDate,
    required this.endDate,
    required this.onStartPressed,
    required this.onEndPressed,
    required this.onStartClear,
    required this.onEndClear,
  });

  final String title;
  final DateTime? startDate;
  final DateTime? endDate;
  final VoidCallback onStartPressed;
  final VoidCallback onEndPressed;
  final VoidCallback onStartClear;
  final VoidCallback onEndClear;

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      color: const Color(0xFFF7F9FC),
      child: Padding(
        padding: const EdgeInsets.all(AppPadding.medium),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: const TextStyle(fontWeight: FontWeight.w700)),
            const SizedBox(height: AppPadding.small),
            Row(
              children: [
                Expanded(
                  child: _DateButton(
                    label: 'Od',
                    date: startDate,
                    onPressed: onStartPressed,
                    onClear: onStartClear,
                  ),
                ),
                const SizedBox(width: AppPadding.medium),
                Expanded(
                  child: _DateButton(
                    label: 'Do',
                    date: endDate,
                    onPressed: onEndPressed,
                    onClear: onEndClear,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _DateButton extends StatelessWidget {
  const _DateButton({
    required this.label,
    required this.date,
    required this.onPressed,
    required this.onClear,
  });

  final String label;
  final DateTime? date;
  final VoidCallback onPressed;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: OutlinedButton.icon(
            onPressed: onPressed,
            icon: const Icon(Icons.calendar_month_outlined),
            label: Text(
              '$label: ${date == null ? 'Nije odabrano' : _formatDate(date!)}',
            ),
          ),
        ),
        if (date != null)
          IconButton(
            tooltip: 'Poništi datum',
            onPressed: onClear,
            icon: const Icon(Icons.close),
          ),
      ],
    );
  }
}

class _LoadError extends StatelessWidget {
  const _LoadError({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Card(
        margin: const EdgeInsets.all(AppPadding.large),
        child: Padding(
          padding: const EdgeInsets.all(AppPadding.extraLarge),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.error_outline,
                size: 52,
                color: Color(0xFFB3261E),
              ),
              const SizedBox(height: AppPadding.medium),
              Text(message, textAlign: TextAlign.center),
              const SizedBox(height: AppPadding.large),
              FilledButton.icon(
                onPressed: onRetry,
                icon: const Icon(Icons.refresh),
                label: const Text('Pokušaj ponovo'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _EmptyOrders extends StatelessWidget {
  const _EmptyOrders();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.receipt_long_outlined, size: 56, color: Color(0xFF7A8493)),
          SizedBox(height: AppPadding.medium),
          Text('Nema pronađenih narudžbi.'),
        ],
      ),
    );
  }
}

enum _OrderAction { accept, reject, cancel, complete, deleteHistory }

enum _DateFilter { minOrder, maxOrder, minShipping, maxShipping }

class _ActionConfiguration {
  const _ActionConfiguration({
    required this.title,
    required this.message,
    required this.confirmLabel,
    required this.successMessage,
  });

  final String title;
  final String message;
  final String confirmLabel;
  final String successMessage;
}

class _StatusColors {
  const _StatusColors(this.background, this.foreground);

  final Color background;
  final Color foreground;
}

List<_OrderAction> _actionsForState(String state) {
  switch (state.toLowerCase()) {
    case 'onhold':
      return const [
        _OrderAction.accept,
        _OrderAction.reject,
        _OrderAction.cancel,
      ];
    case 'accepted':
      return const [_OrderAction.complete];
    case 'completed':
    case 'rejected':
    case 'cancelled':
    case 'missingpayment':
    case 'paymentfailed':
      return const [_OrderAction.deleteHistory];
    default:
      return const [];
  }
}

String _actionLabel(_OrderAction action) {
  switch (action) {
    case _OrderAction.accept:
      return 'Prihvati';
    case _OrderAction.reject:
      return 'Odbij';
    case _OrderAction.cancel:
      return 'Otkaži';
    case _OrderAction.complete:
      return 'Označi završenom';
    case _OrderAction.deleteHistory:
      return 'Ukloni iz historije';
  }
}

IconData _actionIcon(_OrderAction action) {
  switch (action) {
    case _OrderAction.accept:
      return Icons.check_circle_outline;
    case _OrderAction.reject:
      return Icons.block_outlined;
    case _OrderAction.cancel:
      return Icons.cancel_outlined;
    case _OrderAction.complete:
      return Icons.task_alt;
    case _OrderAction.deleteHistory:
      return Icons.delete_outline;
  }
}

String _stateLabel(String state) {
  switch (state.toLowerCase()) {
    case 'initial':
      return 'Početna';
    case 'missingpayment':
      return 'Nedostaje uplata';
    case 'onhold':
      return 'Na čekanju';
    case 'accepted':
      return 'Prihvaćena';
    case 'rejected':
      return 'Odbijena';
    case 'cancelled':
      return 'Otkazana';
    case 'paymentfailed':
      return 'Plaćanje neuspješno';
    case 'completed':
      return 'Završena';
    default:
      return state;
  }
}

_StatusColors _statusColors(String state) {
  switch (state.toLowerCase()) {
    case 'onhold':
      return const _StatusColors(Color(0xFFE8F0FF), Color(0xFF2848C7));
    case 'accepted':
      return const _StatusColors(Color(0xFFFFF3D6), Color(0xFF8A5A00));
    case 'completed':
      return const _StatusColors(Color(0xFFE7F6EC), Color(0xFF1B7F3A));
    case 'rejected':
    case 'cancelled':
    case 'paymentfailed':
      return const _StatusColors(Color(0xFFFDECEB), Color(0xFFB3261E));
    case 'missingpayment':
      return const _StatusColors(Color(0xFFFFF0E2), Color(0xFF9A4A00));
    default:
      return const _StatusColors(Color(0xFFF0F2F5), Color(0xFF4F5968));
  }
}

String _formatDate(DateTime value) {
  final local = value.toLocal();
  return '${_twoDigits(local.day)}.${_twoDigits(local.month)}.${local.year}.';
}

String _formatDateTime(DateTime value) {
  final local = value.toLocal();
  return '${_formatDate(local)} ${_twoDigits(local.hour)}:${_twoDigits(local.minute)}';
}

String _twoDigits(int value) => value.toString().padLeft(2, '0');

String? _emptyToNull(String value) {
  final trimmed = value.trim();
  return trimmed.isEmpty ? null : trimmed;
}

DateTime? _endOfDay(DateTime? value) {
  if (value == null) return null;
  return DateTime(value.year, value.month, value.day, 23, 59, 59, 999);
}
