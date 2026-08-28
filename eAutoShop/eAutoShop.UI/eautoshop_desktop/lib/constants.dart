class ApiHost {
  static const address = String.fromEnvironment(
    'API_HOST',
    defaultValue: 'localhost',
  );

  static const port = String.fromEnvironment('API_PORT', defaultValue: '5236');
}

class AppConstants {
  static const appName = 'eAutoShop';
  static const loginTitle = 'Prijava u desktop aplikaciju';
  static const usernameLabel = 'Korisničko ime';
  static const passwordLabel = 'Lozinka';
  static const loginButtonLabel = 'Prijavi se';
  static const usernameError = 'Unesite korisničko ime.';
  static const passwordError = 'Unesite lozinku.';
}

class AppPadding {
  static const small = 8.0;
  static const medium = 16.0;
  static const large = 24.0;
  static const extraLarge = 32.0;
}

class AppRadius {
  static const card = 16.0;
  static const field = 12.0;
  static const button = 12.0;
}
