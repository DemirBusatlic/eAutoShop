import 'dart:convert';
import 'dart:typed_data';

import 'package:eautoshop_desktop/constants.dart';
import 'package:eautoshop_desktop/models/car_model/car_model.dart';
import 'package:eautoshop_desktop/models/car_model/car_models_by_manufacturer.dart';
import 'package:eautoshop_desktop/models/product/product.dart';
import 'package:eautoshop_desktop/models/product/product_insert_update.dart';
import 'package:eautoshop_desktop/providers/car_models_by_manufacturer_provider.dart';
import 'package:eautoshop_desktop/providers/product_category_provider.dart';
import 'package:eautoshop_desktop/providers/product_provider.dart';
import 'package:eautoshop_desktop/utilities/custom_exception.dart';
import 'package:file_selector/file_selector.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class ProductScreen extends StatefulWidget {
  const ProductScreen({super.key});

  @override
  State<ProductScreen> createState() => _ProductScreenState();
}

class _ProductScreenState extends State<ProductScreen> {
  static const Color _primaryBlue = Color(0xFF2848C7);
  static const int _pageSize = 9;

  final TextEditingController _searchController = TextEditingController();

  int _page = 1;
  String? _state;
  bool? _withDiscount;
  int? _productCategoryId;
  int? _carManufacturerId;
  List<int> _carModelIds = [];
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
        _loadProducts(),
        context.read<ProductCategoryProvider>().getCategories(),
        context
            .read<CarModelsByManufacturerProvider>()
            .getCarModelsByManufacturer(),
      ]);
    } on CustomException catch (error) {
      _loadError = error.message;
    } catch (_) {
      _loadError = 'Podaci o proizvodima nisu mogli biti učitani.';
    }

    if (mounted) setState(() => _initialLoading = false);
  }

  Future<void> _loadProducts({bool resetPage = false}) async {
    if (resetPage) _page = 1;

    await context.read<ProductProvider>().getProducts(
      page: _page,
      pageSize: _pageSize,
      name: _emptyToNull(_searchController.text),
      withDiscount: _withDiscount,
      state: _state,
      productCategoryId: _productCategoryId,
      carManufacturerId: _carManufacturerId,
      carModelIds: _carModelIds,
    );
  }

  Future<void> _search() async {
    try {
      await _loadProducts(resetPage: true);
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
    final result = await showDialog<_ProductFilters>(
      context: context,
      builder: (_) => _ProductFilterDialog(
        initial: _ProductFilters(
          state: _state,
          withDiscount: _withDiscount,
          productCategoryId: _productCategoryId,
          carManufacturerId: _carManufacturerId,
          carModelIds: _carModelIds,
        ),
      ),
    );

    if (result == null || !mounted) return;

    setState(() {
      _state = result.state;
      _withDiscount = result.withDiscount;
      _productCategoryId = result.productCategoryId;
      _carManufacturerId = result.carManufacturerId;
      _carModelIds = result.carModelIds;
    });

    await _search();
  }

  Future<void> _openProductDialog([Product? product]) async {
    final saved = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (_) => _ProductDialog(product: product),
    );

    if (saved == true && mounted) {
      await _loadProducts();
      _showMessage(
        product == null
            ? 'Proizvod je uspješno dodan.'
            : 'Proizvod je uspješno ažuriran.',
      );
    }
  }

  Future<void> _deleteProduct(Product product) async {
    final provider = context.read<ProductProvider>();

    final confirmed = await _confirm(
      title: 'Brisanje proizvoda',
      message: 'Da li želite obrisati proizvod „${product.name}“?',
      confirmLabel: 'Obriši',
    );
    if (!confirmed || !mounted) return;

    try {
      await provider.deleteProduct(product.id);
      if (_page > 1 && provider.products.length == 1) {
        _page--;
      }
      await _loadProducts();
      _showMessage('Proizvod je obrisan.');
    } on CustomException catch (error) {
      _showMessage(error.message, isError: true);
    }
  }

  Future<void> _changeState(Product product, {required bool activate}) async {
    final provider = context.read<ProductProvider>();
    final verb = activate ? 'aktivirati' : 'sakriti';
    final confirmed = await _confirm(
      title: activate ? 'Aktivacija proizvoda' : 'Sakrivanje proizvoda',
      message: 'Da li želite $verb proizvod „${product.name}“?',
      confirmLabel: activate ? 'Aktiviraj' : 'Sakrij',
    );
    if (!confirmed || !mounted) return;

    try {
      if (activate) {
        await provider.activateProduct(product.id);
      } else {
        await provider.hideProduct(product.id);
      }
      await _loadProducts();
      _showMessage(
        activate ? 'Proizvod je aktiviran.' : 'Proizvod je vraćen u nacrt.',
      );
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
      _state != null ||
      _withDiscount != null ||
      _productCategoryId != null ||
      _carManufacturerId != null ||
      _carModelIds.isNotEmpty;

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

    final provider = context.watch<ProductProvider>();
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
                  : provider.products.isEmpty
                  ? const _EmptyProducts()
                  : GridView.builder(
                      padding: const EdgeInsets.all(AppPadding.medium),
                      gridDelegate:
                          const SliverGridDelegateWithMaxCrossAxisExtent(
                            maxCrossAxisExtent: 330,
                            mainAxisExtent: 390,
                            crossAxisSpacing: AppPadding.medium,
                            mainAxisSpacing: AppPadding.medium,
                          ),
                      itemCount: provider.products.length,
                      itemBuilder: (context, index) {
                        final product = provider.products[index];
                        return _ProductCard(
                          product: product,
                          onDetails: () =>
                              _showProductDetails(context, product),
                          onEdit: () => _openProductDialog(product),
                          onDelete: () => _deleteProduct(product),
                          onActivate: () =>
                              _changeState(product, activate: true),
                          onHide: () => _changeState(product, activate: false),
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

  Widget _buildToolbar(ProductProvider provider) {
    return Row(
      children: [
        SizedBox(
          width: 350,
          child: TextField(
            controller: _searchController,
            onSubmitted: (_) => _search(),
            onChanged: (_) => setState(() {}),
            decoration: InputDecoration(
              hintText: 'Pretraga proizvoda po nazivu',
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
        const SizedBox(width: AppPadding.small),
        FilledButton.icon(
          onPressed: provider.isLoading ? null : _search,
          icon: const Icon(Icons.search),
          label: const Text('Pretraži'),
          style: FilledButton.styleFrom(minimumSize: const Size(120, 52)),
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
        FilledButton.icon(
          onPressed: provider.isLoading ? null : () => _openProductDialog(),
          icon: const Icon(Icons.add),
          label: const Text('Dodaj proizvod'),
          style: FilledButton.styleFrom(
            minimumSize: const Size(170, 52),
            backgroundColor: _primaryBlue,
          ),
        ),
      ],
    );
  }

  Widget _buildPagination(ProductProvider provider, int totalPages) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        IconButton(
          tooltip: 'Prethodna stranica',
          onPressed: !provider.isLoading && _page > 1
              ? () async {
                  setState(() => _page--);
                  await _loadProducts();
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
                  await _loadProducts();
                }
              : null,
          icon: const Icon(Icons.chevron_right),
        ),
      ],
    );
  }
}

class _ProductCard extends StatelessWidget {
  const _ProductCard({
    required this.product,
    required this.onDetails,
    required this.onEdit,
    required this.onDelete,
    required this.onActivate,
    required this.onHide,
  });

  final Product product;
  final VoidCallback onDetails;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final VoidCallback onActivate;
  final VoidCallback onHide;

  @override
  Widget build(BuildContext context) {
    final isDraft = product.state.toLowerCase() == 'draft';

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
            Expanded(child: _ProductImage(imageData: product.imageData)),
            Padding(
              padding: const EdgeInsets.all(AppPadding.medium),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          product.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      _ProductStatusChip(state: product.state),
                    ],
                  ),
                  const SizedBox(height: AppPadding.small),
                  Text(
                    product.category ?? 'Kategorija nije navedena',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(color: Color(0xFF687385)),
                  ),
                  const SizedBox(height: AppPadding.small),
                  _Price(product: product),
                  const SizedBox(height: AppPadding.small),
                  Text(
                    product.carModels?.isNotEmpty == true
                        ? product.carModels!
                              .map((model) => model.name)
                              .join(', ')
                        : 'Modeli vozila nisu navedeni',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(color: Color(0xFF687385)),
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
                      PopupMenuButton<_ProductAction>(
                        tooltip: 'Akcije',
                        onSelected: (action) {
                          switch (action) {
                            case _ProductAction.edit:
                              onEdit();
                              break;
                            case _ProductAction.delete:
                              onDelete();
                              break;
                            case _ProductAction.activate:
                              onActivate();
                              break;
                            case _ProductAction.hide:
                              onHide();
                              break;
                          }
                        },
                        itemBuilder: (_) => isDraft
                            ? const [
                                PopupMenuItem(
                                  value: _ProductAction.edit,
                                  child: Text('Uredi'),
                                ),
                                PopupMenuItem(
                                  value: _ProductAction.activate,
                                  child: Text('Aktiviraj'),
                                ),
                                PopupMenuItem(
                                  value: _ProductAction.delete,
                                  child: Text('Obriši'),
                                ),
                              ]
                            : const [
                                PopupMenuItem(
                                  value: _ProductAction.hide,
                                  child: Text('Sakrij'),
                                ),
                              ],
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

enum _ProductAction { edit, delete, activate, hide }

class _ProductImage extends StatelessWidget {
  const _ProductImage({this.imageData});

  final String? imageData;

  @override
  Widget build(BuildContext context) {
    final bytes = _decodeBase64(imageData);
    if (bytes == null) {
      return const ColoredBox(
        color: Color(0xFFF0F3F8),
        child: Center(
          child: Icon(Icons.image_outlined, size: 72, color: Color(0xFF8B95A5)),
        ),
      );
    }
    return Image.memory(
      bytes,
      fit: BoxFit.cover,
      errorBuilder: (_, _, _) {
        return const ColoredBox(
          color: Color(0xFFF0F3F8),
          child: Center(child: Icon(Icons.broken_image_outlined, size: 60)),
        );
      },
    );
  }
}

class _Price extends StatelessWidget {
  const _Price({required this.product});

  final Product product;

  @override
  Widget build(BuildContext context) {
    if (product.discount <= 0) {
      return Text(
        '${product.price.toStringAsFixed(2)} €',
        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
      );
    }

    return Row(
      children: [
        Text(
          '${product.price.toStringAsFixed(2)} €',
          style: const TextStyle(
            color: Color(0xFF8B95A5),
            decoration: TextDecoration.lineThrough,
          ),
        ),
        const SizedBox(width: AppPadding.small),
        Text(
          '${product.discountedPrice.toStringAsFixed(2)} €',
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

class _ProductStatusChip extends StatelessWidget {
  const _ProductStatusChip({required this.state});

  final String state;

  @override
  Widget build(BuildContext context) {
    final active = state.toLowerCase() == 'active';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
      decoration: BoxDecoration(
        color: active ? const Color(0xFFE7F6EC) : const Color(0xFFFFF3D6),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        active ? 'Aktivan' : 'Nacrt',
        style: TextStyle(
          color: active ? const Color(0xFF1B7F3A) : const Color(0xFF8A5A00),
          fontWeight: FontWeight.w600,
          fontSize: 12,
        ),
      ),
    );
  }
}

class _ProductFilters {
  const _ProductFilters({
    this.state,
    this.withDiscount,
    this.productCategoryId,
    this.carManufacturerId,
    this.carModelIds = const [],
  });

  final String? state;
  final bool? withDiscount;
  final int? productCategoryId;
  final int? carManufacturerId;
  final List<int> carModelIds;
}

class _ProductFilterDialog extends StatefulWidget {
  const _ProductFilterDialog({required this.initial});

  final _ProductFilters initial;

  @override
  State<_ProductFilterDialog> createState() => _ProductFilterDialogState();
}

class _ProductFilterDialogState extends State<_ProductFilterDialog> {
  String? _state;
  bool? _withDiscount;
  int? _categoryId;
  int? _manufacturerId;
  int? _modelToAdd;
  late List<int> _modelIds;

  @override
  void initState() {
    super.initState();
    _state = widget.initial.state;
    _withDiscount = widget.initial.withDiscount;
    _categoryId = widget.initial.productCategoryId;
    _manufacturerId = widget.initial.carManufacturerId;
    _modelIds = [...widget.initial.carModelIds];
  }

  @override
  Widget build(BuildContext context) {
    final categories = context.watch<ProductCategoryProvider>().categories;
    final groups = context
        .watch<CarModelsByManufacturerProvider>()
        .modelsByManufacturer;
    final selectedGroup = _groupForManufacturer(groups, _manufacturerId);

    return AlertDialog(
      title: const Text('Filteri proizvoda'),
      content: SizedBox(
        width: 560,
        child: SingleChildScrollView(
          child: Column(
            children: [
              DropdownButtonFormField<String?>(
                initialValue: _state,
                decoration: const InputDecoration(labelText: 'Status'),
                items: const [
                  DropdownMenuItem(value: null, child: Text('Svi statusi')),
                  DropdownMenuItem(value: 'active', child: Text('Aktivni')),
                  DropdownMenuItem(value: 'draft', child: Text('Nacrti')),
                ],
                onChanged: (value) => setState(() => _state = value),
              ),
              const SizedBox(height: AppPadding.medium),
              DropdownButtonFormField<bool?>(
                initialValue: _withDiscount,
                decoration: const InputDecoration(labelText: 'Popust'),
                items: const [
                  DropdownMenuItem(value: null, child: Text('Svi proizvodi')),
                  DropdownMenuItem(value: true, child: Text('Sa popustom')),
                  DropdownMenuItem(value: false, child: Text('Bez popusta')),
                ],
                onChanged: (value) => setState(() => _withDiscount = value),
              ),
              const SizedBox(height: AppPadding.medium),
              DropdownButtonFormField<int?>(
                initialValue: _categoryId,
                decoration: const InputDecoration(labelText: 'Kategorija'),
                items: [
                  const DropdownMenuItem(
                    value: null,
                    child: Text('Sve kategorije'),
                  ),
                  ...categories.map(
                    (category) => DropdownMenuItem(
                      value: category.id,
                      child: Text(category.name),
                    ),
                  ),
                ],
                onChanged: (value) => setState(() => _categoryId = value),
              ),
              const SizedBox(height: AppPadding.medium),
              DropdownButtonFormField<int?>(
                initialValue: _manufacturerId,
                decoration: const InputDecoration(
                  labelText: 'Proizvođač vozila',
                ),
                items: [
                  const DropdownMenuItem(
                    value: null,
                    child: Text('Svi proizvođači'),
                  ),
                  ...groups.map(
                    (group) => DropdownMenuItem(
                      value: group.manufacturer.id,
                      child: Text(group.manufacturer.name),
                    ),
                  ),
                ],
                onChanged: (value) {
                  setState(() {
                    _manufacturerId = value;
                    _modelToAdd = null;
                    _modelIds.clear();
                  });
                },
              ),
              if (selectedGroup != null) ...[
                const SizedBox(height: AppPadding.medium),
                DropdownButtonFormField<int?>(
                  key: ValueKey(_manufacturerId),
                  initialValue: _modelToAdd,
                  decoration: const InputDecoration(labelText: 'Model vozila'),
                  items: selectedGroup.models
                      .where((model) => !_modelIds.contains(model.id))
                      .map(
                        (model) => DropdownMenuItem(
                          value: model.id,
                          child: Text('${model.name} (${model.modelYear})'),
                        ),
                      )
                      .toList(),
                  onChanged: (value) {
                    if (value == null) return;
                    setState(() {
                      _modelIds.add(value);
                      _modelToAdd = null;
                    });
                  },
                ),
              ],
              if (_modelIds.isNotEmpty) ...[
                const SizedBox(height: AppPadding.medium),
                Align(
                  alignment: Alignment.centerLeft,
                  child: Wrap(
                    spacing: AppPadding.small,
                    runSpacing: AppPadding.small,
                    children: _modelIds.map((id) {
                      final model = _findModel(groups, id);
                      return InputChip(
                        label: Text(
                          model == null
                              ? 'Model $id'
                              : '${model.name} (${model.modelYear})',
                        ),
                        onDeleted: () => setState(() => _modelIds.remove(id)),
                      );
                    }).toList(),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, const _ProductFilters()),
          child: const Text('Poništi filtere'),
        ),
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Odustani'),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(
            context,
            _ProductFilters(
              state: _state,
              withDiscount: _withDiscount,
              productCategoryId: _categoryId,
              carManufacturerId: _manufacturerId,
              carModelIds: _modelIds,
            ),
          ),
          child: const Text('Primijeni'),
        ),
      ],
    );
  }
}

class _ProductDialog extends StatefulWidget {
  const _ProductDialog({this.product});

  final Product? product;

  @override
  State<_ProductDialog> createState() => _ProductDialogState();
}

class _ProductDialogState extends State<_ProductDialog> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  late final TextEditingController _nameController;
  late final TextEditingController _priceController;
  late final TextEditingController _discountController;
  late final TextEditingController _descriptionController;

  int? _categoryId;
  int? _manufacturerId;
  int? _modelToAdd;
  late List<int> _modelIds;
  String? _base64Image;
  bool _saving = false;

  bool get _isEditing => widget.product != null;

  @override
  void initState() {
    super.initState();
    final product = widget.product;
    _nameController = TextEditingController(text: product?.name ?? '');
    _priceController = TextEditingController(
      text: product == null ? '' : product.price.toStringAsFixed(2),
    );
    _discountController = TextEditingController(
      text: product == null ? '0' : (product.discount * 100).toStringAsFixed(0),
    );
    _descriptionController = TextEditingController(
      text: product?.details ?? '',
    );
    _categoryId = product?.productCategoryId;
    _modelIds = product?.carModels?.map((model) => model.id).toList() ?? [];
    _base64Image = product?.imageData;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _priceController.dispose();
    _discountController.dispose();
    _descriptionController.dispose();
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
    if (_categoryId == null) {
      _showError('Odaberite kategoriju proizvoda.');
      return;
    }
    if (_modelIds.isEmpty) {
      _showError('Odaberite najmanje jedan model vozila.');
      return;
    }

    setState(() => _saving = true);
    try {
      final request = ProductInsertUpdate(
        name: _nameController.text.trim(),
        price: _parseNumber(_priceController.text),
        discount: _parseNumber(_discountController.text)! / 100,
        imageData: _base64Image,
        description: _descriptionController.text.trim(),
        carModelIds: _modelIds,
        productCategoryId: _categoryId,
      );

      final provider = context.read<ProductProvider>();
      if (_isEditing) {
        await provider.updateProduct(id: widget.product!.id, request: request);
      } else {
        await provider.insertProduct(request);
      }

      if (mounted) Navigator.pop(context, true);
    } on CustomException catch (error) {
      _showError(error.message);
    } catch (_) {
      _showError('Spremanje proizvoda nije uspjelo.');
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

  @override
  Widget build(BuildContext context) {
    final categories = context.watch<ProductCategoryProvider>().categories;
    final groups = context
        .watch<CarModelsByManufacturerProvider>()
        .modelsByManufacturer;
    final selectedGroup = _groupForManufacturer(groups, _manufacturerId);

    return AlertDialog(
      title: Text(_isEditing ? 'Uredi proizvod' : 'Dodaj proizvod'),
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
                        child: _ProductImage(imageData: _base64Image),
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
                              _base64Image == null
                                  ? 'Odaberi sliku'
                                  : 'Promijeni sliku',
                            ),
                          ),
                          if (!_isEditing && _base64Image != null)
                            TextButton(
                              onPressed: _saving
                                  ? null
                                  : () => setState(() => _base64Image = null),
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
                      icon: Icons.inventory_2_outlined,
                      validator: (value) =>
                          _requiredText(value, 'naziv proizvoda'),
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
                    SizedBox(
                      width: 340,
                      child: DropdownButtonFormField<int>(
                        initialValue: _categoryId,
                        decoration: const InputDecoration(
                          labelText: 'Kategorija',
                          prefixIcon: Icon(Icons.category_outlined),
                        ),
                        items: categories
                            .map(
                              (category) => DropdownMenuItem(
                                value: category.id,
                                child: Text(category.name),
                              ),
                            )
                            .toList(),
                        onChanged: _saving
                            ? null
                            : (value) => setState(() => _categoryId = value),
                        validator: (value) =>
                            value == null ? 'Odaberite kategoriju.' : null,
                      ),
                    ),
                    SizedBox(
                      width: 340,
                      child: DropdownButtonFormField<int>(
                        initialValue: _manufacturerId,
                        decoration: const InputDecoration(
                          labelText: 'Proizvođač vozila',
                          prefixIcon: Icon(Icons.directions_car_outlined),
                        ),
                        items: groups
                            .map(
                              (group) => DropdownMenuItem(
                                value: group.manufacturer.id,
                                child: Text(group.manufacturer.name),
                              ),
                            )
                            .toList(),
                        onChanged: _saving
                            ? null
                            : (value) {
                                setState(() {
                                  _manufacturerId = value;
                                  _modelToAdd = null;
                                });
                              },
                      ),
                    ),
                    SizedBox(
                      width: 340,
                      child: DropdownButtonFormField<int>(
                        key: ValueKey(_manufacturerId),
                        initialValue: _modelToAdd,
                        decoration: const InputDecoration(
                          labelText: 'Dodaj model vozila',
                          prefixIcon: Icon(Icons.commute_outlined),
                        ),
                        items:
                            selectedGroup?.models
                                .where((model) => !_modelIds.contains(model.id))
                                .map(
                                  (model) => DropdownMenuItem(
                                    value: model.id,
                                    child: Text(
                                      '${model.name} (${model.modelYear})',
                                    ),
                                  ),
                                )
                                .toList() ??
                            [],
                        onChanged: _saving || selectedGroup == null
                            ? null
                            : (value) {
                                if (value == null) return;
                                setState(() {
                                  _modelIds.add(value);
                                  _modelToAdd = null;
                                });
                              },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppPadding.medium),
                Align(
                  alignment: Alignment.centerLeft,
                  child: Wrap(
                    spacing: AppPadding.small,
                    runSpacing: AppPadding.small,
                    children: _modelIds.map((id) {
                      final model = _findModel(groups, id);
                      return InputChip(
                        label: Text(
                          model == null
                              ? 'Model $id'
                              : '${model.name} (${model.modelYear})',
                        ),
                        onDeleted: _saving
                            ? null
                            : () => setState(() => _modelIds.remove(id)),
                      );
                    }).toList(),
                  ),
                ),
                const SizedBox(height: AppPadding.medium),
                TextFormField(
                  controller: _descriptionController,
                  minLines: 3,
                  maxLines: 5,
                  validator: (value) => _requiredText(value, 'opis proizvoda'),
                  decoration: const InputDecoration(
                    labelText: 'Opis',
                    alignLabelWithHint: true,
                    prefixIcon: Icon(Icons.description_outlined),
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

class _EmptyProducts extends StatelessWidget {
  const _EmptyProducts();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.inventory_2_outlined, size: 56, color: Color(0xFF7A8493)),
          SizedBox(height: AppPadding.medium),
          Text('Nema pronađenih proizvoda.'),
        ],
      ),
    );
  }
}

void _showProductDetails(BuildContext context, Product product) {
  showDialog<void>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      title: Text(product.name),
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
                  child: _ProductImage(imageData: product.imageData),
                ),
              ),
              const SizedBox(height: AppPadding.large),
              _DetailRow(
                label: 'Status',
                value: product.state == 'active' ? 'Aktivan' : 'Nacrt',
              ),
              _DetailRow(
                label: 'Cijena',
                value: '${product.price.toStringAsFixed(2)} €',
              ),
              if (product.discount > 0) ...[
                _DetailRow(
                  label: 'Popust',
                  value: '${(product.discount * 100).toStringAsFixed(0)}%',
                ),
                _DetailRow(
                  label: 'Cijena s popustom',
                  value: '${product.discountedPrice.toStringAsFixed(2)} €',
                ),
              ],
              _DetailRow(
                label: 'Kategorija',
                value: product.category ?? 'Nije navedena',
              ),
              _DetailRow(
                label: 'Opis',
                value: product.details ?? 'Nije naveden',
              ),
              _DetailRow(
                label: 'Modeli vozila',
                value: product.carModels?.isNotEmpty == true
                    ? product.carModels!
                          .map((model) => '${model.name} (${model.modelYear})')
                          .join(', ')
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

class _DetailRow extends StatelessWidget {
  const _DetailRow({required this.label, required this.value});

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

CarModel? _findModel(List<CarModelsByManufacturer> groups, int id) {
  for (final group in groups) {
    for (final model in group.models) {
      if (model.id == id) return model;
    }
  }
  return null;
}

CarModelsByManufacturer? _groupForManufacturer(
  List<CarModelsByManufacturer> groups,
  int? manufacturerId,
) {
  if (manufacturerId == null) return null;
  for (final group in groups) {
    if (group.manufacturer.id == manufacturerId) return group;
  }
  return null;
}

Uint8List? _decodeBase64(String? value) {
  if (value == null || value.trim().isEmpty) return null;
  try {
    return base64Decode(value.contains(',') ? value.split(',').last : value);
  } catch (_) {
    return null;
  }
}
