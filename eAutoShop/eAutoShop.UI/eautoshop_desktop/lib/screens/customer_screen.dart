import 'dart:convert';
import 'dart:typed_data';

import 'package:eautoshop_desktop/constants.dart';
import 'package:eautoshop_desktop/models/city/city.dart';
import 'package:eautoshop_desktop/models/user/user.dart';
import 'package:eautoshop_desktop/models/user/user_update.dart';
import 'package:eautoshop_desktop/providers/city_provider.dart';
import 'package:eautoshop_desktop/providers/user_provider.dart';
import 'package:eautoshop_desktop/utilities/custom_exception.dart';
import 'package:file_selector/file_selector.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class CustomerScreen extends StatefulWidget {
  const CustomerScreen({super.key});

  @override
  State<CustomerScreen> createState() => _CustomerScreenState();
}

class _CustomerScreenState extends State<CustomerScreen> {
  static const _primaryBlue = Color(0xFF2848C7);
  final _searchController = TextEditingController();

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
        context.read<UserProvider>().getCustomers(),
        context.read<CityProvider>().getCities(),
      ]);
    } on CustomException catch (error) {
      _loadError = error.message;
    } catch (_) {
      _loadError = 'Podaci o kupcima nisu mogli biti učitani.';
    }

    if (mounted) setState(() => _initialLoading = false);
  }

  Future<void> _search() async {
    try {
      await context.read<UserProvider>().getCustomers(
        containsUsername: _searchController.text.trim(),
      );
    } on CustomException catch (error) {
      _showMessage(error.message, isError: true);
    }
  }

  Future<void> _clearSearch() async {
    _searchController.clear();
    setState(() {});

    try {
      await context.read<UserProvider>().getCustomers();
    } on CustomException catch (error) {
      _showMessage(error.message, isError: true);
    }
  }

  Future<void> _editCustomer(User customer) async {
    final saved = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (_) => _CustomerEditDialog(customer: customer),
    );

    if (saved == true && mounted) {
      await _search();
      _showMessage('Podaci kupca su uspješno ažurirani.');
    }
  }

  Future<void> _changeActiveStatus(User customer) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(
          customer.active ? 'Deaktivacija kupca' : 'Aktivacija kupca',
        ),
        content: Text(
          'Da li želite ${customer.active ? 'deaktivirati' : 'aktivirati'} '
          'kupca ${_fullName(customer)}?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Odustani'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: Text(customer.active ? 'Deaktiviraj' : 'Aktiviraj'),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    try {
      await context.read<UserProvider>().changeActiveStatus(customer.id);
      await _search();
      _showMessage(
        customer.active ? 'Kupac je deaktiviran.' : 'Kupac je aktiviran.',
      );
    } on CustomException catch (error) {
      _showMessage(error.message, isError: true);
    }
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

  String _fullName(User customer) {
    final name = [
      customer.name,
      customer.surname,
    ].whereType<String>().where((value) => value.trim().isNotEmpty).join(' ');
    return name.isEmpty ? customer.username ?? 'Nepoznato' : name;
  }

  @override
  Widget build(BuildContext context) {
    if (_initialLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_loadError != null) {
      return Center(
        child: Card(
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

    final provider = context.watch<UserProvider>();

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
                  : _buildTable(provider.customers),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildToolbar(UserProvider provider) {
    return Row(
      children: [
        SizedBox(
          width: 360,
          child: TextField(
            controller: _searchController,
            onSubmitted: (_) => _search(),
            onChanged: (_) => setState(() {}),
            decoration: InputDecoration(
              hintText: 'Pretraga po korisničkom imenu',
              prefixIcon: const Icon(Icons.search),
              suffixIcon: _searchController.text.isEmpty
                  ? null
                  : IconButton(
                      tooltip: 'Poništi pretragu',
                      onPressed: _clearSearch,
                      icon: const Icon(Icons.close),
                    ),
              filled: true,
              fillColor: Colors.white,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppRadius.field),
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
        const Spacer(),
        Container(
          height: 52,
          padding: const EdgeInsets.symmetric(horizontal: AppPadding.medium),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: const Color(0xFFF0F3FF),
            borderRadius: BorderRadius.circular(AppRadius.field),
          ),
          child: Text(
            'Ukupno kupaca: ${provider.countOfItems}',
            style: const TextStyle(
              color: _primaryBlue,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTable(List<User> customers) {
    if (customers.isEmpty) {
      return const Center(child: Text('Nema pronađenih kupaca.'));
    }

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: SingleChildScrollView(
        child: DataTable(
          headingRowColor: WidgetStateProperty.all(const Color(0xFFF0F3FF)),
          horizontalMargin: 24,
          columnSpacing: 38,
          columns: const [
            DataColumn(label: Text('Kupac')),
            DataColumn(label: Text('Korisničko ime')),
            DataColumn(label: Text('Email')),
            DataColumn(label: Text('Telefon')),
            DataColumn(label: Text('Grad')),
            DataColumn(label: Text('Status')),
            DataColumn(label: Text('Akcije')),
          ],
          rows: customers.map((customer) {
            return DataRow(
              cells: [
                DataCell(
                  Row(
                    children: [
                      _CustomerAvatar(customer: customer),
                      const SizedBox(width: AppPadding.small),
                      Text(
                        _fullName(customer),
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                    ],
                  ),
                ),
                DataCell(Text(customer.username ?? '—')),
                DataCell(Text(customer.email ?? '—')),
                DataCell(Text(customer.phone ?? '—')),
                DataCell(Text(customer.cityName ?? '—')),
                DataCell(_StatusChip(active: customer.active)),
                DataCell(
                  Row(
                    children: [
                      IconButton(
                        tooltip: 'Uredi kupca',
                        onPressed: () => _editCustomer(customer),
                        icon: const Icon(
                          Icons.edit_outlined,
                          color: _primaryBlue,
                        ),
                      ),
                      IconButton(
                        tooltip: customer.active
                            ? 'Deaktiviraj kupca'
                            : 'Aktiviraj kupca',
                        onPressed: () => _changeActiveStatus(customer),
                        icon: Icon(
                          customer.active
                              ? Icons.person_off_outlined
                              : Icons.person_add_alt_outlined,
                          color: customer.active
                              ? const Color(0xFFB3261E)
                              : const Color(0xFF1B7F3A),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            );
          }).toList(),
        ),
      ),
    );
  }
}

class _CustomerEditDialog extends StatefulWidget {
  const _CustomerEditDialog({required this.customer});
  final User customer;

  @override
  State<_CustomerEditDialog> createState() => _CustomerEditDialogState();
}

class _CustomerEditDialogState extends State<_CustomerEditDialog> {
  static const _primaryBlue = Color(0xFF2848C7);
  final _formKey = GlobalKey<FormState>();

  late final TextEditingController _name;
  late final TextEditingController _surname;
  late final TextEditingController _username;
  late final TextEditingController _email;
  late final TextEditingController _phone;
  late final TextEditingController _address;
  late final TextEditingController _postalCode;

  int? _cityId;
  String _gender = 'Male';
  String? _image;
  bool _imageChanged = false;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final customer = widget.customer;
    _name = TextEditingController(text: customer.name ?? '');
    _surname = TextEditingController(text: customer.surname ?? '');
    _username = TextEditingController(text: customer.username ?? '');
    _email = TextEditingController(text: customer.email ?? '');
    _phone = TextEditingController(text: customer.phone ?? '');
    _address = TextEditingController(text: customer.address ?? '');
    _postalCode = TextEditingController(text: customer.postalCode ?? '');
    _cityId = customer.cityId;
    _gender = customer.gender == 'Female' ? 'Female' : 'Male';
    _image = customer.image;
  }

  @override
  void dispose() {
    for (final controller in [
      _name,
      _surname,
      _username,
      _email,
      _phone,
      _address,
      _postalCode,
    ]) {
      controller.dispose();
    }
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
      if (!mounted) return;
      setState(() {
        _image = base64Encode(bytes);
        _imageChanged = true;
      });
    } catch (_) {
      _showError('Odabrana slika nije mogla biti učitana.');
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    if (_cityId == null) {
      _showError('Odaberite grad.');
      return;
    }

    setState(() => _saving = true);

    final request = UserUpdate(
      username: _username.text.trim(),
      name: _name.text.trim(),
      surname: _surname.text.trim(),
      email: _email.text.trim(),
      phone: _phone.text.trim(),
      gender: _gender,
      address: _emptyToNull(_address.text),
      postalCode: _emptyToNull(_postalCode.text),
      cityId: _cityId,
      image: _imageChanged ? (_image ?? '') : null,
    );

    try {
      await context.read<UserProvider>().updateUser(
        id: widget.customer.id,
        request: request,
      );
      if (mounted) Navigator.pop(context, true);
    } on CustomException catch (error) {
      _showError(error.message);
    } catch (_) {
      _showError('Spremanje podataka nije uspjelo.');
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  String? _emptyToNull(String value) {
    final trimmed = value.trim();
    return trimmed.isEmpty ? null : trimmed;
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

  String? _required(String? value, String field) {
    return value == null || value.trim().isEmpty ? 'Unesite $field.' : null;
  }

  Widget _field(
    TextEditingController controller,
    String label,
    IconData icon, {
    String? Function(String?)? validator,
  }) {
    return SizedBox(
      width: 320,
      child: TextFormField(
        controller: controller,
        validator: validator,
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: Icon(icon),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(AppRadius.field),
          ),
        ),
      ),
    );
  }

  InputDecoration _dropdown(String label, IconData icon) {
    return InputDecoration(
      labelText: label,
      prefixIcon: Icon(icon),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppRadius.field),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final cities = context.watch<CityProvider>().cities;

    return AlertDialog(
      title: const Text('Uredi kupca'),
      content: SizedBox(
        width: 720,
        child: SingleChildScrollView(
          child: Form(
            key: _formKey,
            child: Column(
              children: [
                Row(
                  children: [
                    _EditableAvatar(image: _image),
                    const SizedBox(width: AppPadding.medium),
                    OutlinedButton.icon(
                      onPressed: _saving ? null : _pickImage,
                      icon: const Icon(Icons.image_outlined),
                      label: const Text('Odaberi sliku'),
                    ),
                    if (_image != null) ...[
                      const SizedBox(width: AppPadding.small),
                      TextButton(
                        onPressed: _saving
                            ? null
                            : () => setState(() {
                                _image = null;
                                _imageChanged = true;
                              }),
                        child: const Text('Ukloni sliku'),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: AppPadding.large),
                Wrap(
                  spacing: AppPadding.medium,
                  runSpacing: AppPadding.medium,
                  children: [
                    _field(
                      _name,
                      'Ime',
                      Icons.person_outline,
                      validator: (value) => _required(value, 'ime'),
                    ),
                    _field(
                      _surname,
                      'Prezime',
                      Icons.person_outline,
                      validator: (value) => _required(value, 'prezime'),
                    ),
                    _field(
                      _username,
                      'Korisničko ime',
                      Icons.alternate_email,
                      validator: (value) => _required(value, 'korisničko ime'),
                    ),
                    _field(
                      _email,
                      'Email',
                      Icons.email_outlined,
                      validator: (value) => _required(value, 'email'),
                    ),
                    _field(
                      _phone,
                      'Telefon',
                      Icons.phone_outlined,
                      validator: (value) => _required(value, 'telefon'),
                    ),
                    _field(_address, 'Adresa', Icons.home_outlined),
                    _field(
                      _postalCode,
                      'Poštanski broj',
                      Icons.local_post_office_outlined,
                    ),
                    SizedBox(
                      width: 320,
                      child: DropdownButtonFormField<int>(
                        initialValue: _cityId,
                        decoration: _dropdown(
                          'Grad',
                          Icons.location_city_outlined,
                        ),
                        items: cities.map((City city) {
                          return DropdownMenuItem(
                            value: city.id,
                            child: Text(city.name),
                          );
                        }).toList(),
                        onChanged: _saving
                            ? null
                            : (value) => setState(() => _cityId = value),
                        validator: (value) =>
                            value == null ? 'Odaberite grad.' : null,
                      ),
                    ),
                    SizedBox(
                      width: 320,
                      child: DropdownButtonFormField<String>(
                        initialValue: _gender,
                        decoration: _dropdown('Spol', Icons.wc),
                        items: const [
                          DropdownMenuItem(value: 'Male', child: Text('Muško')),
                          DropdownMenuItem(
                            value: 'Female',
                            child: Text('Žensko'),
                          ),
                        ],
                        onChanged: _saving
                            ? null
                            : (value) {
                                if (value != null) {
                                  setState(() => _gender = value);
                                }
                              },
                      ),
                    ),
                  ],
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
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                )
              : const Icon(Icons.save_outlined),
          label: Text(_saving ? 'Spremanje...' : 'Sačuvaj'),
          style: FilledButton.styleFrom(backgroundColor: _primaryBlue),
        ),
      ],
    );
  }
}

class _StatusChip extends StatelessWidget {
  const _StatusChip({required this.active});
  final bool active;

  @override
  Widget build(BuildContext context) {
    final color = active ? const Color(0xFF1B7F3A) : const Color(0xFFB3261E);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        active ? 'Aktivan' : 'Neaktivan',
        style: TextStyle(color: color, fontWeight: FontWeight.w600),
      ),
    );
  }
}

class _CustomerAvatar extends StatelessWidget {
  const _CustomerAvatar({required this.customer});
  final User customer;

  @override
  Widget build(BuildContext context) {
    return _Avatar(image: customer.image, radius: 20);
  }
}

class _EditableAvatar extends StatelessWidget {
  const _EditableAvatar({required this.image});
  final String? image;

  @override
  Widget build(BuildContext context) {
    return _Avatar(image: image, radius: 38);
  }
}

class _Avatar extends StatelessWidget {
  const _Avatar({required this.image, required this.radius});
  final String? image;
  final double radius;

  @override
  Widget build(BuildContext context) {
    final bytes = _decodeImage(image);
    return CircleAvatar(
      radius: radius,
      backgroundColor: const Color(0xFFF0F3FF),
      backgroundImage: bytes == null ? null : MemoryImage(bytes),
      child: bytes == null
          ? Icon(
              Icons.person_outline,
              size: radius,
              color: const Color(0xFF2848C7),
            )
          : null,
    );
  }
}

Uint8List? _decodeImage(String? image) {
  if (image == null || image.trim().isEmpty) return null;
  try {
    return base64Decode(image);
  } catch (_) {
    return null;
  }
}
