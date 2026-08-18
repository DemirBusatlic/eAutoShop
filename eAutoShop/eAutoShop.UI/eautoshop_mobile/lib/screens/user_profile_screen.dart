import 'dart:convert';

import 'package:eautoshop_mobile/models/city/city.dart';
import 'package:eautoshop_mobile/models/user/user.dart';
import 'package:eautoshop_mobile/models/user/user_change_password.dart';
import 'package:eautoshop_mobile/models/user/user_update.dart';
import 'package:eautoshop_mobile/providers/auth_provider.dart';
import 'package:eautoshop_mobile/providers/city_provider.dart';
import 'package:eautoshop_mobile/providers/user_provider.dart';
import 'package:eautoshop_mobile/screens/login_screen.dart';
import 'package:eautoshop_mobile/screens/master_screen.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

class UserProfileScreen extends StatefulWidget {
  const UserProfileScreen({super.key});

  @override
  State<UserProfileScreen> createState() => _UserProfileScreenState();
}

class _UserProfileScreenState extends State<UserProfileScreen> {
  static const int _maximumImageSize = 5 * 1024 * 1024;

  final _formKey = GlobalKey<FormState>();

  final _nameController = TextEditingController();
  final _surnameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _addressController = TextEditingController();
  final _postalCodeController = TextEditingController();

  List<City> _cities = [];
  int? _selectedCityId;
  String? _selectedGender;

