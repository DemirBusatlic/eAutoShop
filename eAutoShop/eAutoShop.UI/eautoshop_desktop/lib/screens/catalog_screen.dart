import 'dart:convert';
import 'dart:typed_data';

import 'package:eautoshop_desktop/models/car_manufacturer/car_manufacturer.dart';
import 'package:eautoshop_desktop/models/car_model/car_model.dart';
import 'package:eautoshop_desktop/models/car_model/car_model_insert_update.dart';
import 'package:eautoshop_desktop/models/catalog/catalog_name_request.dart';
import 'package:eautoshop_desktop/models/city/city.dart';
import 'package:eautoshop_desktop/models/product_category/product_category.dart';
import 'package:eautoshop_desktop/models/service_type/service_type.dart';
import 'package:eautoshop_desktop/models/service_type/service_type_insert_update.dart';
import 'package:eautoshop_desktop/providers/car_manufacturer_provider.dart';
import 'package:eautoshop_desktop/providers/car_model_provider.dart';
import 'package:eautoshop_desktop/providers/city_provider.dart';
import 'package:eautoshop_desktop/providers/product_category_provider.dart';
import 'package:eautoshop_desktop/providers/service_type_provider.dart';
import 'package:eautoshop_desktop/utilities/custom_exception.dart';
import 'package:file_selector/file_selector.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

enum CatalogType { cities, categories, manufacturers, carModels, serviceTypes }

extension CatalogTypeExtension on CatalogType {
  String get label {
    switch (this) {
      case CatalogType.cities:
        return 'Gradovi';
      case CatalogType.categories:
        return 'Kategorije';
      case CatalogType.manufacturers:
        return 'Proizvođači';
      case CatalogType.carModels:
        return 'Modeli vozila';
      case CatalogType.serviceTypes:
        return 'Tipovi usluga';
    }
  }

  String get singularLabel {
    switch (this) {
      case CatalogType.cities:
        return 'grad';
      case CatalogType.categories:
        return 'kategoriju';
      case CatalogType.manufacturers:
        return 'proizvođača';
      case CatalogType.carModels:
        return 'model vozila';
      case CatalogType.serviceTypes:
        return 'tip usluge';
    }
  }
}

class CatalogScreen extends StatefulWidget {
  const CatalogScreen({super.key});

  @override
  State<CatalogScreen> createState() => _CatalogScreenState();
}

