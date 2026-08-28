class CustomException implements Exception {
  const CustomException(this.message);

  final String message;

  @override
  String toString() => message;
}
