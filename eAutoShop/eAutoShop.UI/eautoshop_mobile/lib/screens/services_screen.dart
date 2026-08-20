import 'dart:convert';
import 'dart:typed_data';

import 'package:eautoshop_mobile/models/appointment/appointment_insert.dart';
import 'package:eautoshop_mobile/models/autoshop_service/autoshop_service.dart';
import 'package:eautoshop_mobile/models/autoshop_service/autoshop_service_search_object.dart';
import 'package:eautoshop_mobile/models/car_model/car_model.dart';
import 'package:eautoshop_mobile/models/car_model/car_models_by_manufacturer.dart';
import 'package:eautoshop_mobile/providers/appointment_provider.dart';
import 'package:eautoshop_mobile/providers/autoshop_service_provider.dart';
import 'package:eautoshop_mobile/providers/car_models_by_manufacturer_provider.dart';
import 'package:eautoshop_mobile/screens/master_screen.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class ServicesScreen extends StatefulWidget {
  const ServicesScreen({super.key});

  @override
  State<ServicesScreen> createState() => _ServicesScreenState();
}

class _ServicesScreenState extends State<ServicesScreen> {
  static const int _pageSize = 10;

  static const List<String> _serviceTypes = [
    'AC & Climate',
    'Detailing',
    'Tire & Wheel',
    'Mechanical',
    'Diagnostics',
  ];

  final TextEditingController _nameFilterController = TextEditingController();

  final TextEditingController _orderIdController = TextEditingController();

  final Map<int, AutoShopService> _selectedServices = {};

  List<CarModelsByManufacturer> _carModelsByManufacturer = [];

  int _pageNumber = 1;
  int _totalPages = 1;

  int? _selectedManufacturerId;
  CarModel? _selectedCarModel;

  DateTime? _selectedDate;
  TimeOfDay? _selectedTime;

  String _nameFilter = '';
  String _discountFilter = 'all';
  String? _selectedServiceType;
  String? _servicesError;
  String? _carModelsError;

