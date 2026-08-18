import 'dart:convert';
import 'dart:typed_data';

import 'package:eautoshop_mobile/models/car_model/car_model.dart';
import 'package:eautoshop_mobile/models/car_model/car_models_by_manufacturer.dart';
import 'package:eautoshop_mobile/models/city/city.dart';
import 'package:eautoshop_mobile/models/order/order_insert.dart';
import 'package:eautoshop_mobile/models/products/product.dart';
import 'package:eautoshop_mobile/models/products/product_order.dart';
import 'package:eautoshop_mobile/models/product_category/product_category.dart';
import 'package:eautoshop_mobile/providers/car_models_by_manufacturer_provider.dart';
import 'package:eautoshop_mobile/providers/city_provider.dart';
import 'package:eautoshop_mobile/providers/order_provider.dart';
import 'package:eautoshop_mobile/providers/product_category_provider.dart';
import 'package:eautoshop_mobile/providers/product_provider.dart';
import 'package:eautoshop_mobile/providers/product_recommender_provider.dart';
import 'package:eautoshop_mobile/screens/master_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_stripe/flutter_stripe.dart' as stripe;
import 'package:provider/provider.dart';

class ProductsScreen extends StatefulWidget {
  const ProductsScreen({super.key});

  @override
  State<ProductsScreen> createState() => _ProductsScreenState();
}

class _ProductsScreenState extends State<ProductsScreen> {
  static const int _pageSize = 10;
  static const int _maximumQuantity = 99;

  final TextEditingController _nameFilterController = TextEditingController();
  final TextEditingController _addressController = TextEditingController();
  final TextEditingController _postalCodeController = TextEditingController();

  final Map<int, int> _quantities = <int, int>{};
  final Map<int, Product> _cartProducts = <int, Product>{};

  List<ProductCategory> _categories = <ProductCategory>[];
  List<CarModelsByManufacturer> _carModelsByManufacturer =
      <CarModelsByManufacturer>[];
  List<City> _cities = <City>[];

  int _pageNumber = 1;
  int _totalPages = 1;
  int? _selectedCityId;
  int? _selectedCategoryId;
  int? _selectedManufacturerId;

  String _nameFilter = '';
  String _discountFilter = 'all';
  String? _productsError;
  String? _filterDataError;

  List<CarModel> _selectedCarModels = <CarModel>[];

