import 'dart:convert';
import 'dart:typed_data';

import 'package:eautoshop_desktop/constants.dart';
import 'package:eautoshop_desktop/models/auto_shop_service/auto_shop_service.dart';
import 'package:eautoshop_desktop/models/auto_shop_service/auto_shop_service_insert_update.dart';
import 'package:eautoshop_desktop/models/auto_shop_service/auto_shop_service_search_object.dart';
import 'package:eautoshop_desktop/providers/auto_shop_service_provider.dart';
import 'package:eautoshop_desktop/providers/service_type_provider.dart';
import 'package:eautoshop_desktop/utilities/custom_exception.dart';
import 'package:file_selector/file_selector.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class ServiceScreen extends StatefulWidget {
  const ServiceScreen({super.key});

  @override
  State<ServiceScreen> createState() => _ServiceScreenState();
}

class _ServiceScreenState extends State<ServiceScreen> {
  static const Color _primaryBlue = Color(0xFF2848C7);
  static const int _pageSize = 9;

  final TextEditingController _searchController = TextEditingController();

  int _page = 1;
  int? _serviceTypeId;
  String? _state;
  bool? _withDiscount;
  bool _initialLoading = true;
  String? _loadError;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadInitialData());
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadInitialData() async {
    setState(() {
      _initialLoading = true;
      _loadError = null;
    });

    try {
      await Future.wait([
        _loadServices(),
        context.read<ServiceTypeProvider>().getTypes(),
      ]);
    } on CustomException catch (error) {
      _loadError = error.message;
    } catch (_) {
      _loadError = 'Podaci o uslugama nisu mogli biti učitani.';
    }

    if (mounted) setState(() => _initialLoading = false);
  }

  Future<void> _loadServices({bool resetPage = false}) async {
    if (resetPage) _page = 1;

    await context.read<AutoShopServiceProvider>().getServices(
      page: _page,
      pageSize: _pageSize,
      search: AutoShopServiceSearchObject(
        serviceTypeId: _serviceTypeId,
        name: _emptyToNull(_searchController.text),
        withDiscount: _withDiscount,
        state: _state,
      ),
    );
  }

  Future<void> _search() async {
    try {
      await _loadServices(resetPage: true);
    } on CustomException catch (error) {
      _showMessage(error.message, isError: true);
    }
  }

  Future<void> _clearSearch() async {
    _searchController.clear();
    setState(() {});
    await _search();
  }

  Future<void> _openFilters() async {
    final result = await showDialog<_ServiceFilters>(
      context: context,
      builder: (_) => _ServiceFilterDialog(
        initial: _ServiceFilters(
          serviceTypeId: _serviceTypeId,
          state: _state,
          withDiscount: _withDiscount,
        ),
      ),
    );

    if (result == null || !mounted) return;

    setState(() {
      _serviceTypeId = result.serviceTypeId;
      _state = result.state;
      _withDiscount = result.withDiscount;
    });

    await _search();
  }

  Future<void> _openServiceDialog([AutoShopService? service]) async {
    if (context.read<ServiceTypeProvider>().types.isEmpty) {
      _showMessage(
        'Nema dostupnih vrsta usluga. Uslugu nije moguće dodati.',
        isError: true,
      );
      return;
    }

    final saved = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (_) => _ServiceDialog(service: service),
    );

    if (saved == true && mounted) {
      await _loadServices();
      _showMessage(
        service == null
            ? 'Usluga je uspješno dodana.'
            : 'Usluga je uspješno ažurirana.',
      );
    }
  }

  Future<void> _deleteService(AutoShopService service) async {
    final confirmed = await _confirm(
      title: 'Brisanje usluge',
      message: 'Da li želite obrisati uslugu „${service.name}“?',
      confirmLabel: 'Obriši',
    );
    if (!confirmed || !mounted) return;

    try {
      final provider = context.read<AutoShopServiceProvider>();
      await provider.deleteService(service.id);

      if (_page > 1 && provider.services.length == 1) _page--;

      await _loadServices();
      _showMessage('Usluga je obrisana.');
    } on CustomException catch (error) {
      _showMessage(error.message, isError: true);
    }
  }

  Future<void> _changeState(
    AutoShopService service, {
    required bool activate,
  }) async {
    final confirmed = await _confirm(
      title: activate ? 'Aktivacija usluge' : 'Sakrivanje usluge',
      message: activate
          ? 'Da li želite aktivirati uslugu „${service.name}“?'
          : 'Da li želite sakriti uslugu „${service.name}“?',
      confirmLabel: activate ? 'Aktiviraj' : 'Sakrij',
    );
    if (!confirmed || !mounted) return;

    try {
      final provider = context.read<AutoShopServiceProvider>();
      if (activate) {
        await provider.activateService(service.id);
      } else {
        await provider.hideService(service.id);
      }

      await _loadServices();
      _showMessage(activate ? 'Usluga je aktivirana.' : 'Usluga je sakrivena.');
    } on CustomException catch (error) {
      _showMessage(error.message, isError: true);
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

  String? _emptyToNull(String value) {
    final trimmed = value.trim();
    return trimmed.isEmpty ? null : trimmed;
  }

  int _totalPages(int count) {
    final pages = (count / _pageSize).ceil();
    return pages < 1 ? 1 : pages;
  }

  bool get _hasFilters =>
      _serviceTypeId != null || _state != null || _withDiscount != null;

  @override
  Widget build(BuildContext context) {
    if (_initialLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_loadError != null) {
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
                Text(_loadError!, textAlign: TextAlign.center),
                const SizedBox(height: AppPadding.large),
                FilledButton.icon(
                  onPressed: _loadInitialData,
                  icon: const Icon(Icons.refresh),
                  label: const Text('Pokušaj ponovo'),
                ),
              ],
            ),
          ),
        ),
      );
    }

    final provider = context.watch<AutoShopServiceProvider>();
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
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppRadius.card),
                side: const BorderSide(color: Color(0xFFE2E7F0)),
              ),
              child: provider.isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : provider.services.isEmpty
                  ? const _EmptyServices()
                  : GridView.builder(
                      padding: const EdgeInsets.all(AppPadding.medium),
                      gridDelegate:
                          const SliverGridDelegateWithMaxCrossAxisExtent(
                            maxCrossAxisExtent: 350,
                            mainAxisExtent: 410,
                            crossAxisSpacing: AppPadding.medium,
                            mainAxisSpacing: AppPadding.medium,
                          ),
                      itemCount: provider.services.length,
                      itemBuilder: (context, index) {
                        final service = provider.services[index];
                        return _ServiceCard(
                          service: service,
                          onDetails: () =>
                              _showServiceDetails(context, service),
                          onEdit: () => _openServiceDialog(service),
                          onDelete: () => _deleteService(service),
                          onActivate: () =>
                              _changeState(service, activate: true),
                          onHide: () => _changeState(service, activate: false),
                        );
                      },
                    ),
            ),
          ),
          const SizedBox(height: AppPadding.small),
          _buildPagination(provider, totalPages),
        ],
      ),
    );
  }

  Widget _buildToolbar(AutoShopServiceProvider provider) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final searchWidth = constraints.maxWidth < 760
            ? constraints.maxWidth
            : 350.0;

        return Wrap(
          spacing: AppPadding.small,
          runSpacing: AppPadding.small,
          alignment: WrapAlignment.start,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            SizedBox(
              width: searchWidth,
              child: TextField(
                controller: _searchController,
                onSubmitted: (_) => _search(),
                onChanged: (_) => setState(() {}),
                decoration: InputDecoration(
                  hintText: 'Pretraga usluga po nazivu',
                  prefixIcon: const Icon(Icons.search),
                  suffixIcon: _searchController.text.isEmpty
                      ? null
                      : IconButton(
                          tooltip: 'Poništi pretragu',
                          onPressed: _clearSearch,
                          icon: const Icon(Icons.close),
                        ),
                ),
              ),
            ),
            FilledButton.icon(
              onPressed: provider.isLoading ? null : _search,
              icon: const Icon(Icons.search),
              label: const Text('Pretraži'),
              style: FilledButton.styleFrom(minimumSize: const Size(120, 52)),
            ),
            Badge(
              isLabelVisible: _hasFilters,
              child: OutlinedButton.icon(
                onPressed: provider.isLoading ? null : _openFilters,
                icon: const Icon(Icons.tune),
                label: const Text('Filteri'),
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size(120, 52),
                ),
              ),
            ),
            FilledButton.icon(
              onPressed: provider.isLoading ? null : _openServiceDialog,
              icon: const Icon(Icons.add),
              label: const Text('Dodaj uslugu'),
              style: FilledButton.styleFrom(
                minimumSize: const Size(160, 52),
                backgroundColor: _primaryBlue,
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildPagination(AutoShopServiceProvider provider, int totalPages) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        IconButton(
          tooltip: 'Prethodna stranica',
          onPressed: !provider.isLoading && _page > 1
              ? () async {
                  setState(() => _page--);
                  await _loadServices();
                }
              : null,
          icon: const Icon(Icons.chevron_left),
        ),
        Text('Stranica $_page od $totalPages'),
        IconButton(
          tooltip: 'Sljedeća stranica',
          onPressed: !provider.isLoading && _page < totalPages
              ? () async {
                  setState(() => _page++);
                  await _loadServices();
                }
              : null,
          icon: const Icon(Icons.chevron_right),
        ),
      ],
    );
  }
}