  bool _filtersApplied = false;
  bool _carModelsLoading = true;

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadInitialData();
    });
  }

  Future<void> _loadInitialData() async {
    await Future.wait([_loadServices(), _loadCarModels()]);
  }

  Future<void> _loadServices() async {
    if (mounted) {
      setState(() {
        _servicesError = null;
      });
    }

    bool? withDiscount;

    if (_discountFilter == 'discounted') {
      withDiscount = true;
    } else if (_discountFilter == 'notDiscounted') {
      withDiscount = false;
    }

    final search = AutoShopServiceSearchObject(
      name: _nameFilter.trim().isEmpty ? null : _nameFilter.trim(),
      serviceType: _selectedServiceType,
      withDiscount: withDiscount,
    );

    try {
      final provider = context.read<AutoShopServiceProvider>();

      await provider.getServices(
        pageNumber: _pageNumber,
        pageSize: _pageSize,
        serviceSearch: search,
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
        _servicesError = error.toString();
        _totalPages = 1;
      });
    }
  }

  Future<void> _loadCarModels() async {
    setState(() {
      _carModelsLoading = true;
      _carModelsError = null;
    });

    try {
      final provider = context.read<CarModelsByManufacturerProvider>();

      await provider.getCarModelsByManufacturer();

      if (!mounted) {
        return;
      }

      setState(() {
        _carModelsByManufacturer = List<CarModelsByManufacturer>.of(
          provider.modelsByManufacturer,
        );
      });
    } catch (error) {
      if (!mounted) {
        return;
      }

      setState(() {
        _carModelsError = error.toString();
      });
    } finally {
      if (mounted) {
        setState(() {
          _carModelsLoading = false;
        });
      }
    }
  }

  List<CarModel> _modelsForManufacturer(int? manufacturerId) {
    if (manufacturerId == null) {
      return [];
    }

    for (final group in _carModelsByManufacturer) {
      if (group.manufacturer.id == manufacturerId) {
        return group.models;
      }
    }

    return [];
  }

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

  Widget _serviceImage(
    AutoShopService service, {
    double? width,
    double? height,
  }) {
    final bytes = _decodeImage(service.imageData);

    if (bytes == null) {
      return SizedBox(
        width: width,
        height: height,
        child: const Icon(Icons.car_repair_outlined, size: 64),
      );
    }

    return Image.memory(
      bytes,
      width: width,
      height: height,
      fit: BoxFit.contain,
      errorBuilder: (_, _, _) {
        return const Icon(Icons.car_repair_outlined, size: 64);
      },
    );
  }

  Duration _parseDuration(String value) {
    final parts = value.split(':');

    if (parts.length < 3) {
      return Duration.zero;
    }

    return Duration(
      hours: int.tryParse(parts[0]) ?? 0,
      minutes: int.tryParse(parts[1]) ?? 0,
      seconds: int.tryParse(parts[2].split('.').first) ?? 0,
    );
  }

  Duration get _totalDuration {
    return _selectedServices.values.fold(
      Duration.zero,
      (total, service) => total + _parseDuration(service.duration),
    );
  }

  double get _totalAmount {
    return _selectedServices.values.fold(
      0,
      (total, service) =>
          total +
          (service.discount > 0 ? service.discountedPrice : service.price),
    );
  }

  String _formatDuration(Duration duration) {
    final hours = duration.inHours;
    final minutes = duration.inMinutes.remainder(60);

    if (hours == 0) {
      return '$minutes min';
    }

    return '$hours h ${minutes.toString().padLeft(2, '0')} min';
  }

  void _toggleService(AutoShopService service) {
    setState(() {
      if (_selectedServices.containsKey(service.id)) {
        _selectedServices.remove(service.id);
      } else {
        _selectedServices[service.id] = service;
      }
    });
  }

  Future<void> _changePage(int page) async {
    if (page < 1 || page > _totalPages || page == _pageNumber) {
      return;
    }

    setState(() {
      _pageNumber = page;
    });

    await _loadServices();
  }

  void _showFilterDialog() {
    _nameFilterController.text = _nameFilter;

    String draftDiscountFilter = _discountFilter;
    String? draftServiceType = _selectedServiceType;

    showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return AlertDialog(
              title: const Text('Filteri usluga'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: _nameFilterController,
                      decoration: const InputDecoration(
                        labelText: 'Naziv usluge',
                        prefixIcon: Icon(Icons.search),
                      ),
                    ),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<String>(
                      initialValue: draftServiceType,
                      decoration: const InputDecoration(
                        labelText: 'Vrsta usluge',
                        border: OutlineInputBorder(),
                      ),
                      items: [
                        const DropdownMenuItem<String>(
                          value: null,
                          child: Text('Sve vrste'),
                        ),
                        ..._serviceTypes.map(
                          (type) => DropdownMenuItem<String>(
                            value: type,
                            child: Text(type),
                          ),
                        ),
                      ],
                      onChanged: (value) {
                        setModalState(() {
                          draftServiceType = value;
                        });
                      },
                    ),
                    const SizedBox(height: 16),
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
                            title: Text('Sve usluge'),
                            value: 'all',
                          ),
                          RadioListTile<String>(
                            title: Text('Na popustu'),
                            value: 'discounted',
                          ),
                          RadioListTile<String>(
                            title: Text('Bez popusta'),
                            value: 'notDiscounted',
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    _nameFilterController.clear();

                    setModalState(() {
                      draftServiceType = null;
                      draftDiscountFilter = 'all';
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

                      _selectedServiceType = draftServiceType;
                      _discountFilter = draftDiscountFilter;
                      _pageNumber = 1;

                      _filtersApplied =
                          _nameFilter.isNotEmpty ||
                          _selectedServiceType != null ||
                          _discountFilter != 'all';
                    });

                    Navigator.pop(dialogContext);
                    _loadServices();
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

  void _showServiceDetails(AutoShopService service) {
    showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: Text(service.name, textAlign: TextAlign.center),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                SizedBox(height: 160, child: _serviceImage(service)),
                const SizedBox(height: 12),
                _detailRow('Cijena', '${service.price.toStringAsFixed(2)} €'),
                if (service.discount > 0) ...[
                  _detailRow(
                    'Popust',
                    '${(service.discount * 100).toStringAsFixed(0)}%',
                  ),
                  _detailRow(
                    'Cijena s popustom',
                    '${service.discountedPrice.toStringAsFixed(2)} €',
                  ),
                ],
                _detailRow('Vrsta', service.serviceTypeName),
                _detailRow(
                  'Trajanje',
                  _formatDuration(_parseDuration(service.duration)),
                ),
                _detailRow(
                  'Opis',
                  service.description.trim().isNotEmpty
                      ? service.description
                      : 'Opis nije dostupan',
                ),
                if (service.details?.trim().isNotEmpty == true)
                  _detailRow('Detalji', service.details!.trim()),
              ],
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
            child: Text(
              '$title:',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          Expanded(child: Text(value, textAlign: TextAlign.end)),
        ],
      ),
    );
  }

  Future<void> _selectDate(
    BuildContext modalContext,
    StateSetter setModalState,
  ) async {
    final now = DateTime.now();

    final result = await showDatePicker(
      context: modalContext,
      initialDate: _selectedDate ?? now,
      firstDate: DateTime(now.year, now.month, now.day),
      lastDate: DateTime(now.year + 2),
    );

    if (result != null) {
      setState(() {
        _selectedDate = result;
      });

      setModalState(() {
        _selectedDate = result;
      });
    }
  }

  Future<void> _selectTime(
    BuildContext modalContext,
    StateSetter setModalState,
  ) async {
    final result = await showTimePicker(
      context: modalContext,
      initialTime: _selectedTime ?? TimeOfDay.now(),
    );

    if (result != null) {
      setState(() {
        _selectedTime = result;
      });

      setModalState(() {
        _selectedTime = result;
      });
    }
  }

  void _showReservationForm() {
    if (_selectedServices.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Odaberite najmanje jednu uslugu.')),
      );
      return;
    }

    final formKey = GlobalKey<FormState>();
    bool submitting = false;

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (modalContext) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            final availableModels = _modelsForManufacturer(
              _selectedManufacturerId,
            );

            return Padding(
              padding: EdgeInsets.fromLTRB(
                16,
                16,
                16,
                MediaQuery.of(modalContext).viewInsets.bottom + 20,
              ),
              child: SingleChildScrollView(
                child: Form(
                  key: formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'Rezervacija termina',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      const SizedBox(height: 16),
                      Text('Odabrane usluge: ${_selectedServices.length}'),
                      Text('Ukupno: ${_totalAmount.toStringAsFixed(2)} €'),
                      Text('Trajanje: ${_formatDuration(_totalDuration)}'),
                      const SizedBox(height: 16),
                      if (_carModelsLoading)
                        const CircularProgressIndicator()
                      else if (_carModelsError != null)
                        Text('Modeli vozila nisu učitani: $_carModelsError')
                      else ...[
                        DropdownButtonFormField<int>(
                          initialValue: _selectedManufacturerId,
                          decoration: const InputDecoration(
                            labelText: 'Proizvođač vozila',
                            border: OutlineInputBorder(),
                          ),
                          items: _carModelsByManufacturer
                              .map(
                                (group) => DropdownMenuItem<int>(
                                  value: group.manufacturer.id,
                                  child: Text(group.manufacturer.name),
                                ),
                              )
                              .toList(),
                          onChanged: submitting
                              ? null
                              : (value) {
                                  setModalState(() {
                                    _selectedManufacturerId = value;
                                    _selectedCarModel = null;
                                  });

                                  setState(() {
                                    _selectedManufacturerId = value;
                                    _selectedCarModel = null;
                                  });
                                },
                          validator: (value) {
                            if (value == null) {
                              return 'Odaberite proizvođača.';
                            }

                            return null;
                          },
                        ),
                        const SizedBox(height: 12),
                        DropdownButtonFormField<CarModel>(
                          key: ValueKey(_selectedManufacturerId),
                          initialValue: _selectedCarModel,
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
                          onChanged: submitting
                              ? null
                              : (value) {
                                  setModalState(() {
                                    _selectedCarModel = value;
                                  });

                                  setState(() {
                                    _selectedCarModel = value;
                                  });
                                },
                          validator: (value) {
                            if (value == null) {
                              return 'Odaberite model vozila.';
                            }

                            return null;
                          },
                        ),
                      ],
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _orderIdController,
                        enabled: !submitting,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          labelText: 'Broj narudžbe (opcionalno)',
                          border: OutlineInputBorder(),
                        ),
                        validator: (value) {
                          final text = value?.trim() ?? '';

                          if (text.isNotEmpty && int.tryParse(text) == null) {
                            return 'Unesite ispravan broj narudžbe.';
                          }

                          return null;
                        },
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: submitting
                                  ? null
                                  : () => _selectDate(
                                      modalContext,
                                      setModalState,
                                    ),
                              icon: const Icon(Icons.calendar_month),
                              label: Text(
                                _selectedDate == null
                                    ? 'Odaberi datum'
                                    : '${_selectedDate!.day}.'
                                          '${_selectedDate!.month}.'
                                          '${_selectedDate!.year}.',
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: submitting
                                  ? null
                                  : () => _selectTime(
                                      modalContext,
                                      setModalState,
                                    ),
                              icon: const Icon(Icons.access_time),
                              label: Text(
                                _selectedTime?.format(context) ??
                                    'Odaberi vrijeme',
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      FilledButton.icon(
                        onPressed: submitting
                            ? null
                            : () async {
                                final valid =
                                    formKey.currentState?.validate() ?? false;

                                if (!valid ||
                                    _selectedCarModel == null ||
                                    _selectedDate == null ||
                                    _selectedTime == null) {
                                  ScaffoldMessenger.of(
                                    this.context,
                                  ).showSnackBar(
                                    const SnackBar(
                                      content: Text(
                                        'Odaberite vozilo, datum i vrijeme.',
                                      ),
                                    ),
                                  );
                                  return;
                                }

                                final localDateTime = DateTime(
                                  _selectedDate!.year,
                                  _selectedDate!.month,
                                  _selectedDate!.day,
                                  _selectedTime!.hour,
                                  _selectedTime!.minute,
                                );

                                if (!localDateTime.isAfter(DateTime.now())) {
                                  ScaffoldMessenger.of(
                                    this.context,
                                  ).showSnackBar(
                                    const SnackBar(
                                      content: Text(
                                        'Termin mora biti u budućnosti.',
                                      ),
                                    ),
                                  );
                                  return;
                                }

                                setModalState(() {
                                  submitting = true;
                                });

                                final orderIdText = _orderIdController.text
                                    .trim();

                                final appointment = AppointmentInsert(
                                  carModelId: _selectedCarModel!.id,
                                  orderId: orderIdText.isEmpty
                                      ? null
                                      : int.parse(orderIdText),
                                  reservationDate: localDateTime.toUtc(),
                                  services: _selectedServices.keys.toList(),
                                );

                                try {
                                  await context
                                      .read<AppointmentProvider>()
                                      .insertAppointment(appointment);

                                  if (!mounted || !modalContext.mounted) {
                                    return;
                                  }

                                  Navigator.pop(modalContext);

                                  setState(() {
                                    _selectedServices.clear();
                                    _orderIdController.clear();
                                    _selectedManufacturerId = null;
                                    _selectedCarModel = null;
                                    _selectedDate = null;
                                    _selectedTime = null;
                                  });

                                  ScaffoldMessenger.of(
                                    this.context,
                                  ).showSnackBar(
                                    const SnackBar(
                                      content: Text(
                                        'Rezervacija je uspješno kreirana.',
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
                            : const Icon(Icons.event_available),
                        label: Text(
                          submitting ? 'Rezervacija...' : 'Potvrdi rezervaciju',
                        ),
                      ),
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
                          onPressed: _showFilterDialog,
                          icon: const Icon(Icons.filter_list),
                          label: Text(
                            _filtersApplied ? 'Filteri aktivni' : 'Filteri',
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      IconButton.filledTonal(
                        onPressed: _loadInitialData,
                        icon: const Icon(Icons.refresh),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: Consumer<AutoShopServiceProvider>(
                    builder: (context, provider, _) {
                      if (provider.isLoading) {
                        return const Center(child: CircularProgressIndicator());
                      }

                      if (_servicesError != null) {
                        return Center(
                          child: Padding(
                            padding: const EdgeInsets.all(20),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  _servicesError!,
                                  textAlign: TextAlign.center,
                                ),
                                const SizedBox(height: 12),
                                FilledButton(
                                  onPressed: _loadServices,
                                  child: const Text('Pokušaj ponovo'),
                                ),
                              ],
                            ),
                          ),
                        );
                      }

                      if (provider.services.isEmpty) {
                        return Center(
                          child: Text(
                            _filtersApplied
                                ? 'Nema usluga koje odgovaraju filterima.'
                                : 'Trenutno nema dostupnih usluga.',
                          ),
                        );
                      }

                      return LayoutBuilder(
                        builder: (context, constraints) {
                          final columns = constraints.maxWidth >= 800
                              ? 4
                              : constraints.maxWidth >= 560
                              ? 3
                              : 2;

                          return GridView.builder(
                            padding: const EdgeInsets.fromLTRB(12, 8, 12, 92),
                            gridDelegate:
                                SliverGridDelegateWithFixedCrossAxisCount(
                                  crossAxisCount: columns,
                                  crossAxisSpacing: 10,
                                  mainAxisSpacing: 10,
                                  childAspectRatio: 0.62,
                                ),
                            itemCount: provider.services.length,
                            itemBuilder: (context, index) {
                              final service = provider.services[index];

                              final selected = _selectedServices.containsKey(
                                service.id,
                              );

                              return Card(
                                clipBehavior: Clip.antiAlias,
                                child: InkWell(
                                  onTap: () => _showServiceDetails(service),
                                  child: Padding(
                                    padding: const EdgeInsets.all(10),
                                    child: Column(
                                      children: [
                                        Expanded(child: _serviceImage(service)),
                                        Text(
                                          service.name,
                                          textAlign: TextAlign.center,
                                          maxLines: 2,
                                          overflow: TextOverflow.ellipsis,
                                          style: const TextStyle(
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        const SizedBox(height: 5),
                                        Text(
                                          service.serviceTypeName,
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                        const SizedBox(height: 5),
                                        if (service.discount > 0)
                                          Text.rich(
                                            TextSpan(
                                              children: [
                                                TextSpan(
                                                  text:
                                                      '${service.price.toStringAsFixed(2)} € ',
                                                  style: const TextStyle(
                                                    decoration: TextDecoration
                                                        .lineThrough,
                                                    color: Colors.red,
                                                  ),
                                                ),
                                                TextSpan(
                                                  text:
                                                      '${service.discountedPrice.toStringAsFixed(2)} €',
                                                ),
                                              ],
                                            ),
                                          )
                                        else
                                          Text(
                                            '${service.price.toStringAsFixed(2)} €',
                                          ),
                                        Text(
                                          _formatDuration(
                                            _parseDuration(service.duration),
                                          ),
                                        ),
                                        CheckboxListTile(
                                          contentPadding: EdgeInsets.zero,
                                          title: const Text('Odaberi'),
                                          value: selected,
                                          onChanged: (_) =>
                                              _toggleService(service),
                                          controlAffinity:
                                              ListTileControlAffinity.leading,
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              );
                            },
                          );
                        },
                      );
                    },
                  ),
                ),
                Consumer<AutoShopServiceProvider>(
                  builder: (context, provider, _) {
                    if (provider.isLoading || provider.services.isEmpty) {
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
                onPressed: _showReservationForm,
                icon: const Icon(Icons.car_repair),
                label: Text('Rezerviši (${_selectedServices.length})'),
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
    _orderIdController.dispose();
    super.dispose();
  }
}