  bool _filtersApplied = false;
  bool _filterDataLoading = true;
  bool _useProfileAddress = true;

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadInitialData();
    });
  }

  Future<void> _loadInitialData() async {
    await _loadProducts();

    if (!mounted) {
      return;
    }

    setState(() {
      _filterDataLoading = true;
      _filterDataError = null;
    });

    try {
      final categoryProvider = context.read<ProductCategoryProvider>();
      final carModelProvider = context.read<CarModelsByManufacturerProvider>();
      final cityProvider = context.read<CityProvider>();

      await Future.wait<void>([
        categoryProvider.getCategories(),
        carModelProvider.getCarModelsByManufacturer(),
        cityProvider.getCities(),
      ]);

      if (!mounted) {
        return;
      }

      setState(() {
        _categories = List<ProductCategory>.of(categoryProvider.categories);
        _carModelsByManufacturer = List<CarModelsByManufacturer>.of(
          carModelProvider.modelsByManufacturer,
        );
        _cities = List<City>.of(cityProvider.cities);
        _selectedCityId = _cities.isEmpty ? null : _cities.first.id;
      });
    } catch (error) {
      if (!mounted) {
        return;
      }

      setState(() {
        _filterDataError = error.toString();
      });
    } finally {
      if (mounted) {
        setState(() {
          _filterDataLoading = false;
        });
      }
    }
  }

  Future<void> _loadProducts() async {
    if (mounted) {
      setState(() {
        _productsError = null;
      });
    }

    bool? withDiscount;

    if (_discountFilter == 'discounted') {
      withDiscount = true;
    } else if (_discountFilter == 'notDiscounted') {
      withDiscount = false;
    }

    try {
      final provider = context.read<ProductProvider>();

      await provider.getProducts(
        pageNumber: _pageNumber,
        pageSize: _pageSize,
        nameFilter: _nameFilter.trim().isEmpty ? null : _nameFilter.trim(),
        withDiscount: withDiscount,
        categoryFilter: _selectedCategoryId,
        carManufacturerId: _selectedManufacturerId,
        carModelsFilter: _selectedCarModels.map((model) => model.id).toList(),
      );

      if (!mounted) {
        return;
      }

      final calculatedPages = (provider.countOfItems / _pageSize).ceil();

      setState(() {
        _totalPages = calculatedPages < 1 ? 1 : calculatedPages;
      });
    } catch (error) {
      if (!mounted) {
        return;
      }

      setState(() {
        _productsError = error.toString();
        _totalPages = 1;
      });
    }
  }

  Future<void> _changePage(int page) async {
    if (page < 1 || page > _totalPages || page == _pageNumber) {
      return;
    }

    setState(() {
      _pageNumber = page;
    });

    await _loadProducts();
  }

  int _quantityFor(int productId) => _quantities[productId] ?? 0;

  void _changeQuantity(Product product, int quantity) {
    final correctedQuantity = quantity.clamp(0, _maximumQuantity).toInt();

    setState(() {
      if (correctedQuantity == 0) {
        _quantities.remove(product.id);
        _cartProducts.remove(product.id);
      } else {
        _quantities[product.id] = correctedQuantity;
        _cartProducts[product.id] = product;
      }
    });
  }

  int get _cartItemCount =>
      _quantities.values.fold<int>(0, (sum, quantity) => sum + quantity);

  double get _cartTotal {
    double total = 0;

    for (final entry in _quantities.entries) {
      final product = _cartProducts[entry.key];

      if (product == null) {
        continue;
      }

      final price = product.discount > 0
          ? product.discountedPrice
          : product.price;

      total += price * entry.value;
    }

    return total;
  }

  List<ProductOrder> get _productOrders => _quantities.entries
      .map((entry) => ProductOrder(entry.key, entry.value))
      .toList();

  Uint8List? _decodeImage(String? imageData) {
    if (imageData == null || imageData.trim().isEmpty) {
      return null;
    }

    try {
      final commaIndex = imageData.indexOf(',');
      final payload = commaIndex >= 0
          ? imageData.substring(commaIndex + 1)
          : imageData;

      return base64Decode(payload);
    } on FormatException {
      return null;
    }
  }

  Widget _productImage(
    Product product, {
    double? width,
    double? height,
    BoxFit fit = BoxFit.contain,
  }) {
    final bytes = _decodeImage(product.imageData);

    if (bytes == null) {
      return SizedBox(
        width: width,
        height: height,
        child: const Icon(Icons.image_not_supported_outlined, size: 64),
      );
    }

    return Image.memory(
      bytes,
      width: width,
      height: height,
      fit: fit,
      errorBuilder: (_, _, _) =>
          const Icon(Icons.broken_image_outlined, size: 64),
    );
  }

  List<CarModel> _modelsForManufacturer(int? manufacturerId) {
    if (manufacturerId == null) {
      return <CarModel>[];
    }

    for (final group in _carModelsByManufacturer) {
      if (group.manufacturer.id == manufacturerId) {
        return group.models;
      }
    }

    return <CarModel>[];
  }

  void _showFilterDialog() {
    _nameFilterController.text = _nameFilter;

    String draftDiscountFilter = _discountFilter;
    int? draftCategoryId = _selectedCategoryId;
    int? draftManufacturerId = _selectedManufacturerId;
    final draftCarModels = List<CarModel>.of(_selectedCarModels);

    showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            final availableModels = _modelsForManufacturer(draftManufacturerId);

            return AlertDialog(
              title: const Text('Filteri proizvoda'),
              content: SizedBox(
                width: double.maxFinite,
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      TextField(
                        controller: _nameFilterController,
                        decoration: const InputDecoration(
                          labelText: 'Naziv proizvoda',
                          prefixIcon: Icon(Icons.search),
                        ),
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        'Popust',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      RadioGroup<String>(
                        groupValue: draftDiscountFilter,
                        onChanged: (value) {
                          setModalState(() {
                            draftDiscountFilter = value ?? 'all';
                          });
                        },
                        child: const Column(
                          children: [
                            RadioListTile<String>(
                              contentPadding: EdgeInsets.zero,
                              title: Text('Svi proizvodi'),
                              value: 'all',
                            ),
                            RadioListTile<String>(
                              contentPadding: EdgeInsets.zero,
                              title: Text('Na popustu'),
                              value: 'discounted',
                            ),
                            RadioListTile<String>(
                              contentPadding: EdgeInsets.zero,
                              title: Text('Bez popusta'),
                              value: 'notDiscounted',
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 8),
                      DropdownButtonFormField<int>(
                        key: ValueKey('category-$draftCategoryId'),
                        initialValue: draftCategoryId,
                        decoration: const InputDecoration(
                          labelText: 'Kategorija',
                          border: OutlineInputBorder(),
                        ),
                        items: [
                          const DropdownMenuItem<int>(
                            value: null,
                            child: Text('Sve kategorije'),
                          ),
                          ..._categories.map(
                            (category) => DropdownMenuItem<int>(
                              value: category.id,
                              child: Text(category.name),
                            ),
                          ),
                        ],
                        onChanged: (value) {
                          setModalState(() {
                            draftCategoryId = value;
                          });
                        },
                      ),
                      const SizedBox(height: 16),
                      DropdownButtonFormField<int>(
                        key: ValueKey('manufacturer-$draftManufacturerId'),
                        initialValue: draftManufacturerId,
                        decoration: const InputDecoration(
                          labelText: 'Proizvođač vozila',
                          border: OutlineInputBorder(),
                        ),
                        items: [
                          const DropdownMenuItem<int>(
                            value: null,
                            child: Text('Svi proizvođači'),
                          ),
                          ..._carModelsByManufacturer.map(
                            (group) => DropdownMenuItem<int>(
                              value: group.manufacturer.id,
                              child: Text(group.manufacturer.name),
                            ),
                          ),
                        ],
                        onChanged: (value) {
                          setModalState(() {
                            draftManufacturerId = value;
                            draftCarModels.clear();
                          });
                        },
                      ),
                      if (draftManufacturerId != null) ...[
                        const SizedBox(height: 16),
                        DropdownButtonFormField<CarModel>(
                          key: ValueKey(
                            'model-$draftManufacturerId-'
                            '${draftCarModels.length}',
                          ),
                          initialValue: null,
                          decoration: const InputDecoration(
                            labelText: 'Model vozila',
                            border: OutlineInputBorder(),
                          ),
                          items: availableModels
                              .map(
                                (model) => DropdownMenuItem<CarModel>(
                                  value: model,
                                  child: Text(
                                    '${model.name} (${model.modelYear})',
                                  ),
                                ),
                              )
                              .toList(),
                          onChanged: (model) {
                            if (model == null ||
                                draftCarModels.any(
                                  (selected) => selected.id == model.id,
                                )) {
                              return;
                            }

                            setModalState(() {
                              draftCarModels.add(model);
                            });
                          },
                        ),
                      ],
                      if (draftCarModels.isNotEmpty) ...[
                        const SizedBox(height: 12),
                        Wrap(
                          spacing: 8,
                          runSpacing: 6,
                          children: draftCarModels
                              .map(
                                (model) => InputChip(
                                  label: Text(
                                    '${model.name} (${model.modelYear})',
                                  ),
                                  onDeleted: () {
                                    setModalState(() {
                                      draftCarModels.removeWhere(
                                        (selected) => selected.id == model.id,
                                      );
                                    });
                                  },
                                ),
                              )
                              .toList(),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    _nameFilterController.clear();
                    setModalState(() {
                      draftDiscountFilter = 'all';
                      draftCategoryId = null;
                      draftManufacturerId = null;
                      draftCarModels.clear();
                    });
                  },
                  child: const Text('Očisti'),
                ),
                TextButton(
                  onPressed: () => Navigator.pop(dialogContext),
                  child: const Text('Odustani'),
                ),
                FilledButton(
                  onPressed: () {
                    setState(() {
                      _nameFilter = _nameFilterController.text.trim();
                      _discountFilter = draftDiscountFilter;
                      _selectedCategoryId = draftCategoryId;
                      _selectedManufacturerId = draftManufacturerId;
                      _selectedCarModels = List<CarModel>.of(draftCarModels);
                      _pageNumber = 1;
                      _filtersApplied =
                          _nameFilter.isNotEmpty ||
                          _discountFilter != 'all' ||
                          _selectedCategoryId != null ||
                          _selectedManufacturerId != null ||
                          _selectedCarModels.isNotEmpty;
                    });

                    Navigator.pop(dialogContext);
                    _loadProducts();
                  },
                  child: const Text('Primijeni'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<List<Product>> _loadRecommendations(int productId) async {
    try {
      final provider = context.read<ProductRecommenderProvider>();
      await provider.getProductRecommendations(productId: productId);
      return List<Product>.of(provider.recommendedProducts);
    } catch (_) {
      return <Product>[];
    }
  }

  void _showProductDetails(Product product) {
    final recommendations = _loadRecommendations(product.id);

    showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: Text(product.name, textAlign: TextAlign.center),
          content: SizedBox(
            width: double.maxFinite,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SizedBox(
                    height: 170,
                    child: _productImage(product, fit: BoxFit.contain),
                  ),
                  const SizedBox(height: 12),
                  _detailRow('Cijena', '${product.price.toStringAsFixed(2)} €'),
                  if (product.discount > 0) ...[
                    _detailRow(
                      'Popust',
                      '${(product.discount * 100).toStringAsFixed(0)}%',
                    ),
                    _detailRow(
                      'Cijena s popustom',
                      '${product.discountedPrice.toStringAsFixed(2)} €',
                    ),
                  ],
                  _detailRow('Kategorija', product.category ?? 'Nije navedena'),
                  _detailRow(
                    'Opis',
                    product.details?.trim().isNotEmpty == true
                        ? product.details!.trim()
                        : 'Opis nije dostupan',
                  ),
                  _detailRow(
                    'Modeli vozila',
                    product.carModels?.isNotEmpty == true
                        ? product.carModels!
                              .map(
                                (model) => '${model.name} (${model.modelYear})',
                              )
                              .join(', ')
                        : 'Univerzalni proizvod',
                  ),
                  const Divider(height: 28),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      'Preporučeni proizvodi',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                  ),
                  const SizedBox(height: 8),
                  FutureBuilder<List<Product>>(
                    future: recommendations,
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Padding(
                          padding: EdgeInsets.all(12),
                          child: CircularProgressIndicator(),
                        );
                      }

                      final recommendedProducts = snapshot.data ?? <Product>[];

                      if (recommendedProducts.isEmpty) {
                        return const Text(
                          'Trenutno nema preporučenih proizvoda.',
                        );
                      }

                      return Column(
                        children: recommendedProducts
                            .map(
                              (recommendedProduct) => ListTile(
                                contentPadding: EdgeInsets.zero,
                                leading: SizedBox(
                                  width: 48,
                                  height: 48,
                                  child: _productImage(recommendedProduct),
                                ),
                                title: Text(recommendedProduct.name),
                                subtitle: Text(
                                  '${(recommendedProduct.discount > 0 ? recommendedProduct.discountedPrice : recommendedProduct.price).toStringAsFixed(2)} €',
                                ),
                                onTap: () {
                                  Navigator.pop(dialogContext);
                                  _showProductDetails(recommendedProduct);
                                },
                              ),
                            )
                            .toList(),
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Zatvori'),
            ),
          ],
        );
      },
    );
  }

  Widget _detailRow(String title, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 2,
            child: Text(
              '$title:',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(flex: 3, child: Text(value, textAlign: TextAlign.end)),
        ],
      ),
    );
  }

  void _openCart() {
    final formKey = GlobalKey<FormState>();
    bool cardIsValid = false;
    bool showCardError = false;
    bool submitting = false;

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (modalContext) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Padding(
              padding: EdgeInsets.fromLTRB(
                16,
                16,
                16,
                MediaQuery.of(context).viewInsets.bottom + 16,
              ),
              child: Form(
                key: formKey,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Row(
                        children: [
                          Text(
                            'Korpa',
                            style: Theme.of(context).textTheme.headlineSmall,
                          ),
                          const Spacer(),
                          IconButton(
                            onPressed: submitting
                                ? null
                                : () => Navigator.pop(modalContext),
                            icon: const Icon(Icons.close),
                          ),
                        ],
                      ),
                      if (_quantities.isEmpty)
                        const Padding(
                          padding: EdgeInsets.symmetric(vertical: 32),
                          child: Center(child: Text('Korpa je prazna.')),
                        )
                      else ...[
                        ConstrainedBox(
                          constraints: const BoxConstraints(maxHeight: 230),
                          child: ListView(
                            shrinkWrap: true,
                            children: _quantities.entries.map((entry) {
                              final product = _cartProducts[entry.key]!;

                              return ListTile(
                                contentPadding: EdgeInsets.zero,
                                leading: SizedBox(
                                  width: 50,
                                  height: 50,
                                  child: _productImage(product),
                                ),
                                title: Text(product.name),
                                subtitle: Text(
                                  '${(product.discount > 0 ? product.discountedPrice : product.price).toStringAsFixed(2)} €',
                                ),
                                trailing: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    IconButton(
                                      onPressed: submitting
                                          ? null
                                          : () {
                                              _changeQuantity(
                                                product,
                                                entry.value - 1,
                                              );
                                              setModalState(() {});
                                            },
                                      icon: const Icon(Icons.remove),
                                    ),
                                    Text('${entry.value}'),
                                    IconButton(
                                      onPressed:
                                          submitting ||
                                              entry.value >= _maximumQuantity
                                          ? null
                                          : () {
                                              _changeQuantity(
                                                product,
                                                entry.value + 1,
                                              );
                                              setModalState(() {});
                                            },
                                      icon: const Icon(Icons.add),
                                    ),
                                  ],
                                ),
                              );
                            }).toList(),
                          ),
                        ),
                        const Divider(),
                        Align(
                          alignment: Alignment.centerRight,
                          child: Text(
                            'Ukupno: ${_cartTotal.toStringAsFixed(2)} €',
                            style: Theme.of(context).textTheme.titleMedium
                                ?.copyWith(fontWeight: FontWeight.bold),
                          ),
                        ),
                        const SizedBox(height: 16),
                        const Text(
                          'Podaci kartice',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 8),
                        stripe.CardField(
                          onCardChanged: (card) {
                            setModalState(() {
                              cardIsValid = card?.complete ?? false;

                              if (cardIsValid) {
                                showCardError = false;
                              }
                            });
                          },
                          decoration: const InputDecoration(
                            border: OutlineInputBorder(),
                          ),
                        ),
                        if (showCardError)
                          Padding(
                            padding: const EdgeInsets.only(top: 6),
                            child: Text(
                              'Unesite ispravne podatke kartice.',
                              style: TextStyle(
                                color: Theme.of(context).colorScheme.error,
                              ),
                            ),
                          ),
                        const SizedBox(height: 16),
                        SwitchListTile(
                          contentPadding: EdgeInsets.zero,
                          title: const Text('Koristi adresu s profila'),
                          value: _useProfileAddress,
                          onChanged: submitting
                              ? null
                              : (value) {
                                  setModalState(() {
                                    _useProfileAddress = value;
                                  });
                                },
                        ),
                        if (!_useProfileAddress) ...[
                          const SizedBox(height: 8),
                          DropdownButtonFormField<int>(
                            initialValue: _selectedCityId,
                            decoration: const InputDecoration(
                              labelText: 'Grad',
                              border: OutlineInputBorder(),
                            ),
                            items: _cities
                                .map(
                                  (city) => DropdownMenuItem<int>(
                                    value: city.id,
                                    child: Text(city.name),
                                  ),
                                )
                                .toList(),
                            onChanged: submitting
                                ? null
                                : (value) {
                                    setModalState(() {
                                      _selectedCityId = value;
                                    });
                                  },
                            validator: (value) {
                              if (!_useProfileAddress && value == null) {
                                return 'Odaberite grad.';
                              }

                              return null;
                            },
                          ),
                          const SizedBox(height: 12),
                          TextFormField(
                            controller: _addressController,
                            enabled: !submitting,
                            decoration: const InputDecoration(
                              labelText: 'Adresa dostave',
                              border: OutlineInputBorder(),
                            ),
                            validator: (value) {
                              if (_useProfileAddress) {
                                return null;
                              }

                              final address = value?.trim() ?? '';

                              if (address.isEmpty) {
                                return 'Unesite adresu dostave.';
                              }

                              if (address.length > 100) {
                                return 'Adresa može imati najviše 100 znakova.';
                              }

                              return null;
                            },
                          ),
                          const SizedBox(height: 12),
                          TextFormField(
                            controller: _postalCodeController,
                            enabled: !submitting,
                            keyboardType: TextInputType.number,
                            decoration: const InputDecoration(
                              labelText: 'Poštanski broj',
                              border: OutlineInputBorder(),
                            ),
                            validator: (value) {
                              if (_useProfileAddress) {
                                return null;
                              }

                              final postalCode = value?.trim() ?? '';

                              if (postalCode.isEmpty) {
                                return 'Unesite poštanski broj.';
                              }

                              if (postalCode.length > 15) {
                                return 'Poštanski broj može imati najviše 15 znakova.';
                              }

                              return null;
                            },
                          ),
                        ],
                        const SizedBox(height: 20),
                        FilledButton.icon(
                          onPressed: submitting
                              ? null
                              : () async {
                                  final formIsValid =
                                      formKey.currentState?.validate() ?? false;

                                  if (!cardIsValid) {
                                    setModalState(() {
                                      showCardError = true;
                                    });
                                  }

                                  if (!formIsValid || !cardIsValid) {
                                    return;
                                  }

                                  setModalState(() {
                                    submitting = true;
                                  });

                                  final order = OrderInsert(
                                    userAddress: _useProfileAddress,
                                    cityId: _useProfileAddress
                                        ? null
                                        : _selectedCityId,
                                    shippingAddress: _useProfileAddress
                                        ? null
                                        : _addressController.text.trim(),
                                    shippingPostalCode: _useProfileAddress
                                        ? null
                                        : _postalCodeController.text.trim(),
                                    products: _productOrders,
                                  );

                                  try {
                                    final orderProvider = context
                                        .read<OrderProvider>();

                                    await orderProvider.insertOrder(order);

                                    if (!mounted || !modalContext.mounted) {
                                      return;
                                    }

                                    Navigator.pop(modalContext);

                                    setState(() {
                                      _quantities.clear();
                                      _cartProducts.clear();
                                      _addressController.clear();
                                      _postalCodeController.clear();
                                    });

                                    ScaffoldMessenger.of(
                                      this.context,
                                    ).showSnackBar(
                                      const SnackBar(
                                        content: Text(
                                          'Narudžba i plaćanje su uspješni.',
                                        ),
                                      ),
                                    );
                                  } catch (error) {
                                    if (!mounted) {
                                      return;
                                    }

                                    ScaffoldMessenger.of(
                                      this.context,
                                    ).showSnackBar(
                                      SnackBar(content: Text(error.toString())),
                                    );

                                    if (modalContext.mounted) {
                                      setModalState(() {
                                        submitting = false;
                                      });
                                    }
                                  }
                                },
                          icon: submitting
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                )
                              : const Icon(Icons.payment),
                          label: Text(
                            submitting ? 'Obrada...' : 'Plati i naruči',
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return MasterScreen(
      child: SafeArea(
        child: Stack(
          children: [
            Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(12, 10, 12, 6),
                  child: Row(
                    children: [
                      Expanded(
                        child: FilledButton.tonalIcon(
                          onPressed: _filterDataLoading
                              ? null
                              : _showFilterDialog,
                          icon: const Icon(Icons.filter_list),
                          label: Text(
                            _filtersApplied ? 'Filteri aktivni' : 'Filteri',
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      IconButton.filledTonal(
                        tooltip: 'Osvježi',
                        onPressed: _loadInitialData,
                        icon: const Icon(Icons.refresh),
                      ),
                    ],
                  ),
                ),
                if (_filterDataError != null)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    child: Text(
                      'Filteri nisu potpuno učitani. Proizvode i dalje možete pregledati.',
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.error,
                      ),
                    ),
                  ),
                Expanded(
                  child: Consumer<ProductProvider>(
                    builder: (context, provider, _) {
                      if (provider.isLoading) {
                        return const Center(child: CircularProgressIndicator());
                      }

                      if (_productsError != null) {
                        return _ErrorState(
                          message: _productsError!,
                          onRetry: _loadProducts,
                        );
                      }

                      if (provider.products.isEmpty) {
                        return Center(
                          child: Text(
                            _filtersApplied
                                ? 'Nema proizvoda koji odgovaraju filterima.'
                                : 'Trenutno nema dostupnih proizvoda.',
                          ),
                        );
                      }

                      return LayoutBuilder(
                        builder: (context, constraints) {
                          final crossAxisCount = constraints.maxWidth >= 800
                              ? 4
                              : constraints.maxWidth >= 560
                              ? 3
                              : constraints.maxWidth >= 360
                              ? 2
                              : 1;

                          return GridView.builder(
                            padding: const EdgeInsets.fromLTRB(12, 8, 12, 92),
                            gridDelegate:
                                SliverGridDelegateWithFixedCrossAxisCount(
                                  crossAxisCount: crossAxisCount,
                                  crossAxisSpacing: 10,
                                  mainAxisSpacing: 10,
                                  childAspectRatio: crossAxisCount == 1
                                      ? 1.12
                                      : 0.60,
                                ),
                            itemCount: provider.products.length,
                            itemBuilder: (context, index) {
                              final product = provider.products[index];
                              return _buildProductCard(product);
                            },
                          );
                        },
                      );
                    },
                  ),
                ),
                Consumer<ProductProvider>(
                  builder: (context, provider, _) {
                    if (provider.isLoading || provider.products.isEmpty) {
                      return const SizedBox.shrink();
                    }

                    return Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          IconButton(
                            onPressed: _pageNumber > 1
                                ? () => _changePage(_pageNumber - 1)
                                : null,
                            icon: const Icon(Icons.chevron_left),
                          ),
                          Text('Stranica $_pageNumber od $_totalPages'),
                          IconButton(
                            onPressed: _pageNumber < _totalPages
                                ? () => _changePage(_pageNumber + 1)
                                : null,
                            icon: const Icon(Icons.chevron_right),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ],
            ),
            Positioned(
              right: 16,
              bottom: 16,
              child: FloatingActionButton.extended(
                heroTag: 'productsCartButton',
                onPressed: _openCart,
                icon: const Icon(Icons.shopping_cart_outlined),
                label: Text('Korpa ($_cartItemCount)'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProductCard(Product product) {
    final quantity = _quantityFor(product.id);

    return Card(
      clipBehavior: Clip.antiAlias,
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(child: _productImage(product, fit: BoxFit.contain)),
            const SizedBox(height: 6),
            Text(
              product.name,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 5),
            if (product.discount > 0)
              Text.rich(
                TextSpan(
                  children: [
                    TextSpan(
                      text: '${product.price.toStringAsFixed(2)} €  ',
                      style: const TextStyle(
                        color: Colors.red,
                        decoration: TextDecoration.lineThrough,
                      ),
                    ),
                    TextSpan(
                      text: '${product.discountedPrice.toStringAsFixed(2)} €',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
                textAlign: TextAlign.center,
              )
            else
              Text(
                '${product.price.toStringAsFixed(2)} €',
                textAlign: TextAlign.center,
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            const SizedBox(height: 4),
            Text(
              product.category ?? 'Bez kategorije',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodySmall,
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                IconButton(
                  visualDensity: VisualDensity.compact,
                  onPressed: quantity > 0
                      ? () => _changeQuantity(product, quantity - 1)
                      : null,
                  icon: const Icon(Icons.remove_circle_outline),
                ),
                Text(
                  '$quantity',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                IconButton(
                  visualDensity: VisualDensity.compact,
                  onPressed: quantity < _maximumQuantity
                      ? () => _changeQuantity(product, quantity + 1)
                      : null,
                  icon: const Icon(Icons.add_circle_outline),
                ),
              ],
            ),
            SizedBox(
              height: 36,
              child: OutlinedButton(
                onPressed: () => _showProductDetails(product),
                child: const Text('Detalji'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _nameFilterController.dispose();
    _addressController.dispose();
    _postalCodeController.dispose();
    super.dispose();
  }
}

class _ErrorState extends StatelessWidget {
  final String message;
  final Future<void> Function() onRetry;

  const _ErrorState({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.error_outline,
              size: 48,
              color: Theme.of(context).colorScheme.error,
            ),
            const SizedBox(height: 12),
            Text(message, textAlign: TextAlign.center),
            const SizedBox(height: 12),
            FilledButton.tonal(
              onPressed: onRetry,
              child: const Text('Pokušaj ponovo'),
            ),
          ],
        ),
      ),
    );
  }
}