class _ServiceCard extends StatelessWidget {
  const _ServiceCard({
    required this.service,
    required this.onDetails,
    required this.onEdit,
    required this.onDelete,
    required this.onActivate,
    required this.onHide,
  });

  final AutoShopService service;
  final VoidCallback onDetails;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final VoidCallback onActivate;
  final VoidCallback onHide;

  @override
  Widget build(BuildContext context) {
    final state = service.state.toLowerCase();

    return Card(
      margin: EdgeInsets.zero,
      elevation: 1,
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.card),
        side: const BorderSide(color: Color(0xFFE2E7F0)),
      ),
      child: InkWell(
        onTap: onDetails,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(child: _ServiceImage(imageData: service.imageData)),
            Padding(
              padding: const EdgeInsets.all(AppPadding.medium),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          service.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      _ServiceStatusChip(state: state),
                    ],
                  ),
                  const SizedBox(height: AppPadding.small),
                  Text(
                    service.serviceTypeName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(color: Color(0xFF687385)),
                  ),
                  const SizedBox(height: AppPadding.small),
                  _ServicePrice(service: service),
                  const SizedBox(height: AppPadding.small),
                  Row(
                    children: [
                      const Icon(
                        Icons.schedule_outlined,
                        size: 18,
                        color: Color(0xFF687385),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        _formatDuration(service.duration),
                        style: const TextStyle(color: Color(0xFF687385)),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppPadding.small),
                  Row(
                    children: [
                      TextButton.icon(
                        onPressed: onDetails,
                        icon: const Icon(Icons.visibility_outlined),
                        label: const Text('Detalji'),
                      ),
                      const Spacer(),
                      PopupMenuButton<_ServiceAction>(
                        tooltip: 'Akcije',
                        onSelected: (action) {
                          switch (action) {
                            case _ServiceAction.edit:
                              onEdit();
                              break;
                            case _ServiceAction.delete:
                              onDelete();
                              break;
                            case _ServiceAction.activate:
                              onActivate();
                              break;
                            case _ServiceAction.hide:
                              onHide();
                              break;
                          }
                        },
                        itemBuilder: (_) {
                          if (state == 'draft') {
                            return const [
                              PopupMenuItem(
                                value: _ServiceAction.edit,
                                child: Text('Uredi'),
                              ),
                              PopupMenuItem(
                                value: _ServiceAction.activate,
                                child: Text('Aktiviraj'),
                              ),
                              PopupMenuItem(
                                value: _ServiceAction.delete,
                                child: Text('Obriši'),
                              ),
                            ];
                          }
                          if (state == 'active') {
                            return const [
                              PopupMenuItem(
                                value: _ServiceAction.hide,
                                child: Text('Sakrij'),
                              ),
                            ];
                          }
                          return const [
                            PopupMenuItem(
                              value: _ServiceAction.edit,
                              child: Text('Uredi'),
                            ),
                            PopupMenuItem(
                              value: _ServiceAction.activate,
                              child: Text('Aktiviraj'),
                            ),
                          ];
                        },
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

enum _ServiceAction { edit, delete, activate, hide }

class _ServiceImage extends StatelessWidget {
  const _ServiceImage({this.imageData});

  final String? imageData;

  @override
  Widget build(BuildContext context) {
    final bytes = _decodeBase64(imageData);
    if (bytes == null) {
      return const ColoredBox(
        color: Color(0xFFF0F3F8),
        child: Center(
          child: Icon(Icons.build_outlined, size: 72, color: Color(0xFF8B95A5)),
        ),
      );
    }

    return Image.memory(
      bytes,
      fit: BoxFit.cover,
      errorBuilder: (_, _, _) => const ColoredBox(
        color: Color(0xFFF0F3F8),
        child: Center(child: Icon(Icons.broken_image_outlined, size: 60)),
      ),
    );
  }
}

class _ServicePrice extends StatelessWidget {
  const _ServicePrice({required this.service});

  final AutoShopService service;

  @override
  Widget build(BuildContext context) {
    if (service.discount <= 0) {
      return Text(
        '${service.price.toStringAsFixed(2)} €',
        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
      );
    }

    return Row(
      children: [
        Text(
          '${service.price.toStringAsFixed(2)} €',
          style: const TextStyle(
            color: Color(0xFF8B95A5),
            decoration: TextDecoration.lineThrough,
          ),
        ),
        const SizedBox(width: AppPadding.small),
        Text(
          '${service.discountedPrice.toStringAsFixed(2)} €',
          style: const TextStyle(
            color: Color(0xFF1B7F3A),
            fontSize: 18,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }
}

class _ServiceStatusChip extends StatelessWidget {
  const _ServiceStatusChip({required this.state});

  final String state;

  @override
  Widget build(BuildContext context) {
    final (label, background, foreground) = switch (state) {
      'active' => ('Aktivna', const Color(0xFFE7F6EC), const Color(0xFF1B7F3A)),
      'hidden' => (
        'Sakrivena',
        const Color(0xFFF0F1F3),
        const Color(0xFF586170),
      ),
      _ => ('Nacrt', const Color(0xFFFFF3D6), const Color(0xFF8A5A00)),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: foreground,
          fontWeight: FontWeight.w600,
          fontSize: 12,
        ),
      ),
    );
  }
}

class _ServiceFilters {
  const _ServiceFilters({this.serviceTypeId, this.state, this.withDiscount});

  final int? serviceTypeId;
  final String? state;
  final bool? withDiscount;
}

class _ServiceFilterDialog extends StatefulWidget {
  const _ServiceFilterDialog({required this.initial});

  final _ServiceFilters initial;

  @override
  State<_ServiceFilterDialog> createState() => _ServiceFilterDialogState();
}

class _ServiceFilterDialogState extends State<_ServiceFilterDialog> {
  int? _serviceTypeId;
  String? _state;
  bool? _withDiscount;

  @override
  void initState() {
    super.initState();
    _serviceTypeId = widget.initial.serviceTypeId;
    _state = widget.initial.state;
    _withDiscount = widget.initial.withDiscount;
  }

  @override
  Widget build(BuildContext context) {
    final types = context.watch<ServiceTypeProvider>().types;

    return AlertDialog(
      title: const Text('Filteri usluga'),
      content: SizedBox(
        width: 520,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            DropdownButtonFormField<int?>(
              initialValue: _serviceTypeId,
              decoration: const InputDecoration(labelText: 'Vrsta usluge'),
              items: [
                const DropdownMenuItem(
                  value: null,
                  child: Text('Sve vrste usluga'),
                ),
                ...types.map(
                  (type) =>
                      DropdownMenuItem(value: type.id, child: Text(type.name)),
                ),
              ],
              onChanged: (value) => setState(() => _serviceTypeId = value),
            ),
            const SizedBox(height: AppPadding.medium),
            DropdownButtonFormField<String?>(
              initialValue: _state,
              decoration: const InputDecoration(labelText: 'Status'),
              items: const [
                DropdownMenuItem(value: null, child: Text('Svi statusi')),
                DropdownMenuItem(value: 'draft', child: Text('Nacrti')),
                DropdownMenuItem(value: 'active', child: Text('Aktivne')),
                DropdownMenuItem(value: 'hidden', child: Text('Sakrivene')),
              ],
              onChanged: (value) => setState(() => _state = value),
            ),
            const SizedBox(height: AppPadding.medium),
            DropdownButtonFormField<bool?>(
              initialValue: _withDiscount,
              decoration: const InputDecoration(labelText: 'Popust'),
              items: const [
                DropdownMenuItem(value: null, child: Text('Sve usluge')),
                DropdownMenuItem(value: true, child: Text('Sa popustom')),
                DropdownMenuItem(value: false, child: Text('Bez popusta')),
              ],
              onChanged: (value) => setState(() => _withDiscount = value),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, const _ServiceFilters()),
          child: const Text('Poništi filtere'),
        ),
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Odustani'),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(
            context,
            _ServiceFilters(
              serviceTypeId: _serviceTypeId,
              state: _state,
              withDiscount: _withDiscount,
            ),
          ),
          child: const Text('Primijeni'),
        ),
      ],
    );
  }
}

class _ServiceDialog extends StatefulWidget {
  const _ServiceDialog({this.service});

  final AutoShopService? service;

  @override
  State<_ServiceDialog> createState() => _ServiceDialogState();
}

class _ServiceDialogState extends State<_ServiceDialog> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  late final TextEditingController _nameController;
  late final TextEditingController _priceController;
  late final TextEditingController _discountController;
  late final TextEditingController _durationController;
  late final TextEditingController _descriptionController;
  late final TextEditingController _detailsController;

  int? _serviceTypeId;
  String? _base64Image;
  bool _saving = false;

  bool get _isEditing => widget.service != null;

  @override
  void initState() {
    super.initState();
    final service = widget.service;
    _nameController = TextEditingController(text: service?.name ?? '');
    _priceController = TextEditingController(
      text: service == null ? '' : service.price.toStringAsFixed(2),
    );
    _discountController = TextEditingController(
      text: service == null ? '0' : (service.discount * 100).toStringAsFixed(0),
    );
    _durationController = TextEditingController(
      text: service == null ? '01:00' : _durationForInput(service.duration),
    );
    _descriptionController = TextEditingController(
      text: service?.description ?? '',
    );
    _detailsController = TextEditingController(text: service?.details ?? '');
    _serviceTypeId = service?.serviceTypeId;
    _base64Image = service?.imageData;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _priceController.dispose();
    _discountController.dispose();
    _durationController.dispose();
    _descriptionController.dispose();
    _detailsController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    const imageTypes = XTypeGroup(
      label: 'Slike',
      extensions: ['jpg', 'jpeg', 'png', 'webp'],
    );
    final file = await openFile(acceptedTypeGroups: [imageTypes]);
    if (file == null) return;

    try {
      final bytes = await file.readAsBytes();
      if (mounted) setState(() => _base64Image = base64Encode(bytes));
    } catch (_) {
      _showError('Odabrana slika nije mogla biti učitana.');
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _saving = true);
    try {
      final request = AutoShopServiceInsertUpdate(
        serviceTypeId: _serviceTypeId,
        name: _nameController.text.trim(),
        price: _parseNumber(_priceController.text),
        discount: _parseNumber(_discountController.text)! / 100,
        imageData: _base64Image,
        description: _descriptionController.text.trim(),
        details: _emptyToNull(_detailsController.text),
        duration: _durationForApi(_durationController.text),
      );

      final provider = context.read<AutoShopServiceProvider>();
      if (_isEditing) {
        await provider.updateService(id: widget.service!.id, request: request);
      } else {
        await provider.insertService(request);
      }

      if (mounted) Navigator.pop(context, true);
    } on CustomException catch (error) {
      _showError(error.message);
    } catch (_) {
      _showError('Spremanje usluge nije uspjelo.');
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  void _showError(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: const Color(0xFFB3261E),
      ),
    );
  }

  double? _parseNumber(String value) =>
      double.tryParse(value.trim().replaceAll(',', '.'));

  String? _emptyToNull(String value) {
    final trimmed = value.trim();
    return trimmed.isEmpty ? null : trimmed;
  }

  String? _requiredText(String? value, String field) {
    return value == null || value.trim().isEmpty ? 'Unesite $field.' : null;
  }

  String? _priceValidator(String? value) {
    final price = _parseNumber(value ?? '');
    if (price == null) return 'Unesite ispravnu cijenu.';
    if (price <= 0) return 'Cijena mora biti veća od nule.';
    return null;
  }

  String? _discountValidator(String? value) {
    final discount = _parseNumber(value ?? '');
    if (discount == null) return 'Unesite ispravan popust.';
    if (discount < 0 || discount > 100) {
      return 'Popust mora biti između 0 i 100%.';
    }
    return null;
  }

  String? _durationValidator(String? value) {
    final match = RegExp(
      r'^(\d{1,2}):([0-5]\d)$',
    ).firstMatch(value?.trim() ?? '');
    if (match == null) return 'Unesite trajanje u formatu HH:mm.';

    final hours = int.parse(match.group(1)!);
    final minutes = int.parse(match.group(2)!);
    if (hours > 23) return 'Trajanje ne može biti duže od 23:59.';
    if (hours == 0 && minutes == 0) return 'Trajanje mora biti veće od nule.';
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final types = context.watch<ServiceTypeProvider>().types;

    return AlertDialog(
      title: Text(_isEditing ? 'Uredi uslugu' : 'Dodaj uslugu'),
      content: SizedBox(
        width: 760,
        child: SingleChildScrollView(
          child: Form(
            key: _formKey,
            child: Column(
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(
                      width: 220,
                      height: 180,
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(AppRadius.card),
                        child: _ServiceImage(imageData: _base64Image),
                      ),
                    ),
                    const SizedBox(width: AppPadding.large),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          OutlinedButton.icon(
                            onPressed: _saving ? null : _pickImage,
                            icon: const Icon(Icons.image_outlined),
                            label: Text(
                              _decodeBase64(_base64Image) == null
                                  ? 'Odaberi sliku'
                                  : 'Promijeni sliku',
                            ),
                          ),
                          if (_decodeBase64(_base64Image) != null)
                            TextButton(
                              onPressed: _saving
                                  ? null
                                  : () => setState(() => _base64Image = ''),
                              child: const Text('Ukloni sliku'),
                            ),
                          const SizedBox(height: AppPadding.small),
                          const Text(
                            'Slika nije obavezna. Podržani su JPG, PNG i WebP formati.',
                            style: TextStyle(color: Color(0xFF687385)),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppPadding.large),
                Wrap(
                  spacing: AppPadding.medium,
                  runSpacing: AppPadding.medium,
                  children: [
                    _dialogField(
                      controller: _nameController,
                      label: 'Naziv',
                      icon: Icons.build_outlined,
                      validator: (value) =>
                          _requiredText(value, 'naziv usluge'),
                    ),
                    SizedBox(
                      width: 340,
                      child: DropdownButtonFormField<int>(
                        initialValue: _serviceTypeId,
                        decoration: const InputDecoration(
                          labelText: 'Vrsta usluge',
                          prefixIcon: Icon(Icons.category_outlined),
                        ),
                        items: types
                            .map(
                              (type) => DropdownMenuItem(
                                value: type.id,
                                child: Text(type.name),
                              ),
                            )
                            .toList(),
                        onChanged: _saving
                            ? null
                            : (value) => setState(() => _serviceTypeId = value),
                        validator: (value) =>
                            value == null ? 'Odaberite vrstu usluge.' : null,
                      ),
                    ),
                    _dialogField(
                      controller: _priceController,
                      label: 'Cijena (€)',
                      icon: Icons.payments_outlined,
                      validator: _priceValidator,
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                    ),
                    _dialogField(
                      controller: _discountController,
                      label: 'Popust (%)',
                      icon: Icons.percent,
                      validator: _discountValidator,
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                    ),
                    _dialogField(
                      controller: _durationController,
                      label: 'Trajanje (HH:mm)',
                      icon: Icons.schedule_outlined,
                      validator: _durationValidator,
                      keyboardType: TextInputType.datetime,
                    ),
                  ],
                ),
                const SizedBox(height: AppPadding.medium),
                TextFormField(
                  controller: _descriptionController,
                  minLines: 3,
                  maxLines: 5,
                  validator: (value) => _requiredText(value, 'opis usluge'),
                  decoration: const InputDecoration(
                    labelText: 'Opis',
                    alignLabelWithHint: true,
                    prefixIcon: Icon(Icons.description_outlined),
                  ),
                ),
                const SizedBox(height: AppPadding.medium),
                TextFormField(
                  controller: _detailsController,
                  minLines: 2,
                  maxLines: 4,
                  decoration: const InputDecoration(
                    labelText: 'Dodatni detalji (nije obavezno)',
                    alignLabelWithHint: true,
                    prefixIcon: Icon(Icons.notes_outlined),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _saving ? null : () => Navigator.pop(context, false),
          child: const Text('Odustani'),
        ),
        FilledButton.icon(
          onPressed: _saving ? null : _save,
          icon: _saving
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Icon(Icons.save_outlined),
          label: Text(_saving ? 'Spremanje...' : 'Spremi'),
        ),
      ],
    );
  }

  Widget _dialogField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    required String? Function(String?) validator,
    TextInputType? keyboardType,
  }) {
    return SizedBox(
      width: 340,
      child: TextFormField(
        controller: controller,
        validator: validator,
        keyboardType: keyboardType,
        decoration: InputDecoration(labelText: label, prefixIcon: Icon(icon)),
      ),
    );
  }
}

class _EmptyServices extends StatelessWidget {
  const _EmptyServices();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.build_outlined, size: 56, color: Color(0xFF7A8493)),
          SizedBox(height: AppPadding.medium),
          Text('Nema pronađenih usluga.'),
        ],
      ),
    );
  }
}

