import 'dart:convert';

import 'package:eautoshop_mobile/models/city/city.dart';
import 'package:eautoshop_mobile/models/user/user_register.dart';
import 'package:eautoshop_mobile/providers/city_provider.dart';
import 'package:eautoshop_mobile/providers/user_provider.dart';
import 'package:eautoshop_mobile/screens/login_screen.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  static const int _maximumImageSize = 5 * 1024 * 1024;

  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _surnameController = TextEditingController();
  final _usernameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _addressController = TextEditingController();
  final _postalCodeController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  List<City> _cities = const [];
  int? _selectedCityId;
  String _gender = 'Female';
  Uint8List? _imageBytes;
  bool _isLoadingCities = true;
  bool _isSubmitting = false;
  bool _showPassword = false;
  bool _showConfirmPassword = false;
  bool _submittedOnce = false;
  String? _citiesError;
  String? _registrationError;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadCities());
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
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _loadCities() async {
    setState(() {
      _isLoadingCities = true;
      _citiesError = null;
    });

    try {
      final cityProvider = context.read<CityProvider>();
      await cityProvider.getCities();

      if (!mounted) return;
      setState(() {
        _cities = List<City>.from(cityProvider.cities);
        _isLoadingCities = false;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _citiesError = _readableError(error);
        _isLoadingCities = false;
      });
    }
  }

  Future<void> _pickImage() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: const ['jpg', 'jpeg', 'png'],
      withData: true,
    );

    if (result == null) return;

    final file = result.files.single;
    if (file.size > _maximumImageSize) {
      _showMessage('Slika ne smije biti veća od 5 MB.');
      return;
    }

    final bytes = file.bytes;
    if (bytes == null) {
      _showMessage('Sliku nije moguće učitati. Pokušaj ponovo.');
      return;
    }

    setState(() => _imageBytes = bytes);
  }

  Future<void> _register() async {
    setState(() => _submittedOnce = true);
    FocusScope.of(context).unfocus();

    if (!(_formKey.currentState?.validate() ?? false)) return;

    setState(() {
      _isSubmitting = true;
      _registrationError = null;
    });

    final request = UserRegister(
      name: _nameController.text.trim(),
      surname: _surnameController.text.trim(),
      username: _usernameController.text.trim(),
      email: _emailController.text.trim(),
      phone: _normalizedPhone,
      gender: _gender,
      cityId: _selectedCityId!,
      address: _nullIfEmpty(_addressController.text),
      postalCode: _nullIfEmpty(_postalCodeController.text),
      password: _passwordController.text,
      passwordConfirm: _confirmPasswordController.text,
      image: _imageBytes == null ? null : base64Encode(_imageBytes!),
    );

    try {
      // Backend mora sam postaviti ulogu "customer". RoleId se namjerno
      // ne bira i ne šalje iz mobilne aplikacije.
      await context.read<UserProvider>().register(request);

      if (!mounted) return;
      _showMessage('Korisnički nalog je uspješno kreiran.');
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const LoginScreen()),
        (route) => false,
      );
    } catch (error) {
      if (!mounted) return;
      setState(() => _registrationError = _readableError(error));
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  String get _normalizedPhone {
    var digits = _phoneController.text.replaceAll(RegExp(r'\D'), '');
    if (digits.startsWith('0')) digits = digits.substring(1);
    return '+387$digits';
  }

  String? _nullIfEmpty(String value) {
    final trimmed = value.trim();
    return trimmed.isEmpty ? null : trimmed;
  }

  String _readableError(Object error) {
    return error.toString().replaceFirst(RegExp(r'^Exception:\s*'), '');
  }

  void _showMessage(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Kreiranje naloga')),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 600),
              child: Card(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Form(
                    key: _formKey,
                    autovalidateMode: _submittedOnce
                        ? AutovalidateMode.onUserInteraction
                        : AutovalidateMode.disabled,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Text(
                          'Registracija',
                          textAlign: TextAlign.center,
                          style: Theme.of(context).textTheme.headlineMedium,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Kreiraj korisnički nalog za kupovinu proizvoda i rezervaciju termina.',
                          textAlign: TextAlign.center,
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                        const SizedBox(height: 24),
                        _ProfileImage(
                          imageBytes: _imageBytes,
                          onPick: _isSubmitting ? null : _pickImage,
                          onRemove: _imageBytes == null || _isSubmitting
                              ? null
                              : () => setState(() => _imageBytes = null),
                        ),
                        const SizedBox(height: 28),
                        const _SectionTitle('Lični podaci'),
                        const SizedBox(height: 12),
                        _textField(
                          controller: _nameController,
                          label: 'Ime',
                          icon: Icons.person_outline,
                          maxLength: 100,
                          textCapitalization: TextCapitalization.words,
                          validator: (value) =>
                              _validatePersonName(value, 'ime'),
                        ),
                        const SizedBox(height: 14),
                        _textField(
                          controller: _surnameController,
                          label: 'Prezime',
                          icon: Icons.person_outline,
                          maxLength: 100,
                          textCapitalization: TextCapitalization.words,
                          validator: (value) =>
                              _validatePersonName(value, 'prezime'),
                        ),
                        const SizedBox(height: 14),
                        DropdownButtonFormField<String>(
                          initialValue: _gender,
                          decoration: _decoration('Spol', Icons.wc_outlined),
                          items: const [
                            DropdownMenuItem(
                              value: 'Female',
                              child: Text('Žensko'),
                            ),
                            DropdownMenuItem(
                              value: 'Male',
                              child: Text('Muško'),
                            ),
                          ],
                          onChanged: _isSubmitting
                              ? null
                              : (value) => setState(() => _gender = value!),
                        ),
                        const SizedBox(height: 26),
                        const _SectionTitle('Kontakt i adresa'),
                        const SizedBox(height: 12),
                        _textField(
                          controller: _emailController,
                          label: 'Email',
                          icon: Icons.email_outlined,
                          keyboardType: TextInputType.emailAddress,
                          maxLength: 100,
                          validator: _validateEmail,
                        ),
                        const SizedBox(height: 14),
                        _textField(
                          controller: _phoneController,
                          label: 'Broj telefona',
                          hint: '61 123 456',
                          prefixText: '+387 ',
                          icon: Icons.phone_outlined,
                          keyboardType: TextInputType.phone,
                          maxLength: 12,
                          inputFormatters: [
                            FilteringTextInputFormatter.allow(
                              RegExp(r'[0-9 ]'),
                            ),
                          ],
                          validator: _validatePhone,
                        ),
                        const SizedBox(height: 14),
                        _cityField(),
                        const SizedBox(height: 14),
                        _textField(
                          controller: _addressController,
                          label: 'Adresa (opcionalno)',
                          icon: Icons.home_outlined,
                          maxLength: 255,
                          textCapitalization: TextCapitalization.sentences,
                        ),
                        const SizedBox(height: 14),
                        _textField(
                          controller: _postalCodeController,
                          label: 'Poštanski broj (opcionalno)',
                          icon: Icons.markunread_mailbox_outlined,
                          keyboardType: TextInputType.number,
                          maxLength: 20,
                          inputFormatters: [
                            FilteringTextInputFormatter.digitsOnly,
                          ],
                        ),
                        const SizedBox(height: 26),
                        const _SectionTitle('Podaci za prijavu'),
                        const SizedBox(height: 12),
                        _textField(
                          controller: _usernameController,
                          label: 'Korisničko ime',
                          hint: 'npr. demir.b',
                          icon: Icons.account_circle_outlined,
                          maxLength: 100,
                          inputFormatters: [
                            FilteringTextInputFormatter.allow(
                              RegExp(r'[a-zA-Z0-9._]'),
                            ),
                          ],
                          validator: _validateUsername,
                        ),
                        const SizedBox(height: 14),
                        _passwordField(
                          controller: _passwordController,
                          label: 'Lozinka',
                          visible: _showPassword,
                          onToggle: () =>
                              setState(() => _showPassword = !_showPassword),
                          validator: _validatePassword,
                        ),
                        const SizedBox(height: 14),
                        _passwordField(
                          controller: _confirmPasswordController,
                          label: 'Potvrdi lozinku',
                          visible: _showConfirmPassword,
                          onToggle: () => setState(
                            () => _showConfirmPassword = !_showConfirmPassword,
                          ),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Potvrdi lozinku.';
                            }
                            if (value != _passwordController.text) {
                              return 'Lozinke se ne podudaraju.';
                            }
                            return null;
                          },
                        ),
                        if (_registrationError != null) ...[
                          const SizedBox(height: 18),
                          Text(
                            _registrationError!,
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: Theme.of(context).colorScheme.error,
                            ),
                          ),
                        ],
                        const SizedBox(height: 24),
                        FilledButton.icon(
                          onPressed: _isSubmitting || _isLoadingCities
                              ? null
                              : _register,
                          icon: _isSubmitting
                              ? const SizedBox.square(
                                  dimension: 18,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                )
                              : const Icon(Icons.person_add_alt_1),
                          label: Text(
                            _isSubmitting
                                ? 'Kreiranje naloga...'
                                : 'Registruj se',
                          ),
                        ),
                        const SizedBox(height: 10),
                        TextButton(
                          onPressed: _isSubmitting
                              ? null
                              : () => Navigator.of(context).pushReplacement(
                                  MaterialPageRoute(
                                    builder: (_) => const LoginScreen(),
                                  ),
                                ),
                          child: const Text('Već imaš nalog? Prijavi se'),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _cityField() {
    if (_isLoadingCities) {
      return const InputDecorator(
        decoration: InputDecoration(
          labelText: 'Grad',
          prefixIcon: Icon(Icons.location_city_outlined),
          border: OutlineInputBorder(),
        ),
        child: LinearProgressIndicator(),
      );
    }

    if (_citiesError != null) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Gradove nije moguće učitati: $_citiesError',
            style: TextStyle(color: Theme.of(context).colorScheme.error),
          ),
          Align(
            alignment: Alignment.centerLeft,
            child: TextButton.icon(
              onPressed: _loadCities,
              icon: const Icon(Icons.refresh),
              label: const Text('Pokušaj ponovo'),
            ),
          ),
        ],
      );
    }

    return DropdownButtonFormField<int>(
      initialValue: _selectedCityId,
      isExpanded: true,
      decoration: _decoration('Grad', Icons.location_city_outlined),
      items: _cities
          .map(
            (city) =>
                DropdownMenuItem<int>(value: city.id, child: Text(city.name)),
          )
          .toList(),
      onChanged: _isSubmitting
          ? null
          : (value) => setState(() => _selectedCityId = value),
      validator: (value) => value == null ? 'Odaberi grad.' : null,
    );
  }

  Widget _textField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    String? hint,
    String? prefixText,
    int? maxLength,
    TextInputType? keyboardType,
    TextCapitalization textCapitalization = TextCapitalization.none,
    List<TextInputFormatter>? inputFormatters,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      enabled: !_isSubmitting,
      decoration: _decoration(label, icon, hint: hint, prefixText: prefixText),
      keyboardType: keyboardType,
      textCapitalization: textCapitalization,
      inputFormatters: [
        if (maxLength != null) LengthLimitingTextInputFormatter(maxLength),
        ...?inputFormatters,
      ],
      validator: validator,
    );
  }

  Widget _passwordField({
    required TextEditingController controller,
    required String label,
    required bool visible,
    required VoidCallback onToggle,
    required String? Function(String?) validator,
  }) {
    return TextFormField(
      controller: controller,
      enabled: !_isSubmitting,
      obscureText: !visible,
      enableSuggestions: false,
      autocorrect: false,
      inputFormatters: [LengthLimitingTextInputFormatter(100)],
      decoration: _decoration(label, Icons.lock_outline).copyWith(
        suffixIcon: IconButton(
          tooltip: visible ? 'Sakrij lozinku' : 'Prikaži lozinku',
          onPressed: onToggle,
          icon: Icon(visible ? Icons.visibility_off : Icons.visibility),
        ),
      ),
      validator: validator,
    );
  }

  InputDecoration _decoration(
    String label,
    IconData icon, {
    String? hint,
    String? prefixText,
  }) {
    return InputDecoration(
      labelText: label,
      hintText: hint,
      prefixText: prefixText,
      prefixIcon: Icon(icon),
      border: const OutlineInputBorder(),
    );
  }

  String? _validatePersonName(String? value, String fieldName) {
    final text = value?.trim() ?? '';
    if (text.isEmpty) return 'Unesi $fieldName.';
    if (text.length < 2) {
      return '${_capitalize(fieldName)} mora imati barem 2 znaka.';
    }
    if (RegExp(r'\d').hasMatch(text)) {
      return '${_capitalize(fieldName)} ne smije sadržavati brojeve.';
    }
    return null;
  }

  String? _validateEmail(String? value) {
    final email = value?.trim() ?? '';
    if (email.isEmpty) return 'Unesi email adresu.';
    if (!RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$').hasMatch(email)) {
      return 'Unesi ispravnu email adresu.';
    }
    return null;
  }

  String? _validatePhone(String? value) {
    var digits = (value ?? '').replaceAll(RegExp(r'\D'), '');
    if (digits.startsWith('0')) digits = digits.substring(1);
    if (digits.isEmpty) return 'Unesi broj telefona.';
    if (digits.length < 8 || digits.length > 9) {
      return 'Unesi 8 ili 9 cifara iza pozivnog broja +387.';
    }
    return null;
  }

  String? _validateUsername(String? value) {
    final username = value?.trim() ?? '';
    if (username.isEmpty) return 'Unesi korisničko ime.';
    if (username.length < 3) {
      return 'Korisničko ime mora imati barem 3 znaka.';
    }
    if (!RegExp(r'^[a-zA-Z0-9._]+$').hasMatch(username)) {
      return 'Dozvoljena su slova, brojevi, tačka i donja crta.';
    }
    return null;
  }

  String? _validatePassword(String? value) {
    final password = value ?? '';
    if (password.isEmpty) return 'Unesi lozinku.';
    if (password.trim() != password) {
      return 'Lozinka ne smije početi ili završiti razmakom.';
    }
    if (password.length < 8) {
      return 'Lozinka mora imati barem 8 znakova.';
    }
    if (!RegExp(r'[A-Za-z]').hasMatch(password) ||
        !RegExp(r'\d').hasMatch(password)) {
      return 'Lozinka mora sadržavati slovo i broj.';
    }
    return null;
  }

  String _capitalize(String value) {
    return '${value[0].toUpperCase()}${value.substring(1)}';
  }
}

class _ProfileImage extends StatelessWidget {
  const _ProfileImage({
    required this.imageBytes,
    required this.onPick,
    required this.onRemove,
  });

  final Uint8List? imageBytes;
  final VoidCallback? onPick;
  final VoidCallback? onRemove;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        CircleAvatar(
          radius: 54,
          backgroundImage: imageBytes == null ? null : MemoryImage(imageBytes!),
          child: imageBytes == null
              ? const Icon(Icons.person_outline, size: 52)
              : null,
        ),
        const SizedBox(height: 10),
        Wrap(
          alignment: WrapAlignment.center,
          spacing: 8,
          children: [
            OutlinedButton.icon(
              onPressed: onPick,
              icon: const Icon(Icons.photo_library_outlined),
              label: Text(imageBytes == null ? 'Dodaj sliku' : 'Promijeni'),
            ),
            if (imageBytes != null)
              TextButton.icon(
                onPressed: onRemove,
                icon: const Icon(Icons.delete_outline),
                label: const Text('Ukloni'),
              ),
          ],
        ),
      ],
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.title);

  final String title;

  @override
  Widget build(BuildContext context) {
    return Text(title, style: Theme.of(context).textTheme.titleMedium);
  }
}