  Uint8List? _imageBytes;
  bool _imageChanged = false;
  bool _isLoading = true;
  bool _isSaving = false;
  String? _loadingError;
  int? _initializedUserId;

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadProfile();
    });
  }

  @override
  void dispose() {
    _nameController.dispose();
    _surnameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    _postalCodeController.dispose();
    super.dispose();
  }

  Future<void> _loadProfile() async {
    setState(() {
      _isLoading = true;
      _loadingError = null;
    });

    try {
      final userProvider = context.read<UserProvider>();
      final cityProvider = context.read<CityProvider>();

      await Future.wait([
        userProvider.getCurrentUser(),
        cityProvider.getCities(),
      ]);

      final user = userProvider.user;

      if (user == null) {
        throw Exception('Podaci korisnika nisu pronađeni.');
      }

      if (!mounted) return;

      _cities = List<City>.from(cityProvider.cities);
      _initializeForm(user);

      setState(() {
        _isLoading = false;
      });
    } catch (error) {
      if (!mounted) return;

      setState(() {
        _loadingError = _readableError(error);
        _isLoading = false;
      });
    }
  }

  void _initializeForm(User user) {
    if (_initializedUserId == user.id) return;

    _initializedUserId = user.id;

    _nameController.text = user.name ?? '';
    _surnameController.text = user.surname ?? '';
    _emailController.text = user.email ?? '';
    _phoneController.text = _removePhonePrefix(user.phone ?? '');
    _addressController.text = user.address ?? '';
    _postalCodeController.text = user.postalCode ?? '';

    _selectedGender = user.gender;
    _selectedCityId = user.cityId;

    if (user.image != null && user.image!.isNotEmpty) {
      try {
        _imageBytes = base64Decode(user.image!);
      } catch (_) {
        _imageBytes = null;
      }
    }

    _imageChanged = false;
  }

  String _removePhonePrefix(String phone) {
    return phone.replaceFirst('+387', '').replaceFirst('+387 ', '').trim();
  }

  String get _normalizedPhone {
    var digits = _phoneController.text.replaceAll(RegExp(r'\D'), '');

    if (digits.startsWith('0')) {
      digits = digits.substring(1);
    }

    return '+387$digits';
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

    if (file.bytes == null) {
      _showMessage('Sliku nije moguće učitati.');
      return;
    }

    setState(() {
      _imageBytes = file.bytes;
      _imageChanged = true;
    });
  }

  void _removeImage() {
    setState(() {
      _imageBytes = null;
      _imageChanged = true;
    });
  }

  Future<void> _saveProfile() async {
    FocusScope.of(context).unfocus();

    if (!(_formKey.currentState?.validate() ?? false)) {
      return;
    }

    setState(() => _isSaving = true);

    final request = UserUpdate(
      name: _nameController.text.trim(),
      surname: _surnameController.text.trim(),
      email: _emailController.text.trim(),
      phone: _normalizedPhone,
      gender: _selectedGender,
      address: _addressController.text.trim(),
      postalCode: _postalCodeController.text.trim(),
      cityId: _selectedCityId,
      image: _imageChanged
          ? (_imageBytes == null ? '' : base64Encode(_imageBytes!))
          : null,
    );

    try {
      await context.read<UserProvider>().updateByToken(request);

      if (!mounted) return;

      setState(() {
        _imageChanged = false;
      });

      _showMessage('Podaci profila su uspješno sačuvani.');
    } catch (error) {
      if (!mounted) return;
      _showMessage(_readableError(error));
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  Future<void> _showChangePasswordDialog() async {
    final passwordFormKey = GlobalKey<FormState>();

    final oldPasswordController = TextEditingController();
    final newPasswordController = TextEditingController();
    final confirmPasswordController = TextEditingController();

    bool showOldPassword = false;
    bool showNewPassword = false;
    bool showConfirmPassword = false;

    final request = await showDialog<UserChangePassword>(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text('Promjena lozinke'),
              content: SingleChildScrollView(
                child: Form(
                  key: passwordFormKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      TextFormField(
                        controller: oldPasswordController,
                        obscureText: !showOldPassword,
                        decoration: InputDecoration(
                          labelText: 'Trenutna lozinka',
                          suffixIcon: IconButton(
                            onPressed: () {
                              setDialogState(() {
                                showOldPassword = !showOldPassword;
                              });
                            },
                            icon: Icon(
                              showOldPassword
                                  ? Icons.visibility_off
                                  : Icons.visibility,
                            ),
                          ),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Unesite trenutnu lozinku.';
                          }

                          return null;
                        },
                      ),
                      const SizedBox(height: 14),
                      TextFormField(
                        controller: newPasswordController,
                        obscureText: !showNewPassword,
                        decoration: InputDecoration(
                          labelText: 'Nova lozinka',
                          suffixIcon: IconButton(
                            onPressed: () {
                              setDialogState(() {
                                showNewPassword = !showNewPassword;
                              });
                            },
                            icon: Icon(
                              showNewPassword
                                  ? Icons.visibility_off
                                  : Icons.visibility,
                            ),
                          ),
                        ),
                        validator: _validatePassword,
                      ),
                      const SizedBox(height: 14),
                      TextFormField(
                        controller: confirmPasswordController,
                        obscureText: !showConfirmPassword,
                        decoration: InputDecoration(
                          labelText: 'Potvrdi novu lozinku',
                          suffixIcon: IconButton(
                            onPressed: () {
                              setDialogState(() {
                                showConfirmPassword = !showConfirmPassword;
                              });
                            },
                            icon: Icon(
                              showConfirmPassword
                                  ? Icons.visibility_off
                                  : Icons.visibility,
                            ),
                          ),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Potvrdite novu lozinku.';
                          }

                          if (value != newPasswordController.text) {
                            return 'Lozinke se ne podudaraju.';
                          }

                          return null;
                        },
                      ),
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(dialogContext),
                  child: const Text('Odustani'),
                ),
                FilledButton(
                  onPressed: () {
                    if (!(passwordFormKey.currentState?.validate() ?? false)) {
                      return;
                    }

                    Navigator.pop(
                      dialogContext,
                      UserChangePassword(
                        oldPassword: oldPasswordController.text,
                        newPassword: newPasswordController.text,
                        confirmNewPassword: confirmPasswordController.text,
                      ),
                    );
                  },
                  child: const Text('Promijeni'),
                ),
              ],
            );
          },
        );
      },
    );

    oldPasswordController.dispose();
    newPasswordController.dispose();
    confirmPasswordController.dispose();

    if (request == null || !mounted) return;

    try {
      await context.read<UserProvider>().changePassword(request);

      if (!mounted) return;

      await context.read<AuthProvider>().clearSession();

      if (!mounted) return;

      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const LoginScreen()),
        (route) => false,
      );

      _showMessage('Lozinka je promijenjena. Prijavite se ponovo.');
    } catch (error) {
      if (!mounted) return;
      _showMessage(_readableError(error));
    }
  }

  String? _validateRequired(String? value, String field) {
    if (value == null || value.trim().isEmpty) {
      return 'Unesite $field.';
    }

    return null;
  }

  String? _validateEmail(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Unesite email adresu.';
    }

    final validEmail = RegExp(
      r'^[^@\s]+@[^@\s]+\.[^@\s]+$',
    ).hasMatch(value.trim());

    if (!validEmail) {
      return 'Unesite ispravnu email adresu.';
    }

    return null;
  }

  String? _validatePhone(String? value) {
    final digits = value?.replaceAll(RegExp(r'\D'), '') ?? '';

    if (digits.length < 8 || digits.length > 9) {
      return 'Broj telefona mora imati 8 ili 9 cifara.';
    }

    return null;
  }

  String? _validatePassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Unesite novu lozinku.';
    }

    if (value.length < 6) {
      return 'Lozinka mora imati najmanje 6 znakova.';
    }

    if (!RegExp(r'^(?=.*[A-Za-z])(?=.*\d)').hasMatch(value)) {
      return 'Lozinka mora sadržavati slovo i broj.';
    }

    return null;
  }

  String _readableError(Object error) {
    return error.toString().replaceFirst(
      RegExp(r'^(Exception|CustomException):\s*'),
      '',
    );
  }

  void _showMessage(String message) {
    if (!mounted) return;

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  InputDecoration _decoration(String label, IconData icon) {
    return InputDecoration(
      labelText: label,
      prefixIcon: Icon(icon),
      border: const OutlineInputBorder(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return MasterScreen(child: SafeArea(child: _buildContent()));
  }

  Widget _buildContent() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_loadingError != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(_loadingError!, textAlign: TextAlign.center),
              const SizedBox(height: 16),
              FilledButton.icon(
                onPressed: _loadProfile,
                icon: const Icon(Icons.refresh),
                label: const Text('Pokušaj ponovo'),
              ),
            ],
          ),
        ),
      );
    }

    final user = context.watch<UserProvider>().user;

    if (user == null) {
      return const Center(child: Text('Podaci korisnika nisu pronađeni.'));
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 650),
          child: Card(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      'Moj profil',
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.headlineMedium,
                    ),
                    const SizedBox(height: 20),
                    _profileImage(),
                    const SizedBox(height: 12),
                    Text(
                      user.username ?? '',
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 28),
                    Text(
                      'Lični podaci',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 14),
                    TextFormField(
                      controller: _nameController,
                      enabled: !_isSaving,
                      textCapitalization: TextCapitalization.words,
                      decoration: _decoration('Ime', Icons.person_outline),
                      validator: (value) => _validateRequired(value, 'ime'),
                    ),
                    const SizedBox(height: 14),
                    TextFormField(
                      controller: _surnameController,
                      enabled: !_isSaving,
                      textCapitalization: TextCapitalization.words,
                      decoration: _decoration('Prezime', Icons.person_outline),
                      validator: (value) => _validateRequired(value, 'prezime'),
                    ),
                    const SizedBox(height: 14),
                    DropdownButtonFormField<String>(
                      initialValue: _selectedGender,
                      decoration: _decoration('Spol', Icons.wc_outlined),
                      items: const [
                        DropdownMenuItem(
                          value: 'Female',
                          child: Text('Žensko'),
                        ),
                        DropdownMenuItem(value: 'Male', child: Text('Muško')),
                      ],
                      onChanged: _isSaving
                          ? null
                          : (value) {
                              setState(() {
                                _selectedGender = value;
                              });
                            },
                      validator: (value) {
                        if (value == null) {
                          return 'Odaberite spol.';
                        }

                        return null;
                      },
                    ),
                    const SizedBox(height: 26),
                    Text(
                      'Kontakt i adresa',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 14),
                    TextFormField(
                      controller: _emailController,
                      enabled: !_isSaving,
                      keyboardType: TextInputType.emailAddress,
                      decoration: _decoration('Email', Icons.email_outlined),
                      validator: _validateEmail,
                    ),
                    const SizedBox(height: 14),
                    TextFormField(
                      controller: _phoneController,
                      enabled: !_isSaving,
                      keyboardType: TextInputType.phone,
                      inputFormatters: [
                        FilteringTextInputFormatter.allow(RegExp(r'[0-9 ]')),
                      ],
                      decoration: _decoration(
                        'Broj telefona',
                        Icons.phone_outlined,
                      ).copyWith(prefixText: '+387 '),
                      validator: _validatePhone,
                    ),
                    const SizedBox(height: 14),
                    DropdownButtonFormField<int>(
                      initialValue: _selectedCityId,
                      decoration: _decoration(
                        'Grad',
                        Icons.location_city_outlined,
                      ),
                      items: _cities.map((city) {
                        return DropdownMenuItem<int>(
                          value: city.id,
                          child: Text(city.name),
                        );
                      }).toList(),
                      onChanged: _isSaving
                          ? null
                          : (value) {
                              setState(() {
                                _selectedCityId = value;
                              });
                            },
                      validator: (value) {
                        if (value == null) {
                          return 'Odaberite grad.';
                        }

                        return null;
                      },
                    ),
                    const SizedBox(height: 14),
                    TextFormField(
                      controller: _addressController,
                      enabled: !_isSaving,
                      decoration: _decoration('Adresa', Icons.home_outlined),
                    ),
                    const SizedBox(height: 14),
                    TextFormField(
                      controller: _postalCodeController,
                      enabled: !_isSaving,
                      keyboardType: TextInputType.number,
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                      decoration: _decoration(
                        'Poštanski broj',
                        Icons.markunread_mailbox_outlined,
                      ),
                    ),
                    const SizedBox(height: 26),
                    FilledButton.icon(
                      onPressed: _isSaving ? null : _saveProfile,
                      icon: _isSaving
                          ? const SizedBox.square(
                              dimension: 18,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.save_outlined),
                      label: Text(
                        _isSaving ? 'Čuvanje...' : 'Sačuvaj promjene',
                      ),
                    ),
                    const SizedBox(height: 12),
                    OutlinedButton.icon(
                      onPressed: _isSaving ? null : _showChangePasswordDialog,
                      icon: const Icon(Icons.lock_outline),
                      label: const Text('Promijeni lozinku'),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _profileImage() {
    return Center(
      child: Column(
        children: [
          CircleAvatar(
            radius: 55,
            backgroundImage: _imageBytes == null
                ? null
                : MemoryImage(_imageBytes!),
            child: _imageBytes == null
                ? const Icon(Icons.person, size: 55)
                : null,
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            alignment: WrapAlignment.center,
            children: [
              TextButton.icon(
                onPressed: _isSaving ? null : _pickImage,
                icon: const Icon(Icons.photo_camera_outlined),
                label: const Text('Odaberi sliku'),
              ),
              if (_imageBytes != null)
                TextButton.icon(
                  onPressed: _isSaving ? null : _removeImage,
                  icon: const Icon(Icons.delete_outline),
                  label: const Text('Ukloni'),
                ),
            ],
          ),
        ],
      ),
    );
  }
}