void _showServiceDetails(BuildContext context, AutoShopService service) {
  showDialog<void>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      title: Text(service.name),
      content: SizedBox(
        width: 620,
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              SizedBox(
                height: 240,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(AppRadius.card),
                  child: _ServiceImage(imageData: service.imageData),
                ),
              ),
              const SizedBox(height: AppPadding.large),
              _ServiceDetailRow(
                label: 'Status',
                value: _stateLabel(service.state),
              ),
              _ServiceDetailRow(
                label: 'Vrsta usluge',
                value: service.serviceTypeName,
              ),
              _ServiceDetailRow(
                label: 'Cijena',
                value: '${service.price.toStringAsFixed(2)} €',
              ),
              if (service.discount > 0) ...[
                _ServiceDetailRow(
                  label: 'Popust',
                  value: '${(service.discount * 100).toStringAsFixed(0)}%',
                ),
                _ServiceDetailRow(
                  label: 'Cijena s popustom',
                  value: '${service.discountedPrice.toStringAsFixed(2)} €',
                ),
              ],
              _ServiceDetailRow(
                label: 'Trajanje',
                value: _formatDuration(service.duration),
              ),
              _ServiceDetailRow(label: 'Opis', value: service.description),
              _ServiceDetailRow(
                label: 'Dodatni detalji',
                value: service.details?.trim().isNotEmpty == true
                    ? service.details!
                    : 'Nisu navedeni',
              ),
            ],
          ),
        ),
      ),
      actions: [
        FilledButton(
          onPressed: () => Navigator.pop(dialogContext),
          child: const Text('Zatvori'),
        ),
      ],
    ),
  );
}