class _CatalogScreenState extends State<CatalogScreen>
    with SingleTickerProviderStateMixin {
  static const Color _primaryBlue = Color(0xFF2848C7);

  final TextEditingController _searchController = TextEditingController();
  late final TabController _tabController;

  CatalogType _selectedType = CatalogType.cities;
  int? _manufacturerFilterId;
  bool _initialLoading = true;
  bool _isSaving = false;
  String? _loadError;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(
      length: CatalogType.values.length,
      vsync: this,
    )..addListener(_onTabChanged);
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadInitialData());
  }

  @override
  void dispose() {
    _tabController.removeListener(_onTabChanged);
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _onTabChanged() {
    if (_tabController.indexIsChanging ||
        CatalogType.values[_tabController.index] == _selectedType) {
      return;
    }

    setState(() {
      _selectedType = CatalogType.values[_tabController.index];
      _searchController.clear();
      _manufacturerFilterId = null;
      _loadError = null;
    });

    _loadSelectedCatalog();
  }

  Future<void> _loadInitialData() async {
    setState(() {
      _initialLoading = true;
      _loadError = null;
    });

    try {
      await context.read<CarManufacturerProvider>().getManufacturers();
      await _loadSelectedCatalog();
    } catch (error) {
      if (mounted) {
        setState(() => _loadError = _cleanError(error));
      }
    } finally {
      if (mounted) {
        setState(() => _initialLoading = false);
      }
    }
  }

  Future<void> _loadSelectedCatalog() async {
    final search = _searchController.text.trim();
    final name = search.isEmpty ? null : search;

    try {
      switch (_selectedType) {
        case CatalogType.cities:
          await context.read<CityProvider>().getCities(name: name);
          break;
        case CatalogType.categories:
          await context.read<ProductCategoryProvider>().getCategories(
            name: name,
          );
          break;
        case CatalogType.manufacturers:
          await context.read<CarManufacturerProvider>().getManufacturers(
            name: name,
          );
          break;
        case CatalogType.carModels:
          await context.read<CarModelProvider>().getModels(
            name: name,
            carManufacturerId: _manufacturerFilterId,
          );
          break;
        case CatalogType.serviceTypes:
          await context.read<ServiceTypeProvider>().getTypes(name: name);
          break;
      }

      if (mounted) {
        setState(() => _loadError = null);
      }
    } catch (error) {
      if (mounted) {
        setState(() => _loadError = _cleanError(error));
      }
    }
  }

  bool get _isCurrentCatalogLoading {
    switch (_selectedType) {
      case CatalogType.cities:
        return context.watch<CityProvider>().isLoading;
      case CatalogType.categories:
        return context.watch<ProductCategoryProvider>().isLoading;
      case CatalogType.manufacturers:
        return context.watch<CarManufacturerProvider>().isLoading;
      case CatalogType.carModels:
        return context.watch<CarModelProvider>().isLoading;
      case CatalogType.serviceTypes:
        return context.watch<ServiceTypeProvider>().isLoading;
    }
  }

  int get _currentCount {
    switch (_selectedType) {
      case CatalogType.cities:
        return context.watch<CityProvider>().countOfItems;
      case CatalogType.categories:
        return context.watch<ProductCategoryProvider>().countOfItems;
      case CatalogType.manufacturers:
        return context.watch<CarManufacturerProvider>().countOfItems;
      case CatalogType.carModels:
        return context.watch<CarModelProvider>().countOfItems;
      case CatalogType.serviceTypes:
        return context.watch<ServiceTypeProvider>().countOfItems;
    }
  }

  Future<void> _openAddDialog() async {
    switch (_selectedType) {
      case CatalogType.cities:
      case CatalogType.categories:
      case CatalogType.manufacturers:
        await _showNameDialog();
        break;
      case CatalogType.carModels:
        await _showCarModelDialog();
        break;
      case CatalogType.serviceTypes:
        await _showServiceTypeDialog();
        break;
    }
  }

  Future<void> _showNameDialog({int? id, String initialName = ''}) async {
    final controller = TextEditingController(text: initialName);
    final formKey = GlobalKey<FormState>();

    await showDialog<void>(
      context: context,
      barrierDismissible: !_isSaving,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text(
            id == null
                ? 'Dodaj ${_selectedType.singularLabel}'
                : 'Uredi ${_selectedType.singularLabel}',
          ),
          content: Form(
            key: formKey,
            child: SizedBox(
              width: 420,
              child: TextFormField(
                controller: controller,
                autofocus: true,
                maxLength: 50,
                decoration: const InputDecoration(
                  labelText: 'Naziv',
                  border: OutlineInputBorder(),
                ),
                validator: (value) => value == null || value.trim().isEmpty
                    ? 'Naziv je obavezan.'
                    : null,
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: _isSaving ? null : () => Navigator.pop(dialogContext),
              child: const Text('Odustani'),
            ),
            FilledButton(
              onPressed: _isSaving
                  ? null
                  : () async {
                      if (!formKey.currentState!.validate()) {
                        return;
                      }
                      setDialogState(() => _isSaving = true);
                      try {
                        final request = CatalogNameRequest(
                          name: controller.text.trim(),
                        );
                        await _saveNameCatalog(id, request);
                        if (dialogContext.mounted) {
                          Navigator.pop(dialogContext);
                        }
                        if (mounted) {
                          _showMessage('Podaci su uspješno sačuvani.');
                        }
                      } catch (error) {
                        if (mounted) {
                          _showMessage(_cleanError(error), isError: true);
                        }
                      } finally {
                        _isSaving = false;
                      }
                    },
              child: Text(_isSaving ? 'Čuvanje...' : 'Sačuvaj'),
            ),
          ],
        ),
      ),
    );

    controller.dispose();
  }

  Future<void> _saveNameCatalog(int? id, CatalogNameRequest request) async {
    switch (_selectedType) {
      case CatalogType.cities:
        final provider = context.read<CityProvider>();
        id == null
            ? await provider.insertCity(request)
            : await provider.updateCity(id, request);
        break;
      case CatalogType.categories:
        final provider = context.read<ProductCategoryProvider>();
        id == null
            ? await provider.insertCategory(request)
            : await provider.updateCategory(id, request);
        break;
      case CatalogType.manufacturers:
        final provider = context.read<CarManufacturerProvider>();
        id == null
            ? await provider.insertManufacturer(request)
            : await provider.updateManufacturer(id, request);
        break;
      case CatalogType.carModels:
      case CatalogType.serviceTypes:
        throw StateError('Neodgovarajući tip kataloga.');
    }
    await _loadSelectedCatalog();
  }

  Future<void> _showCarModelDialog({CarModel? model}) async {
    final nameController = TextEditingController(text: model?.name ?? '');
    final yearController = TextEditingController(text: model?.modelYear ?? '');
    final formKey = GlobalKey<FormState>();
    var manufacturerId = model?.carManufacturerId;
    final manufacturers = context.read<CarManufacturerProvider>().manufacturers;

    await showDialog<void>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text(
            model == null ? 'Dodaj model vozila' : 'Uredi model vozila',
          ),
          content: Form(
            key: formKey,
            child: SizedBox(
              width: 440,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  DropdownButtonFormField<int>(
                    initialValue: manufacturerId,
                    isExpanded: true,
                    decoration: const InputDecoration(
                      labelText: 'Proizvođač',
                      border: OutlineInputBorder(),
                    ),
                    items: manufacturers
                        .map(
                          (item) => DropdownMenuItem<int>(
                            value: item.id,
                            child: Text(item.name),
                          ),
                        )
                        .toList(),
                    onChanged: (value) =>
                        setDialogState(() => manufacturerId = value),
                    validator: (value) =>
                        value == null ? 'Odaberite proizvođača.' : null,
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: nameController,
                    maxLength: 100,
                    decoration: const InputDecoration(
                      labelText: 'Naziv modela',
                      border: OutlineInputBorder(),
                    ),
                    validator: _requiredValidator,
                  ),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: yearController,
                    maxLength: 10,
                    decoration: const InputDecoration(
                      labelText: 'Godište',
                      hintText: 'npr. 2018-2024',
                      border: OutlineInputBorder(),
                    ),
                    validator: _requiredValidator,
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: _isSaving ? null : () => Navigator.pop(dialogContext),
              child: const Text('Odustani'),
            ),
            FilledButton(
              onPressed: _isSaving
                  ? null
                  : () async {
                      if (!formKey.currentState!.validate()) {
                        return;
                      }
                      setDialogState(() => _isSaving = true);
                      try {
                        final request = CarModelInsertUpdate(
                          name: nameController.text.trim(),
                          modelYear: yearController.text.trim(),
                          carManufacturerId: manufacturerId!,
                        );
                        final provider = context.read<CarModelProvider>();
                        model == null
                            ? await provider.insertModel(request)
                            : await provider.updateModel(model.id, request);
                        await _loadSelectedCatalog();
                        if (dialogContext.mounted) {
                          Navigator.pop(dialogContext);
                        }
                        if (mounted) {
                          _showMessage('Model vozila je uspješno sačuvan.');
                        }
                      } catch (error) {
                        if (mounted) {
                          _showMessage(_cleanError(error), isError: true);
                        }
                      } finally {
                        _isSaving = false;
                      }
                    },
              child: Text(_isSaving ? 'Čuvanje...' : 'Sačuvaj'),
            ),
          ],
        ),
      ),
    );

    nameController.dispose();
    yearController.dispose();
  }

  Future<void> _showServiceTypeDialog({ServiceType? type}) async {
    final nameController = TextEditingController(text: type?.name ?? '');
    final formKey = GlobalKey<FormState>();
    String? selectedImage;

    await showDialog<void>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text(type == null ? 'Dodaj tip usluge' : 'Uredi tip usluge'),
          content: Form(
            key: formKey,
            child: SizedBox(
              width: 440,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextFormField(
                    controller: nameController,
                    maxLength: 50,
                    decoration: const InputDecoration(
                      labelText: 'Naziv',
                      border: OutlineInputBorder(),
                    ),
                    validator: _requiredValidator,
                  ),
                  const SizedBox(height: 10),
                  OutlinedButton.icon(
                    onPressed: _isSaving
                        ? null
                        : () async {
                            final image = await _selectImage();
                            if (image != null) {
                              setDialogState(() => selectedImage = image);
                            }
                          },
                    icon: const Icon(Icons.image_outlined),
                    label: Text(
                      selectedImage != null
                          ? 'Slika je odabrana'
                          : type?.image.isNotEmpty == true
                          ? 'Promijeni sliku'
                          : 'Odaberi sliku',
                    ),
                  ),
                  if (selectedImage != null ||
                      type?.image.isNotEmpty == true) ...[
                    const SizedBox(height: 12),
                    SizedBox(
                      height: 120,
                      child: Image.memory(
                        _decodeImage(selectedImage ?? type!.image),
                        fit: BoxFit.contain,
                        errorBuilder: (_, _, _) =>
                            const Icon(Icons.broken_image_outlined, size: 48),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: _isSaving ? null : () => Navigator.pop(dialogContext),
              child: const Text('Odustani'),
            ),
            FilledButton(
              onPressed: _isSaving
                  ? null
                  : () async {
                      if (!formKey.currentState!.validate()) {
                        return;
                      }
                      if (type == null && selectedImage == null) {
                        _showMessage('Slika je obavezna.', isError: true);
                        return;
                      }
                      setDialogState(() => _isSaving = true);
                      try {
                        final request = ServiceTypeInsertUpdate(
                          name: nameController.text.trim(),
                          image: selectedImage,
                        );
                        final provider = context.read<ServiceTypeProvider>();
                        type == null
                            ? await provider.insertType(request)
                            : await provider.updateType(type.id, request);
                        await _loadSelectedCatalog();
                        if (dialogContext.mounted) {
                          Navigator.pop(dialogContext);
                        }
                        if (mounted) {
                          _showMessage('Tip usluge je uspješno sačuvan.');
                        }
                      } catch (error) {
                        if (mounted) {
                          _showMessage(_cleanError(error), isError: true);
                        }
                      } finally {
                        _isSaving = false;
                      }
                    },
              child: Text(_isSaving ? 'Čuvanje...' : 'Sačuvaj'),
            ),
          ],
        ),
      ),
    );

    nameController.dispose();
  }

  Future<String?> _selectImage() async {
    const imageTypes = XTypeGroup(
      label: 'Slike',
      extensions: <String>['png', 'jpg', 'jpeg'],
    );
    final file = await openFile(acceptedTypeGroups: const [imageTypes]);
    if (file == null) {
      return null;
    }
    final bytes = await file.readAsBytes();
    if (bytes.length > 5 * 1024 * 1024) {
      throw const CustomException('Slika mora biti manja od 5 MB.');
    }
    return base64Encode(bytes);
  }

  Uint8List _decodeImage(String value) {
    final commaIndex = value.indexOf(',');
    return base64Decode(
      commaIndex >= 0 ? value.substring(commaIndex + 1) : value,
    );
  }

  Future<void> _confirmDelete({required int id, required String name}) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Potvrda brisanja'),
        content: Text('Da li ste sigurni da želite obrisati „$name“?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Odustani'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Obriši'),
          ),
        ],
      ),
    );
    if (confirmed != true) {
      return;
    }

    if (!mounted) {
      return;
    }

    try {
      switch (_selectedType) {
        case CatalogType.cities:
          await context.read<CityProvider>().deleteCity(id);
          break;
        case CatalogType.categories:
          await context.read<ProductCategoryProvider>().deleteCategory(id);
          break;
        case CatalogType.manufacturers:
          await context.read<CarManufacturerProvider>().deleteManufacturer(id);
          break;
        case CatalogType.carModels:
          await context.read<CarModelProvider>().deleteModel(id);
          break;
        case CatalogType.serviceTypes:
          await context.read<ServiceTypeProvider>().deleteType(id);
          break;
      }
      await _loadSelectedCatalog();
      if (mounted) {
        _showMessage('Podatak je uspješno obrisan.');
      }
    } catch (error) {
      if (mounted) {
        _showMessage(_cleanError(error), isError: true);
      }
    }
  }

  static String? _requiredValidator(String? value) {
    return value == null || value.trim().isEmpty ? 'Polje je obavezno.' : null;
  }

  String _cleanError(Object error) {
    return error is CustomException ? error.message : error.toString();
  }

  void _showMessage(String message, {bool isError = false}) {
    if (!mounted) {
      return;
    }
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: isError
              ? Colors.red.shade700
              : Colors.green.shade700,
        ),
      );
  }

  @override
  Widget build(BuildContext context) {
    final isLoading = _initialLoading || _isCurrentCatalogLoading;

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Upravljanje katalozima',
              style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 4),
            const Text(
              'Upravljanje pomoćnim podacima aplikacije',
              style: TextStyle(color: Color(0xFF687385)),
            ),
            const SizedBox(height: 20),
            Card(
              elevation: 0,
              child: TabBar(
                controller: _tabController,
                isScrollable: true,
                tabAlignment: TabAlignment.start,
                labelColor: _primaryBlue,
                indicatorColor: _primaryBlue,
                tabs: CatalogType.values
                    .map((type) => Tab(text: type.label))
                    .toList(),
              ),
            ),
            const SizedBox(height: 16),
            _buildToolbar(),
            const SizedBox(height: 16),
            Expanded(
              child: Card(
                elevation: 0,
                child: isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : _loadError != null
                    ? _buildError()
                    : _buildTable(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildToolbar() {
    final manufacturers = context
        .watch<CarManufacturerProvider>()
        .manufacturers;
    return Wrap(
      spacing: 12,
      runSpacing: 12,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        SizedBox(
          width: 330,
          child: TextField(
            controller: _searchController,
            onSubmitted: (_) => _loadSelectedCatalog(),
            decoration: InputDecoration(
              hintText: 'Pretraži ${_selectedType.label.toLowerCase()}',
              prefixIcon: const Icon(Icons.search),
              suffixIcon: IconButton(
                onPressed: _loadSelectedCatalog,
                icon: const Icon(Icons.arrow_forward),
              ),
              border: const OutlineInputBorder(),
            ),
          ),
        ),
        if (_selectedType == CatalogType.carModels)
          SizedBox(
            width: 250,
            child: DropdownButtonFormField<int>(
              initialValue: _manufacturerFilterId,
              isExpanded: true,
              decoration: const InputDecoration(
                labelText: 'Proizvođač',
                border: OutlineInputBorder(),
              ),
              items: [
                const DropdownMenuItem<int>(
                  value: null,
                  child: Text('Svi proizvođači'),
                ),
                ...manufacturers.map(
                  (item) => DropdownMenuItem<int>(
                    value: item.id,
                    child: Text(item.name),
                  ),
                ),
              ],
              onChanged: (value) {
                setState(() => _manufacturerFilterId = value);
                _loadSelectedCatalog();
              },
            ),
          ),
        FilledButton.icon(
          onPressed: _openAddDialog,
          icon: const Icon(Icons.add),
          label: Text('Dodaj ${_selectedType.singularLabel}'),
        ),
      ],
    );
  }

  Widget _buildError() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.error_outline, size: 48, color: Colors.red),
          const SizedBox(height: 12),
          Text(_loadError!, textAlign: TextAlign.center),
          const SizedBox(height: 12),
          FilledButton.icon(
            onPressed: _loadSelectedCatalog,
            icon: const Icon(Icons.refresh),
            label: const Text('Pokušaj ponovo'),
          ),
        ],
      ),
    );
  }

  Widget _buildTable() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
          child: Text('Ukupno zapisa: $_currentCount'),
        ),
        const Divider(height: 1),
        Expanded(
          child: SingleChildScrollView(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: _selectedTable(),
            ),
          ),
        ),
      ],
    );
  }

  Widget _selectedTable() {
    switch (_selectedType) {
      case CatalogType.cities:
        return _nameTable<City>(
          context.watch<CityProvider>().cities,
          (item) => item.id,
          (item) => item.name,
        );
      case CatalogType.categories:
        return _nameTable<ProductCategory>(
          context.watch<ProductCategoryProvider>().categories,
          (item) => item.id,
          (item) => item.name,
        );
      case CatalogType.manufacturers:
        return _nameTable<CarManufacturer>(
          context.watch<CarManufacturerProvider>().manufacturers,
          (item) => item.id,
          (item) => item.name,
        );
      case CatalogType.carModels:
        return _carModelTable(context.watch<CarModelProvider>().models);
      case CatalogType.serviceTypes:
        return _serviceTypeTable(context.watch<ServiceTypeProvider>().types);
    }
  }

  Widget _nameTable<T>(
    List<T> items,
    int Function(T) idOf,
    String Function(T) nameOf,
  ) {
    return DataTable(
      columns: const [
        DataColumn(label: Text('Naziv')),
        DataColumn(label: Text('Akcije')),
      ],
      rows: items
          .map(
            (item) => DataRow(
              cells: [
                DataCell(SizedBox(width: 500, child: Text(nameOf(item)))),
                DataCell(
                  _actions(
                    onEdit: () => _showNameDialog(
                      id: idOf(item),
                      initialName: nameOf(item),
                    ),
                    onDelete: () =>
                        _confirmDelete(id: idOf(item), name: nameOf(item)),
                  ),
                ),
              ],
            ),
          )
          .toList(),
    );
  }

  Widget _carModelTable(List<CarModel> models) {
    return DataTable(
      columns: const [
        DataColumn(label: Text('Proizvođač')),
        DataColumn(label: Text('Model')),
        DataColumn(label: Text('Godište')),
        DataColumn(label: Text('Akcije')),
      ],
      rows: models
          .map(
            (model) => DataRow(
              cells: [
                DataCell(Text(model.carManufacturerName)),
                DataCell(Text(model.name)),
                DataCell(Text(model.modelYear)),
                DataCell(
                  _actions(
                    onEdit: () => _showCarModelDialog(model: model),
                    onDelete: () => _confirmDelete(
                      id: model.id,
                      name: '${model.carManufacturerName} ${model.name}',
                    ),
                  ),
                ),
              ],
            ),
          )
          .toList(),
    );
  }

  Widget _serviceTypeTable(List<ServiceType> types) {
    return DataTable(
      columns: const [
        DataColumn(label: Text('Slika')),
        DataColumn(label: Text('Naziv')),
        DataColumn(label: Text('Akcije')),
      ],
      rows: types
          .map(
            (type) => DataRow(
              cells: [
                DataCell(
                  SizedBox(
                    width: 48,
                    height: 48,
                    child: type.image.isEmpty
                        ? const Icon(Icons.image_not_supported_outlined)
                        : Image.memory(
                            _decodeImage(type.image),
                            fit: BoxFit.cover,
                            errorBuilder: (_, _, _) =>
                                const Icon(Icons.broken_image_outlined),
                          ),
                  ),
                ),
                DataCell(SizedBox(width: 420, child: Text(type.name))),
                DataCell(
                  _actions(
                    onEdit: () => _showServiceTypeDialog(type: type),
                    onDelete: () =>
                        _confirmDelete(id: type.id, name: type.name),
                  ),
                ),
              ],
            ),
          )
          .toList(),
    );
  }

  Widget _actions({
    required VoidCallback onEdit,
    required VoidCallback onDelete,
  }) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        IconButton(
          tooltip: 'Uredi',
          onPressed: onEdit,
          icon: const Icon(Icons.edit_outlined, color: _primaryBlue),
        ),
        IconButton(
          tooltip: 'Obriši',
          onPressed: onDelete,
          icon: const Icon(Icons.delete_outline, color: Colors.red),
        ),
      ],
    );
  }
}
