import 'dart:convert';
import 'dart:typed_data';

import 'package:eautoshop_desktop/constants.dart';
import 'package:eautoshop_desktop/models/city/city.dart';
import 'package:eautoshop_desktop/models/user/user.dart';
import 'package:eautoshop_desktop/models/user/user_insert.dart';
import 'package:eautoshop_desktop/models/user/user_update.dart';
import 'package:eautoshop_desktop/providers/city_provider.dart';
import 'package:eautoshop_desktop/providers/user_provider.dart';
import 'package:eautoshop_desktop/utilities/custom_exception.dart';
import 'package:file_selector/file_selector.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class UserScreen extends StatefulWidget {
  const UserScreen({super.key});

  @override
  State<UserScreen> createState() => _UserScreenState();
}

class _UserScreenState extends State<UserScreen> {
  static const Color _primaryBlue = Color(0xFF2848C7);

  final TextEditingController _searchController = TextEditingController();

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
        context.read<UserProvider>().getEmployees(),
        context.read<CityProvider>().getCities(),
      ]);
    } on CustomException catch (error) {
      _loadError = error.message;
    } catch (_) {
      _loadError = 'Podaci o zaposlenicima nisu mogli biti učitani.';
    }

    if (mounted) {
      setState(() => _initialLoading = false);
    }
  }

  Future<void> _search() async {
    try {
      await context.read<UserProvider>().getEmployees(
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
      await context.read<UserProvider>().getEmployees();
    } on CustomException catch (error) {
      _showMessage(error.message, isError: true);
    }
  }

  Future<void> _openEmployeeDialog([User? user]) async {
    final saved = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (_) => _EmployeeDialog(user: user),
    );

    if (saved == true && mounted) {
      await _search();
      _showMessage(
        user == null
            ? 'Zaposlenik je uspješno dodan.'
            : 'Podaci zaposlenika su uspješno ažurirani.',
      );
    }
  }

  Future<void> _changeActiveStatus(User user) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(
          user.active ? 'Deaktivacija zaposlenika' : 'Aktivacija zaposlenika',
        ),
        content: Text(
          'Da li želite ${user.active ? 'deaktivirati' : 'aktivirati'} '
          'zaposlenika ${_fullName(user)}?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Odustani'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: Text(user.active ? 'Deaktiviraj' : 'Aktiviraj'),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    try {
      await context.read<UserProvider>().changeActiveStatus(user.id);
      await _search();
      _showMessage(
        user.active ? 'Zaposlenik je deaktiviran.' : 'Zaposlenik je aktiviran.',
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

  String _fullName(User user) {
    final fullName = [
      user.name,
      user.surname,
    ].whereType<String>().where((value) => value.trim().isNotEmpty).join(' ');

    return fullName.isEmpty ? user.username ?? 'Nepoznato' : fullName;
  }

  String _roleName(String? roleName) {
    switch (roleName?.toLowerCase()) {
      case 'salesperson':
        return 'Prodavač';
      case 'technician':
        return 'Tehničar';
      default:
        return roleName ?? 'Nije navedena';
    }
  }

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

    final userProvider = context.watch<UserProvider>();

    return Padding(
      padding: const EdgeInsets.all(AppPadding.large),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildToolbar(userProvider),
          const SizedBox(height: AppPadding.medium),
          Expanded(
            child: Card(
              elevation: 0,
              color: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppRadius.card),
                side: const BorderSide(color: Color(0xFFE2E7F0)),
              ),
              child: userProvider.isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : _buildTable(userProvider.employees),
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
                borderSide: const BorderSide(color: Color(0xFFE2E7F0)),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppRadius.field),
                borderSide: const BorderSide(color: Color(0xFFE2E7F0)),
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
        FilledButton.icon(
          onPressed: provider.isLoading ? null : () => _openEmployeeDialog(),
          icon: const Icon(Icons.person_add_alt_1),
          label: const Text('Dodaj zaposlenika'),
          style: FilledButton.styleFrom(
            minimumSize: const Size(180, 52),
            backgroundColor: _primaryBlue,
          ),
        ),
      ],
    );
  }

  Widget _buildTable(List<User> users) {
    if (users.isEmpty) {
      return const Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.people_outline, size: 52, color: Color(0xFF7A8493)),
            SizedBox(height: AppPadding.medium),
            Text('Nema pronađenih zaposlenika.'),
          ],
        ),
      );
    }

    return Scrollbar(
      thumbVisibility: true,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: SingleChildScrollView(
          child: DataTable(
            headingRowColor: WidgetStateProperty.all(const Color(0xFFF0F3FF)),
            horizontalMargin: 24,
            columnSpacing: 34,
            columns: const [
              DataColumn(label: Text('Zaposlenik')),
              DataColumn(label: Text('Korisničko ime')),
              DataColumn(label: Text('Email')),
              DataColumn(label: Text('Telefon')),
              DataColumn(label: Text('Uloga')),
              DataColumn(label: Text('Grad')),
              DataColumn(label: Text('Status')),
              DataColumn(label: Text('Akcije')),
            ],
            rows: users.map((user) {
              return DataRow(
                cells: [
                  DataCell(
                    Row(
                      children: [
                        _UserAvatar(user: user),
                        const SizedBox(width: AppPadding.small),
                        Text(
                          _fullName(user),
                          style: const TextStyle(fontWeight: FontWeight.w600),
                        ),
                      ],
                    ),
                  ),
                  DataCell(Text(user.username ?? '—')),
                  DataCell(Text(user.email ?? '—')),
                  DataCell(Text(user.phone ?? '—')),
                  DataCell(Text(_roleName(user.roleName))),
                  DataCell(Text(user.cityName ?? '—')),
                  DataCell(_StatusChip(active: user.active)),
                  DataCell(
                    Row(
                      children: [
                        IconButton(
                          tooltip: 'Uredi zaposlenika',
                          onPressed: () => _openEmployeeDialog(user),
                          icon: const Icon(
                            Icons.edit_outlined,
                            color: _primaryBlue,
                          ),
                        ),
                        IconButton(
                          tooltip: user.active
                              ? 'Deaktiviraj zaposlenika'
                              : 'Aktiviraj zaposlenika',
                          onPressed: () => _changeActiveStatus(user),
                          icon: Icon(
                            user.active
                                ? Icons.person_off_outlined
                                : Icons.person_add_alt_outlined,
                            color: user.active
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
      ),
    );
  }
}

class _EmployeeDialog extends StatefulWidget {
  const _EmployeeDialog({this.user});

  final User? user;

  @override
  State<_EmployeeDialog> createState() => _EmployeeDialogState();
}

class _EmployeeDialogState extends State<_EmployeeDialog> {
  static const Color _primaryBlue = Color(0xFF2848C7);

  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  late final TextEditingController _nameController;
  late final TextEditingController _surnameController;
  late final TextEditingController _usernameController;
  late final TextEditingController _emailController;
  late final TextEditingController _phoneController;
  late final TextEditingController _addressController;
  late final TextEditingController _postalCodeController;
  late final TextEditingController _passwordController;
  late final TextEditingController _passwordConfirmController;

  int? _selectedCityId;
  int _selectedRoleId = 3;
  String _selectedGender = 'Male';
  String? _base64Image;
  bool _saving = false;
  bool _showPassword = false;
  bool _showPasswordConfirm = false;

  bool get _isEditing => widget.user != null;

  @override
  void initState() {
    super.initState();
    final user = widget.user;

    _nameController = TextEditingController(text: user?.name ?? '');
    _surnameController = TextEditingController(text: user?.surname ?? '');
    _usernameController = TextEditingController(text: user?.username ?? '');
    _emailController = TextEditingController(text: user?.email ?? '');
    _phoneController = TextEditingController(text: user?.phone ?? '');
    _addressController = TextEditingController(text: user?.address ?? '');
    _postalCodeController = TextEditingController(text: user?.postalCode ?? '');
    _passwordController = TextEditingController();
    _passwordConfirmController = TextEditingController();

    _selectedCityId = user?.cityId;
    _selectedRoleId = user?.roleId == 4 ? 4 : 3;
    _selectedGender = user?.gender == 'Female' ? 'Female' : 'Male';
    _base64Image = user?.image;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _surnameController.dispose();
    _usernameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    _postalCodeController.dispose();
    _passwordController.dispose();
    _passwordConfirmController.dispose();
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

      setState(() => _base64Image = base64Encode(bytes));
    } catch (_) {
      _showError('Odabrana slika nije mogla biti učitana.');
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    if (_selectedCityId == null) {
      _showError('Odaberite grad.');
      return;
    }

    setState(() => _saving = true);

    try {
      final provider = context.read<UserProvider>();

      if (_isEditing) {
        final request = UserUpdate(
          username: _usernameController.text.trim(),
          name: _nameController.text.trim(),
          surname: _surnameController.text.trim(),
          email: _emailController.text.trim(),
          phone: _phoneController.text.trim(),
          gender: _selectedGender,
          address: _emptyToNull(_addressController.text),
          postalCode: _emptyToNull(_postalCodeController.text),
          cityId: _selectedCityId,
          roleId: _selectedRoleId,
          image: _base64Image,
        );

        await provider.updateUser(id: widget.user!.id, request: request);
      } else {
        final request = UserInsert(
          name: _nameController.text.trim(),
          surname: _surnameController.text.trim(),
          username: _usernameController.text.trim(),
          email: _emailController.text.trim(),
          phone: _phoneController.text.trim(),
          gender: _selectedGender,
          address: _emptyToNull(_addressController.text),
          postalCode: _emptyToNull(_postalCodeController.text),
          password: _passwordController.text,
          passwordConfirm: _passwordConfirmController.text,
          cityId: _selectedCityId!,
          roleId: _selectedRoleId,
          image: _base64Image,
        );

        await provider.insert(request, toJson: (item) => item.toJson());
      }

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

  String? _requiredValidator(String? value, String fieldName) {
    if (value == null || value.trim().isEmpty) {
      return 'Unesite $fieldName.';
    }
    return null;
  }

  String? _emailValidator(String? value) {
    if (value == null || value.trim().isEmpty) return 'Unesite email.';

    final emailRegex = RegExp(
      r'^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}$',
    );

    return emailRegex.hasMatch(value.trim()) ? null : 'Unesite ispravan email.';
  }

  String? _passwordValidator(String? value) {
    if (_isEditing) return null;
    if (value == null || value.isEmpty) return 'Unesite lozinku.';
    if (value.length < 6) return 'Lozinka mora imati najmanje 6 znakova.';
    return null;
  }

  String? _passwordConfirmValidator(String? value) {
    if (_isEditing) return null;
    return value == _passwordController.text
        ? null
        : 'Lozinke se ne podudaraju.';
  }

  Widget _field({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    String? Function(String?)? validator,
    TextInputType? keyboardType,
    bool obscureText = false,
    Widget? suffixIcon,
  }) {
    return SizedBox(
      width: 320,
      child: TextFormField(
        controller: controller,
        validator: validator,
        keyboardType: keyboardType,
        obscureText: obscureText,
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: Icon(icon),
          suffixIcon: suffixIcon,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(AppRadius.field),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final cities = context.watch<CityProvider>().cities;

    return AlertDialog(
      title: Text(_isEditing ? 'Uredi zaposlenika' : 'Dodaj zaposlenika'),
      content: SizedBox(
        width: 720,
        child: SingleChildScrollView(
          child: Form(
            key: _formKey,
            child: Column(
              children: [
                Row(
                  children: [
                    _EditableAvatar(base64Image: _base64Image),
                    const SizedBox(width: AppPadding.medium),
                    OutlinedButton.icon(
                      onPressed: _saving ? null : _pickImage,
                      icon: const Icon(Icons.image_outlined),
                      label: const Text('Odaberi sliku'),
                    ),
                    if (_base64Image != null) ...[
                      const SizedBox(width: AppPadding.small),
                      TextButton(
                        onPressed: _saving
                            ? null
                            : () => setState(() => _base64Image = null),
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
                      controller: _nameController,
                      label: 'Ime',
                      icon: Icons.person_outline,
                      validator: (value) => _requiredValidator(value, 'ime'),
                    ),
                    _field(
                      controller: _surnameController,
                      label: 'Prezime',
                      icon: Icons.person_outline,
                      validator: (value) =>
                          _requiredValidator(value, 'prezime'),
                    ),
                    _field(
                      controller: _usernameController,
                      label: 'Korisničko ime',
                      icon: Icons.alternate_email,
                      validator: (value) =>
                          _requiredValidator(value, 'korisničko ime'),
                    ),
                    _field(
                      controller: _emailController,
                      label: 'Email',
                      icon: Icons.email_outlined,
                      validator: _emailValidator,
                      keyboardType: TextInputType.emailAddress,
                    ),
                    _field(
                      controller: _phoneController,
                      label: 'Telefon',
                      icon: Icons.phone_outlined,
                      validator: (value) =>
                          _requiredValidator(value, 'telefon'),
                      keyboardType: TextInputType.phone,
                    ),
                    _field(
                      controller: _addressController,
                      label: 'Adresa',
                      icon: Icons.home_outlined,
                    ),
                    _field(
                      controller: _postalCodeController,
                      label: 'Poštanski broj',
                      icon: Icons.local_post_office_outlined,
                    ),
                    SizedBox(
                      width: 320,
                      child: DropdownButtonFormField<int>(
                        initialValue: _selectedCityId,
                        decoration: _dropdownDecoration(
                          'Grad',
                          Icons.location_city_outlined,
                        ),
                        items: cities.map((City city) {
                          return DropdownMenuItem<int>(
                            value: city.id,
                            child: Text(city.name),
                          );
                        }).toList(),
                        onChanged: _saving
                            ? null
                            : (value) =>
                                  setState(() => _selectedCityId = value),
                        validator: (value) =>
                            value == null ? 'Odaberite grad.' : null,
                      ),
                    ),
                    SizedBox(
                      width: 320,
                      child: DropdownButtonFormField<String>(
                        initialValue: _selectedGender,
                        decoration: _dropdownDecoration('Spol', Icons.wc),
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
                                  setState(() => _selectedGender = value);
                                }
                              },
                      ),
                    ),
                    SizedBox(
                      width: 320,
                      child: DropdownButtonFormField<int>(
                        initialValue: _selectedRoleId,
                        decoration: _dropdownDecoration(
                          'Uloga',
                          Icons.badge_outlined,
                        ),
                        items: const [
                          DropdownMenuItem(value: 3, child: Text('Prodavač')),
                          DropdownMenuItem(value: 4, child: Text('Tehničar')),
                        ],
                        onChanged: _saving
                            ? null
                            : (value) {
                                if (value != null) {
                                  setState(() => _selectedRoleId = value);
                                }
                              },
                      ),
                    ),
                    if (!_isEditing) ...[
                      _field(
                        controller: _passwordController,
                        label: 'Lozinka',
                        icon: Icons.lock_outline,
                        validator: _passwordValidator,
                        obscureText: !_showPassword,
                        suffixIcon: IconButton(
                          onPressed: () =>
                              setState(() => _showPassword = !_showPassword),
                          icon: Icon(
                            _showPassword
                                ? Icons.visibility_off
                                : Icons.visibility,
                          ),
                        ),
                      ),
                      _field(
                        controller: _passwordConfirmController,
                        label: 'Potvrda lozinke',
                        icon: Icons.lock_outline,
                        validator: _passwordConfirmValidator,
                        obscureText: !_showPasswordConfirm,
                        suffixIcon: IconButton(
                          onPressed: () => setState(
                            () => _showPasswordConfirm = !_showPasswordConfirm,
                          ),
                          icon: Icon(
                            _showPasswordConfirm
                                ? Icons.visibility_off
                                : Icons.visibility,
                          ),
                        ),
                      ),
                    ],
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

  InputDecoration _dropdownDecoration(String label, IconData icon) {
    return InputDecoration(
      labelText: label,
      prefixIcon: Icon(icon),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppRadius.field),
      ),
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

class _UserAvatar extends StatelessWidget {
  const _UserAvatar({required this.user});

  final User user;

  @override
  Widget build(BuildContext context) {
    final bytes = _decodeImage(user.image);

    return CircleAvatar(
      radius: 20,
      backgroundColor: const Color(0xFFF0F3FF),
      backgroundImage: bytes == null ? null : MemoryImage(bytes),
      child: bytes == null
          ? const Icon(Icons.person_outline, color: Color(0xFF2848C7))
          : null,
    );
  }
}

class _EditableAvatar extends StatelessWidget {
  const _EditableAvatar({required this.base64Image});

  final String? base64Image;

  @override
  Widget build(BuildContext context) {
    final bytes = _decodeImage(base64Image);

    return CircleAvatar(
      radius: 38,
      backgroundColor: const Color(0xFFF0F3FF),
      backgroundImage: bytes == null ? null : MemoryImage(bytes),
      child: bytes == null
          ? const Icon(Icons.person_outline, size: 38, color: Color(0xFF2848C7))
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