class _ServiceDetailRow extends StatelessWidget {
  const _ServiceDetailRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppPadding.small),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 170,
            child: Text(
              label,
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
          ),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }
}

String _stateLabel(String state) {
  return switch (state.toLowerCase()) {
    'active' => 'Aktivna',
    'hidden' => 'Sakrivena',
    _ => 'Nacrt',
  };
}

String _formatDuration(String value) {
  final parts = value.split(':');
  if (parts.length < 2) return value;

  final hours = int.tryParse(parts[0]) ?? 0;
  final minutes = int.tryParse(parts[1]) ?? 0;
  if (hours == 0) return '$minutes min';
  if (minutes == 0) return '$hours h';
  return '$hours h $minutes min';
}

String _durationForInput(String value) {
  final parts = value.split(':');
  if (parts.length < 2) return '01:00';
  return '${parts[0].padLeft(2, '0')}:${parts[1].padLeft(2, '0')}';
}

String _durationForApi(String value) {
  final parts = value.trim().split(':');
  final hours = int.parse(parts[0]);
  final minutes = int.parse(parts[1]);
  return '${hours.toString().padLeft(2, '0')}:${minutes.toString().padLeft(2, '0')}:00';
}

Uint8List? _decodeBase64(String? value) {
  if (value == null || value.trim().isEmpty) return null;
  try {
    return base64Decode(value.contains(',') ? value.split(',').last : value);
  } catch (_) {
    return null;
  }
}
